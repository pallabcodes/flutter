import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/data/models/credit_score.dart';
import '../lib/data/datasources/credit_bureau_api.dart';
import '../lib/data/repositories/credit_repository.dart';

// Generate mocks
@GenerateMocks([http.Client, FlutterSecureStorage])
import 'credit_repository_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockCreditBureauApi mockApi;
  late CreditRepository repository;

  setUp(() {
    mockClient = MockClient();
    mockSecureStorage = MockFlutterSecureStorage();
    mockApi = MockCreditBureauApi(mockClient, mockSecureStorage);
    repository = CreditRepository(mockApi, mockSecureStorage as dynamic);
  });

  group('CreditRepository', () {
    const testUserId = 'test-user-123';
    const testBureau = CreditBureau.transUnion;

    test('should return credit score when connected', () async {
      // Arrange
      final mockScore = CreditScore(
        bureau: 'TransUnion',
        score: 750,
        lastUpdated: DateTime.now(),
        scoreType: CreditScoreType.fico,
        range: CreditScoreRange.fico,
        factors: [],
      );

      when(mockApi.isConnected(bureau: testBureau, userId: testUserId))
          .thenAnswer((_) async => true);
      when(mockApi.getStoredAuth(bureau: testBureau, userId: testUserId))
          .thenAnswer((_) async => {
                'accessToken': 'test-token',
                'expiresAt': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
              });
      when(mockApi.fetchCreditScore(
        bureau: testBureau,
        accessToken: 'test-token',
        userId: testUserId,
      )).thenAnswer((_) async => mockScore);

      // Act
      final result = await repository.getCreditScore(
        bureau: testBureau,
        userId: testUserId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (score) => expect(score.score, 750),
      );
    });

    test('should return failure when not connected', () async {
      // Arrange
      when(mockApi.isConnected(bureau: testBureau, userId: testUserId))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.getCreditScore(
        bureau: testBureau,
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CreditNotConnectedFailure>()),
        (score) => fail('Should return failure'),
      );
    });

    test('should return connection status for all bureaus', () async {
      // Arrange
      when(mockApi.isConnected(bureau: anyNamed('bureau'), userId: testUserId))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.getConnectionStatus(userId: testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (status) => expect(status.length, CreditBureau.values.length),
      );
    });
  });
}
