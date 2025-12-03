import 'dart:async';
import 'package:finwise_core/finwise_core.dart';
import '../models/investment_models.dart';
import '../datasources/investment_service.dart';

/// Repository for investment data operations
class InvestmentRepository {
  final InvestmentService _investmentService;
  final SecureStorageService _secureStorage;
  final LocalDatabaseService _database;

  InvestmentRepository(this._investmentService, this._secureStorage, this._database);

  /// Get user's investment portfolio
  Future<Either<Failure, InvestmentPortfolio>> getPortfolio({
    required String userId,
  }) async {
    try {
      final portfolio = await _database.getInvestmentPortfolio(userId);

      // Refresh market data for holdings
      if (portfolio.holdings.isNotEmpty) {
        final symbols = portfolio.holdings.map((h) => h.asset.symbol).toList();
        final marketData = await _investmentService.getBatchMarketData(symbols);

        // Update holdings with latest market data
        final updatedHoldings = portfolio.holdings.map((holding) {
          final marketInfo = marketData.firstWhere(
            (data) => data.symbol == holding.asset.symbol,
            orElse: () => null,
          );

          if (marketInfo != null) {
            // Update with latest price data
            return holding.copyWith(
              currentPrice: marketInfo.price,
              dailyChange: marketInfo.change,
              dailyChangePercent: marketInfo.changePercent,
              value: holding.shares * marketInfo.price,
              gainLoss: (holding.shares * marketInfo.price) - holding.cost,
              gainLossPercent: ((holding.shares * marketInfo.price) - holding.cost) / holding.cost * 100,
            );
          }

          return holding;
        }).toList();

        // Recalculate portfolio totals
        final updatedPortfolio = _recalculatePortfolioTotals(portfolio, updatedHoldings);
        return Right(updatedPortfolio);
      }

      return Right(portfolio);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to load portfolio: ${e.toString()}'));
    }
  }

  /// Create a new investment portfolio
  Future<Either<Failure, InvestmentPortfolio>> createPortfolio({
    required InvestmentPortfolio portfolio,
  }) async {
    try {
      final savedPortfolio = await _database.saveInvestmentPortfolio(portfolio);
      return Right(savedPortfolio);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to create portfolio: ${e.toString()}'));
    }
  }

  /// Execute a buy order
  Future<Either<Failure, InvestmentTransaction>> buyAsset({
    required String portfolioId,
    required String assetId,
    required double amount,
    required String userId,
  }) async {
    try {
      final transaction = await _investmentService.executeBuyOrder(
        portfolioId: portfolioId,
        assetId: assetId,
        amount: amount,
        userId: userId,
      );

      // Save transaction to database
      await _database.saveInvestmentTransaction(transaction);

      // Update portfolio holdings
      await _updatePortfolioHoldings(portfolioId, transaction);

      return Right(transaction);
    } catch (e) {
      return Left(InvestmentTransactionFailure('Buy order failed: ${e.toString()}'));
    }
  }

  /// Execute a sell order
  Future<Either<Failure, InvestmentTransaction>> sellAsset({
    required String portfolioId,
    required String assetId,
    required double shares,
    required String userId,
  }) async {
    try {
      final transaction = await _investmentService.executeSellOrder(
        portfolioId: portfolioId,
        assetId: assetId,
        shares: shares,
        userId: userId,
      );

      // Save transaction to database
      await _database.saveInvestmentTransaction(transaction);

      // Update portfolio holdings
      await _updatePortfolioHoldings(portfolioId, transaction);

      return Right(transaction);
    } catch (e) {
      return Left(InvestmentTransactionFailure('Sell order failed: ${e.toString()}'));
    }
  }

  /// Process micro-investment from spare change
  Future<Either<Failure, InvestmentTransaction>> processMicroInvestment({
    required String portfolioId,
    required double amount,
    required String strategy,
    required String userId,
  }) async {
    try {
      final transaction = await _investmentService.processMicroInvestment(
        portfolioId: portfolioId,
        amount: amount,
        strategy: strategy,
        userId: userId,
      );

      // Save transaction to database
      await _database.saveInvestmentTransaction(transaction);

      // Update portfolio holdings
      await _updatePortfolioHoldings(portfolioId, transaction);

      return Right(transaction);
    } catch (e) {
      return Left(InvestmentTransactionFailure('Micro-investment failed: ${e.toString()}'));
    }
  }

  /// Get market data for an asset
  Future<Either<Failure, MarketData>> getMarketData({
    required String symbol,
  }) async {
    try {
      final marketData = await _investmentService.getMarketData(symbol);
      return Right(marketData);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to fetch market data: ${e.toString()}'));
    }
  }

  /// Search for investment assets
  Future<Either<Failure, List<InvestmentAsset>>> searchAssets({
    required String query,
  }) async {
    try {
      final assets = await _investmentService.searchAssets(query);
      return Right(assets);
    } catch (e) {
      return Left(InvestmentDataFailure('Asset search failed: ${e.toString()}'));
    }
  }

  /// Get AI-powered investment recommendations
  Future<Either<Failure, List<InvestmentRecommendation>>> getAIRecommendations({
    required String userId,
    required InvestmentPortfolio portfolio,
    required RiskProfile riskProfile,
  }) async {
    try {
      final recommendations = await _investmentService.getAIRecommendations(
        userId: userId,
        portfolio: portfolio,
        riskProfile: riskProfile,
      );
      return Right(recommendations);
    } catch (e) {
      return Left(InvestmentDataFailure('AI recommendations failed: ${e.toString()}'));
    }
  }

  /// Calculate portfolio rebalancing
  Future<Either<Failure, List<PortfolioRebalance>>> calculateRebalancing({
    required InvestmentPortfolio portfolio,
    required String targetStrategy,
  }) async {
    try {
      final rebalances = await _investmentService.calculateRebalancing(
        portfolio: portfolio,
        targetStrategy: targetStrategy,
      );
      return Right(rebalances);
    } catch (e) {
      return Left(InvestmentDataFailure('Rebalancing calculation failed: ${e.toString()}'));
    }
  }

  /// Create an investment goal
  Future<Either<Failure, InvestmentGoal>> createGoal({
    required InvestmentGoal goal,
  }) async {
    try {
      final savedGoal = await _database.saveInvestmentGoal(goal);
      return Right(savedGoal);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to create goal: ${e.toString()}'));
    }
  }

  /// Get user's investment goals
  Future<Either<Failure, List<InvestmentGoal>>> getGoals({
    required String userId,
  }) async {
    try {
      final goals = await _database.getInvestmentGoals(userId);
      return Right(goals);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to load goals: ${e.toString()}'));
    }
  }

  /// Update investment goal progress
  Future<Either<Failure, InvestmentGoal>> updateGoalProgress({
    required String goalId,
    required double additionalAmount,
  }) async {
    try {
      final goal = await _database.getInvestmentGoal(goalId);
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + additionalAmount,
        updatedAt: DateTime.now(),
      );

      final savedGoal = await _database.saveInvestmentGoal(updatedGoal);
      return Right(savedGoal);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to update goal: ${e.toString()}'));
    }
  }

  /// Get micro-investment settings
  Future<Either<Failure, MicroInvestmentSettings>> getMicroInvestmentSettings({
    required String userId,
  }) async {
    try {
      final settings = await _database.getMicroInvestmentSettings(userId);
      return Right(settings);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to load micro-investment settings: ${e.toString()}'));
    }
  }

  /// Update micro-investment settings
  Future<Either<Failure, MicroInvestmentSettings>> updateMicroInvestmentSettings({
    required MicroInvestmentSettings settings,
  }) async {
    try {
      final updatedSettings = await _database.saveMicroInvestmentSettings(settings);
      return Right(updatedSettings);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to update micro-investment settings: ${e.toString()}'));
    }
  }

  /// Get trending investments
  Future<Either<Failure, List<TrendingInvestment>>> getTrendingInvestments({
    int limit = 10,
  }) async {
    try {
      final trending = await _investmentService.getTrendingInvestments(limit: limit);
      return Right(trending);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to fetch trending investments: ${e.toString()}'));
    }
  }

  /// Get transaction history
  Future<Either<Failure, List<InvestmentTransaction>>> getTransactionHistory({
    required String portfolioId,
    int limit = 50,
  }) async {
    try {
      final transactions = await _database.getInvestmentTransactions(portfolioId, limit);
      return Right(transactions);
    } catch (e) {
      return Left(InvestmentDataFailure('Failed to load transaction history: ${e.toString()}'));
    }
  }

  /// Calculate portfolio performance metrics
  Future<Either<Failure, PortfolioPerformance>> calculatePerformance({
    required InvestmentPortfolio portfolio,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final transactions = await _database.getInvestmentTransactions(
        portfolio.id,
        1000, // Get all transactions for performance calculation
      );

      // Calculate performance metrics
      final performance = PortfolioPerformanceCalculator.calculate(
        portfolio: portfolio,
        transactions: transactions,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(performance);
    } catch (e) {
      return Left(InvestmentDataFailure('Performance calculation failed: ${e.toString()}'));
    }
  }

  // Helper methods
  Future<void> _updatePortfolioHoldings(String portfolioId, InvestmentTransaction transaction) async {
    final portfolio = await _database.getInvestmentPortfolioById(portfolioId);
    final holdings = List<PortfolioHolding>.from(portfolio.holdings);

    if (transaction.isBuy) {
      // Add or update holding for buy transaction
      final existingIndex = holdings.indexWhere((h) => h.asset.id == transaction.assetId);

      if (existingIndex >= 0) {
        // Update existing holding
        final existing = holdings[existingIndex];
        final newShares = existing.shares + transaction.shares;
        final newCost = existing.cost + transaction.total;
        final newAverageCost = newCost / newShares;

        holdings[existingIndex] = existing.copyWith(
          shares: newShares,
          averageCost: newAverageCost,
          cost: newCost,
        );
      } else {
        // Add new holding
        final asset = await _getAssetById(transaction.assetId);
        final holding = PortfolioHolding(
          id: 'holding_${transaction.id}',
          portfolioId: portfolioId,
          asset: asset,
          shares: transaction.shares,
          averageCost: transaction.price,
          currentPrice: transaction.price,
          value: transaction.total,
          cost: transaction.total,
          gainLoss: 0.0,
          gainLossPercent: 0.0,
          dailyChange: 0.0,
          dailyChangePercent: 0.0,
          purchasedAt: transaction.timestamp,
          updatedAt: DateTime.now(),
        );
        holdings.add(holding);
      }
    } else if (transaction.isSell) {
      // Remove shares from holding for sell transaction
      final existingIndex = holdings.indexWhere((h) => h.asset.id == transaction.assetId);

      if (existingIndex >= 0) {
        final existing = holdings[existingIndex];
        final newShares = existing.shares - transaction.shares;

        if (newShares <= 0) {
          // Remove holding if all shares sold
          holdings.removeAt(existingIndex);
        } else {
          // Update remaining shares
          final newCost = existing.cost * (newShares / existing.shares);
          holdings[existingIndex] = existing.copyWith(
            shares: newShares,
            cost: newCost,
          );
        }
      }
    }

    // Recalculate portfolio totals
    final updatedPortfolio = _recalculatePortfolioTotals(portfolio, holdings);
    await _database.saveInvestmentPortfolio(updatedPortfolio);
  }

  Future<InvestmentAsset> _getAssetById(String assetId) async {
    // This would fetch asset details from database or API
    // For now, return a placeholder
    return InvestmentAsset(
      id: assetId,
      symbol: 'UNKNOWN',
      name: 'Unknown Asset',
      type: 'stock',
      exchange: 'NASDAQ',
      sector: 'Unknown',
      industry: 'Unknown',
      currentPrice: 0.0,
      marketCap: 0.0,
      peRatio: 0.0,
      dividendYield: 0.0,
      volatility: 0.5,
      beta: 1.0,
      currency: 'USD',
      description: 'Asset details loading...',
      lastUpdated: DateTime.now(),
    );
  }

  InvestmentPortfolio _recalculatePortfolioTotals(
    InvestmentPortfolio portfolio,
    List<PortfolioHolding> holdings,
  ) {
    final totalValue = holdings.fold<double>(0, (sum, h) => sum + h.value);
    final totalCost = holdings.fold<double>(0, (sum, h) => sum + h.cost);
    final totalGainLoss = totalValue - totalCost;
    final totalGainLossPercent = totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0.0;

    return portfolio.copyWith(
      totalValue: totalValue,
      totalCost: totalCost,
      totalGainLoss: totalGainLoss,
      totalGainLossPercent: totalGainLossPercent,
      holdings: holdings,
      updatedAt: DateTime.now(),
    );
  }
}

/// Investment-specific failure types
class InvestmentDataFailure extends Failure {
  const InvestmentDataFailure(String message) : super(message: message);
}

class InvestmentTransactionFailure extends Failure {
  const InvestmentTransactionFailure(String message) : super(message: message);
}

/// Portfolio performance calculation
class PortfolioPerformance {
  final double totalReturn;
  final double annualizedReturn;
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;
  final List<PerformancePoint> performanceHistory;

  const PortfolioPerformance({
    required this.totalReturn,
    required this.annualizedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.performanceHistory,
  });
}

class PerformancePoint {
  final DateTime date;
  final double value;
  final double returnPercent;

  const PerformancePoint({
    required this.date,
    required this.value,
    required this.returnPercent,
  });
}

class PortfolioPerformanceCalculator {
  static PortfolioPerformance calculate({
    required InvestmentPortfolio portfolio,
    required List<InvestmentTransaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Simplified performance calculation
    // In production, this would use sophisticated financial calculations

    final totalReturn = portfolio.totalGainLossPercent;
    final annualizedReturn = _calculateAnnualizedReturn(totalReturn, startDate, endDate);
    final volatility = _calculateVolatility(portfolio.holdings);
    final sharpeRatio = _calculateSharpeRatio(annualizedReturn, volatility);
    final maxDrawdown = _calculateMaxDrawdown(portfolio.holdings);

    // Generate performance history (simplified)
    final performanceHistory = _generatePerformanceHistory(portfolio, startDate, endDate);

    return PortfolioPerformance(
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn,
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      performanceHistory: performanceHistory,
    );
  }

  static double _calculateAnnualizedReturn(double totalReturn, DateTime start, DateTime end) {
    final years = end.difference(start).inDays / 365.0;
    if (years <= 0) return 0.0;
    return (1 + totalReturn / 100).pow(1 / years) - 1;
  }

  static double _calculateVolatility(List<PortfolioHolding> holdings) {
    if (holdings.isEmpty) return 0.0;
    final avgVolatility = holdings.fold<double>(0, (sum, h) => sum + h.asset.volatility) / holdings.length;
    return avgVolatility;
  }

  static double _calculateSharpeRatio(double annualizedReturn, double volatility) {
    const riskFreeRate = 0.02; // 2% risk-free rate
    final excessReturn = annualizedReturn - riskFreeRate;
    return volatility > 0 ? excessReturn / volatility : 0.0;
  }

  static double _calculateMaxDrawdown(List<PortfolioHolding> holdings) {
    // Simplified max drawdown calculation
    return holdings.isEmpty ? 0.0 : holdings.map((h) => h.asset.volatility).reduce((a, b) => a > b ? a : b) * 2;
  }

  static List<PerformancePoint> _generatePerformanceHistory(
    InvestmentPortfolio portfolio,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Generate simplified performance history
    final history = <PerformancePoint>[];
    final days = endDate.difference(startDate).inDays;

    for (int i = 0; i <= days; i += 30) { // Monthly points
      final date = startDate.add(Duration(days: i));
      final progress = i / days;
      final value = portfolio.totalCost * (1 + portfolio.totalGainLossPercent / 100 * progress);
      final returnPercent = portfolio.totalGainLossPercent * progress;

      history.add(PerformancePoint(
        date: date,
        value: value,
        returnPercent: returnPercent,
      ));
    }

    return history;
  }
}

/// Repository provider
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  final investmentService = ref.watch(investmentServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final database = ref.watch(localDatabaseProvider);
  return InvestmentRepository(investmentService, secureStorage, database);
});

final investmentServiceProvider = Provider<InvestmentService>((ref) {
  final client = ref.watch(httpClientProvider);
  return InvestmentService(client);
});

/// Mock provider for development
final mockInvestmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  final investmentService = ref.watch(mockInvestmentServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final database = ref.watch(localDatabaseProvider);
  return InvestmentRepository(investmentService, secureStorage, database);
});

final mockInvestmentServiceProvider = Provider<InvestmentService>((ref) {
  final client = ref.watch(httpClientProvider);
  return MockInvestmentService(client);
});

class MockInvestmentService extends InvestmentService {
  MockInvestmentService(super.client);

  @override
  Future<MarketData> getMarketData(String symbol) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _generateMockMarketData(symbol);
  }

  @override
  Future<List<MarketData>> getBatchMarketData(List<String> symbols) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return symbols.map((symbol) => _generateMockMarketData(symbol)).toList();
  }

  MarketData _generateMockMarketData(String symbol) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    final basePrice = 100 + (random * 200);
    final change = (random - 0.5) * 10;
    final changePercent = change / basePrice * 100;

    return MarketData(
      symbol: symbol,
      price: basePrice,
      change: change,
      changePercent: changePercent,
      volume: 1000000 + (random * 5000000).toInt(),
      marketCap: basePrice * 1000000000,
      lastUpdated: DateTime.now(),
      priceHistory: _generateMockPriceHistory(basePrice),
    );
  }

  List<PricePoint> _generateMockPriceHistory(double basePrice) {
    final history = <PricePoint>[];
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final variation = (date.millisecondsSinceEpoch % 20 - 10) / 100.0;
      final price = basePrice * (1 + variation);
      history.add(PricePoint(
        timestamp: date,
        price: price,
        volume: 1000000,
      ));
    }
    return history;
  }
}
