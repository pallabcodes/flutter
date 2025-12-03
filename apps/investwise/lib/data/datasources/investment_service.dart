import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment_models.dart';

/// Service for investment operations and market data
class InvestmentService {
  final http.Client _client;
  static const String _baseUrl = 'https://api.investwise.com/v1'; // Placeholder

  InvestmentService(this._client);

  /// Get market data for a specific symbol
  Future<MarketData> getMarketData(String symbol) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/$symbol'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarketData.fromJson(data);
      } else {
        throw InvestmentException('Failed to fetch market data: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Market data fetch failed: ${e.toString()}');
    }
  }

  /// Get market data for multiple symbols
  Future<List<MarketData>> getBatchMarketData(List<String> symbols) async {
    try {
      final symbolsParam = symbols.join(',');
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/batch?symbols=$symbolsParam'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => MarketData.fromJson(item)).toList();
      } else {
        throw InvestmentException('Failed to fetch batch market data: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Batch market data fetch failed: ${e.toString()}');
    }
  }

  /// Search for investment assets
  Future<List<InvestmentAsset>> searchAssets(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/search?q=$query'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => InvestmentAsset.fromJson(item)).toList();
      } else {
        throw InvestmentException('Asset search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Asset search failed: ${e.toString()}');
    }
  }

  /// Execute a buy order
  Future<InvestmentTransaction> executeBuyOrder({
    required String portfolioId,
    required String assetId,
    required double amount,
    required String userId,
  }) async {
    try {
      final orderData = {
        'portfolioId': portfolioId,
        'assetId': assetId,
        'amount': amount,
        'type': 'buy',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/orders/buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return InvestmentTransaction.fromJson(data);
      } else {
        throw InvestmentException('Buy order failed: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Buy order execution failed: ${e.toString()}');
    }
  }

  /// Execute a sell order
  Future<InvestmentTransaction> executeSellOrder({
    required String portfolioId,
    required String assetId,
    required double shares,
    required String userId,
  }) async {
    try {
      final orderData = {
        'portfolioId': portfolioId,
        'assetId': assetId,
        'shares': shares,
        'type': 'sell',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/orders/sell'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return InvestmentTransaction.fromJson(data);
      } else {
        throw InvestmentException('Sell order failed: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Sell order execution failed: ${e.toString()}');
    }
  }

  /// Process micro-investment from spare change
  Future<InvestmentTransaction> processMicroInvestment({
    required String portfolioId,
    required double amount,
    required String strategy,
    required String userId,
  }) async {
    try {
      // Determine asset allocation based on strategy
      final assetAllocations = await _getStrategyAllocations(strategy, amount);

      // Execute multiple small purchases
      final transactions = <InvestmentTransaction>[];

      for (final allocation in assetAllocations) {
        final transaction = await executeBuyOrder(
          portfolioId: portfolioId,
          assetId: allocation['assetId'],
          amount: allocation['amount'],
          userId: userId,
        );
        transactions.add(transaction);
      }

      // Return primary transaction (simplified)
      return transactions.first;
    } catch (e) {
      throw InvestmentException('Micro-investment failed: ${e.toString()}');
    }
  }

  /// Get AI-powered investment recommendations
  Future<List<InvestmentRecommendation>> getAIRecommendations({
    required String userId,
    required InvestmentPortfolio portfolio,
    required RiskProfile riskProfile,
  }) async {
    try {
      final requestData = {
        'userId': userId,
        'portfolio': portfolio.toJson(),
        'riskProfile': riskProfile.toJson(),
        'marketConditions': await _getMarketConditions(),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/recommendations/ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => InvestmentRecommendation.fromJson(item)).toList();
      } else {
        throw InvestmentException('AI recommendations failed: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('AI recommendations failed: ${e.toString()}');
    }
  }

  /// Calculate portfolio rebalancing recommendations
  Future<List<PortfolioRebalance>> calculateRebalancing({
    required InvestmentPortfolio portfolio,
    required String targetStrategy,
  }) async {
    try {
      final allocations = await _getStrategyAllocations(targetStrategy, portfolio.totalValue);

      final rebalances = <PortfolioRebalance>[];

      for (final allocation in allocations) {
        final assetId = allocation['assetId'];
        final targetValue = allocation['amount'];

        // Find current holding
        final currentHolding = portfolio.holdings
            .firstWhere((h) => h.asset.id == assetId, orElse: () => null);

        if (currentHolding != null) {
          final currentValue = currentHolding.value;
          final difference = targetValue - currentValue;

          if (difference.abs() > 1.0) { // Only rebalance if difference > $1
            rebalances.add(PortfolioRebalance(
              assetId: assetId,
              assetName: currentHolding.asset.name,
              currentValue: currentValue,
              targetValue: targetValue,
              difference: difference,
              action: difference > 0 ? 'buy' : 'sell',
              priority: (difference.abs() / portfolio.totalValue),
            ));
          }
        } else if (targetValue > 1.0) {
          // New asset to buy
          rebalances.add(PortfolioRebalance(
            assetId: assetId,
            assetName: allocation['assetName'],
            currentValue: 0.0,
            targetValue: targetValue,
            difference: targetValue,
            action: 'buy',
            priority: targetValue / portfolio.totalValue,
          ));
        }
      }

      // Sort by priority (largest changes first)
      rebalances.sort((a, b) => b.priority.compareTo(a.priority));

      return rebalances;
    } catch (e) {
      throw InvestmentException('Rebalancing calculation failed: ${e.toString()}');
    }
  }

  /// Get trending investments
  Future<List<TrendingInvestment>> getTrendingInvestments({
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/trending?limit=$limit'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => TrendingInvestment.fromJson(item)).toList();
      } else {
        throw InvestmentException('Trending investments fetch failed: ${response.statusCode}');
      }
    } catch (e) {
      throw InvestmentException('Trending investments fetch failed: ${e.toString()}');
    }
  }

  // Helper methods
  Future<List<Map<String, dynamic>>> _getStrategyAllocations(String strategy, double amount) async {
    // This would call an API to get strategy allocations
    // For now, return mock allocations based on strategy

    switch (strategy) {
      case 'conservative':
        return [
          {'assetId': 'BND', 'assetName': 'Vanguard Total Bond Market', 'amount': amount * 0.7},
          {'assetId': 'VTI', 'assetName': 'Vanguard Total Stock Market', 'amount': amount * 0.2},
          {'assetId': 'VXUS', 'assetName': 'Vanguard Total International Stock', 'amount': amount * 0.1},
        ];

      case 'balanced':
        return [
          {'assetId': 'VTI', 'assetName': 'Vanguard Total Stock Market', 'amount': amount * 0.5},
          {'assetId': 'VXUS', 'assetName': 'Vanguard Total International Stock', 'amount': amount * 0.3},
          {'assetId': 'BND', 'assetName': 'Vanguard Total Bond Market', 'amount': amount * 0.2},
        ];

      case 'aggressive':
        return [
          {'assetId': 'VTI', 'assetName': 'Vanguard Total Stock Market', 'amount': amount * 0.7},
          {'assetId': 'VXUS', 'assetName': 'Vanguard Total International Stock', 'amount': amount * 0.2},
          {'assetId': 'QQQ', 'assetName': 'Invesco QQQ', 'amount': amount * 0.1},
        ];

      default:
        return [
          {'assetId': 'VTI', 'assetName': 'Vanguard Total Stock Market', 'amount': amount},
        ];
    }
  }

  Future<Map<String, dynamic>> _getMarketConditions() async {
    // Get current market conditions for AI recommendations
    return {
      'volatility': 0.15,
      'trend': 'bullish',
      'interestRates': 0.045,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Exception for investment service errors
class InvestmentException implements Exception {
  final String message;

  InvestmentException(this.message);

  @override
  String toString() => 'InvestmentException: $message';
}

/// Additional data models for investment operations

/// Risk profile for personalized recommendations
class RiskProfile {
  final String userId;
  final int age;
  final String investmentExperience; // 'beginner', 'intermediate', 'advanced'
  final String timeHorizon; // 'short', 'medium', 'long'
  final double riskTolerance; // 0-1 scale
  final List<String> investmentGoals;
  final double monthlyIncome;
  final double monthlyExpenses;

  const RiskProfile({
    required this.userId,
    required this.age,
    required this.investmentExperience,
    required this.timeHorizon,
    required this.riskTolerance,
    required this.investmentGoals,
    required this.monthlyIncome,
    required this.monthlyExpenses,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'age': age,
      'investmentExperience': investmentExperience,
      'timeHorizon': timeHorizon,
      'riskTolerance': riskTolerance,
      'investmentGoals': investmentGoals,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
    };
  }
}

/// AI-powered investment recommendation
class InvestmentRecommendation {
  final String id;
  final String assetId;
  final String assetName;
  final String reasoning;
  final double confidence;
  final double expectedReturn;
  final double riskLevel;
  final String timeHorizon;
  final List<String> pros;
  final List<String> cons;

  const InvestmentRecommendation({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.reasoning,
    required this.confidence,
    required this.expectedReturn,
    required this.riskLevel,
    required this.timeHorizon,
    required this.pros,
    required this.cons,
  });

  factory InvestmentRecommendation.fromJson(Map<String, dynamic> json) {
    return InvestmentRecommendation(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      assetName: json['assetName'] as String,
      reasoning: json['reasoning'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      expectedReturn: (json['expectedReturn'] as num).toDouble(),
      riskLevel: (json['riskLevel'] as num).toDouble(),
      timeHorizon: json['timeHorizon'] as String,
      pros: (json['pros'] as List<dynamic>).map((e) => e as String).toList(),
      cons: (json['cons'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

/// Portfolio rebalancing recommendation
class PortfolioRebalance {
  final String assetId;
  final String assetName;
  final double currentValue;
  final double targetValue;
  final double difference;
  final String action; // 'buy', 'sell'
  final double priority; // 0-1 scale

  const PortfolioRebalance({
    required this.assetId,
    required this.assetName,
    required this.currentValue,
    required this.targetValue,
    required this.difference,
    required this.action,
    required this.priority,
  });
}

/// Trending investment data
class TrendingInvestment {
  final String assetId;
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final int searchVolume;
  final String trend; // 'up', 'down', 'neutral'

  const TrendingInvestment({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.searchVolume,
    required this.trend,
  });

  factory TrendingInvestment.fromJson(Map<String, dynamic> json) {
    return TrendingInvestment(
      assetId: json['assetId'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      searchVolume: json['searchVolume'] as int,
      trend: json['trend'] as String,
    );
  }
}
