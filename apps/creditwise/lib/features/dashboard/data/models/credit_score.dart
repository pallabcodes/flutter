/// Core credit score data models for CreditWise

enum CreditBureau { transUnion, equifax, experian }

enum CreditScoreType { fico, vantage, ficoAuto, ficoBankcard }

class CreditScore {
  final String bureau;
  final int score;
  final DateTime lastUpdated;
  final CreditScoreType scoreType;
  final CreditScoreRange range;
  final List<CreditFactor> factors;
  final double? changeFromLastMonth;

  const CreditScore({
    required this.bureau,
    required this.score,
    required this.lastUpdated,
    required this.scoreType,
    required this.range,
    required this.factors,
    this.changeFromLastMonth,
  });

  factory CreditScore.fromJson(Map<String, dynamic> json) {
    return CreditScore(
      bureau: json['bureau'] as String,
      score: json['score'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      scoreType: CreditScoreType.values.firstWhere(
        (e) => e.name == json['scoreType'],
        orElse: () => CreditScoreType.fico,
      ),
      range: CreditScoreRange.fromJson(json['range'] as Map<String, dynamic>),
      factors: (json['factors'] as List<dynamic>?)
          ?.map((e) => CreditFactor.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      changeFromLastMonth: json['changeFromLastMonth'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bureau': bureau,
      'score': score,
      'lastUpdated': lastUpdated.toIso8601String(),
      'scoreType': scoreType.name,
      'range': range.toJson(),
      'factors': factors.map((e) => e.toJson()).toList(),
      'changeFromLastMonth': changeFromLastMonth,
    };
  }

  CreditScore copyWith({
    String? bureau,
    int? score,
    DateTime? lastUpdated,
    CreditScoreType? scoreType,
    CreditScoreRange? range,
    List<CreditFactor>? factors,
    double? changeFromLastMonth,
  }) {
    return CreditScore(
      bureau: bureau ?? this.bureau,
      score: score ?? this.score,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      scoreType: scoreType ?? this.scoreType,
      range: range ?? this.range,
      factors: factors ?? this.factors,
      changeFromLastMonth: changeFromLastMonth ?? this.changeFromLastMonth,
    );
  }

  bool get isExcellent => score >= range.excellentMin;
  bool get isGood => score >= range.goodMin && score < range.excellentMin;
  bool get isFair => score >= range.fairMin && score < range.goodMin;
  bool get isPoor => score < range.fairMin;

  String get scoreLabel {
    if (isExcellent) return 'Excellent';
    if (isGood) return 'Good';
    if (isFair) return 'Fair';
    return 'Poor';
  }

  Color get scoreColor {
    if (isExcellent) return const Color(0xFF4CAF50); // Green
    if (isGood) return const Color(0xFF8BC34A); // Light Green
    if (isFair) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }
}

class CreditScoreRange {
  final int poorMin;
  final int fairMin;
  final int goodMin;
  final int excellentMin;
  final int max;

  const CreditScoreRange({
    required this.poorMin,
    required this.fairMin,
    required this.goodMin,
    required this.excellentMin,
    required this.max,
  });

  factory CreditScoreRange.fromJson(Map<String, dynamic> json) {
    return CreditScoreRange(
      poorMin: json['poorMin'] as int,
      fairMin: json['fairMin'] as int,
      goodMin: json['goodMin'] as int,
      excellentMin: json['excellentMin'] as int,
      max: json['max'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poorMin': poorMin,
      'fairMin': fairMin,
      'goodMin': goodMin,
      'excellentMin': excellentMin,
      'max': max,
    };
  }

  // FICO score ranges
  static const fico = CreditScoreRange(
    poorMin: 300,
    fairMin: 580,
    goodMin: 670,
    excellentMin: 740,
    max: 850,
  );

  // VantageScore ranges
  static const vantage = CreditScoreRange(
    poorMin: 300,
    fairMin: 601,
    goodMin: 661,
    excellentMin: 781,
    max: 850,
  );
}

class CreditFactor {
  final String id;
  final String name;
  final String type; // 'paymentHistory', 'creditUtilization', etc.
  final double value;
  final bool isNegative;
  final double impact; // Impact on score (points)
  final String description;
  final List<String> recommendations;

  const CreditFactor({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.isNegative,
    required this.impact,
    required this.description,
    required this.recommendations,
  });

  factory CreditFactor.fromJson(Map<String, dynamic> json) {
    return CreditFactor(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      isNegative: json['isNegative'] as bool,
      impact: (json['impact'] as num).toDouble(),
      description: json['description'] as String,
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'isNegative': isNegative,
      'impact': impact,
      'description': description,
      'recommendations': recommendations,
    };
  }
}

class CreditReport {
  final String id;
  final String userId;
  final CreditBureau bureau;
  final CreditScore currentScore;
  final List<CreditScore> historicalScores;
  final List<CreditAccount> accounts;
  final List<CreditInquiry> inquiries;
  final List<PublicRecord> publicRecords;
  final DateTime generatedAt;
  final DateTime nextUpdate;

  const CreditReport({
    required this.id,
    required this.userId,
    required this.bureau,
    required this.currentScore,
    required this.historicalScores,
    required this.accounts,
    required this.inquiries,
    required this.publicRecords,
    required this.generatedAt,
    required this.nextUpdate,
  });

  factory CreditReport.fromJson(Map<String, dynamic> json) {
    return CreditReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bureau: CreditBureau.values.firstWhere(
        (e) => e.name == json['bureau'],
        orElse: () => CreditBureau.transUnion,
      ),
      currentScore: CreditScore.fromJson(json['currentScore'] as Map<String, dynamic>),
      historicalScores: (json['historicalScores'] as List<dynamic>?)
          ?.map((e) => CreditScore.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      accounts: (json['accounts'] as List<dynamic>?)
          ?.map((e) => CreditAccount.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      inquiries: (json['inquiries'] as List<dynamic>?)
          ?.map((e) => CreditInquiry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      publicRecords: (json['publicRecords'] as List<dynamic>?)
          ?.map((e) => PublicRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      nextUpdate: DateTime.parse(json['nextUpdate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bureau': bureau.name,
      'currentScore': currentScore.toJson(),
      'historicalScores': historicalScores.map((e) => e.toJson()).toList(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'inquiries': inquiries.map((e) => e.toJson()).toList(),
      'publicRecords': publicRecords.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'nextUpdate': nextUpdate.toIso8601String(),
    };
  }
}

class CreditAccount {
  final String id;
  final String name;
  final String type; // 'credit_card', 'auto_loan', 'mortgage', etc.
  final String accountNumber;
  final double balance;
  final double creditLimit;
  final double utilization;
  final String status;
  final DateTime openedDate;
  final DateTime lastPaymentDate;
  final double minimumPayment;

  const CreditAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    required this.balance,
    required this.creditLimit,
    required this.utilization,
    required this.status,
    required this.openedDate,
    required this.lastPaymentDate,
    required this.minimumPayment,
  });

  factory CreditAccount.fromJson(Map<String, dynamic> json) {
    return CreditAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      accountNumber: json['accountNumber'] as String,
      balance: (json['balance'] as num).toDouble(),
      creditLimit: (json['creditLimit'] as num).toDouble(),
      utilization: (json['utilization'] as num).toDouble(),
      status: json['status'] as String,
      openedDate: DateTime.parse(json['openedDate'] as String),
      lastPaymentDate: DateTime.parse(json['lastPaymentDate'] as String),
      minimumPayment: (json['minimumPayment'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'accountNumber': accountNumber,
      'balance': balance,
      'creditLimit': creditLimit,
      'utilization': utilization,
      'status': status,
      'openedDate': openedDate.toIso8601String(),
      'lastPaymentDate': lastPaymentDate.toIso8601String(),
      'minimumPayment': minimumPayment,
    };
  }
}

class CreditInquiry {
  final String id;
  final String creditorName;
  final String inquiryType;
  final DateTime inquiryDate;

  const CreditInquiry({
    required this.id,
    required this.creditorName,
    required this.inquiryType,
    required this.inquiryDate,
  });

  factory CreditInquiry.fromJson(Map<String, dynamic> json) {
    return CreditInquiry(
      id: json['id'] as String,
      creditorName: json['creditorName'] as String,
      inquiryType: json['inquiryType'] as String,
      inquiryDate: DateTime.parse(json['inquiryDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditorName': creditorName,
      'inquiryType': inquiryType,
      'inquiryDate': inquiryDate.toIso8601String(),
    };
  }
}

class PublicRecord {
  final String id;
  final String type; // 'bankruptcy', 'tax_lien', 'judgment', etc.
  final String description;
  final DateTime recordedDate;
  final double amount;

  const PublicRecord({
    required this.id,
    required this.type,
    required this.description,
    required this.recordedDate,
    required this.amount,
  });

  factory PublicRecord.fromJson(Map<String, dynamic> json) {
    return PublicRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      recordedDate: DateTime.parse(json['recordedDate'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'recordedDate': recordedDate.toIso8601String(),
      'amount': amount,
    };
  }
}
