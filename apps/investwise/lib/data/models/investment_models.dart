/// Core investment data models for InvestWise

/// User's investment portfolio
class InvestmentPortfolio {
  final String id;
  final String userId;
  final String name;
  final double totalValue;
  final double totalCost;
  final double totalGainLoss;
  final double totalGainLossPercent;
  final List<PortfolioHolding> holdings;
  final List<InvestmentGoal> goals;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestmentPortfolio({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalValue,
    required this.totalCost,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.holdings,
    required this.goals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentPortfolio.fromJson(Map<String, dynamic> json) {
    return InvestmentPortfolio(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      totalGainLoss: (json['totalGainLoss'] as num).toDouble(),
      totalGainLossPercent: (json['totalGainLossPercent'] as num).toDouble(),
      holdings: (json['holdings'] as List<dynamic>?)
          ?.map((e) => PortfolioHolding.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => InvestmentGoal.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercent': totalGainLossPercent,
      'holdings': holdings.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate portfolio metrics
  double get diversificationScore {
    if (holdings.isEmpty) return 0.0;
    // Calculate based on sector diversification
    final sectors = holdings.map((h) => h.asset.sector).toSet();
    return (sectors.length / holdings.length).clamp(0.0, 1.0);
  }

  double get riskScore {
    if (holdings.isEmpty) return 0.0;
    // Calculate based on asset volatility and allocation
    final avgVolatility = holdings.fold<double>(0, (sum, h) =>
      sum + (h.asset.volatility * (h.value / totalValue))) / holdings.length;
    return avgVolatility.clamp(0.0, 1.0);
  }

  bool get isProfitable => totalGainLoss > 0;
  double get dailyChange => holdings.fold<double>(0, (sum, h) => sum + h.dailyChange);
  double get dailyChangePercent => holdings.isEmpty ? 0.0 :
    dailyChange / (totalValue - dailyChange) * 100;
}

/// Individual holding in a portfolio
class PortfolioHolding {
  final String id;
  final String portfolioId;
  final InvestmentAsset asset;
  final double shares;
  final double averageCost;
  final double currentPrice;
  final double value;
  final double cost;
  final double gainLoss;
  final double gainLossPercent;
  final double dailyChange;
  final double dailyChangePercent;
  final DateTime purchasedAt;
  final DateTime updatedAt;

  const PortfolioHolding({
    required this.id,
    required this.portfolioId,
    required this.asset,
    required this.shares,
    required this.averageCost,
    required this.currentPrice,
    required this.value,
    required this.cost,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.purchasedAt,
    required this.updatedAt,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      id: json['id'] as String,
      portfolioId: json['portfolioId'] as String,
      asset: InvestmentAsset.fromJson(json['asset'] as Map<String, dynamic>),
      shares: (json['shares'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      gainLoss: (json['gainLoss'] as num).toDouble(),
      gainLossPercent: (json['gainLossPercent'] as num).toDouble(),
      dailyChange: (json['dailyChange'] as num).toDouble(),
      dailyChangePercent: (json['dailyChangePercent'] as num).toDouble(),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolioId': portfolioId,
      'asset': asset.toJson(),
      'shares': shares,
      'averageCost': averageCost,
      'currentPrice': currentPrice,
      'value': value,
      'cost': cost,
      'gainLoss': gainLoss,
      'gainLossPercent': gainLossPercent,
      'dailyChange': dailyChange,
      'dailyChangePercent': dailyChangePercent,
      'purchasedAt': purchasedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isProfitable => gainLoss > 0;
  double get allocationPercent => value; // Will be calculated relative to portfolio
}

/// Investment asset (stock, ETF, crypto, etc.)
class InvestmentAsset {
  final String id;
  final String symbol;
  final String name;
  final String type; // 'stock', 'etf', 'crypto', 'bond'
  final String exchange;
  final String sector;
  final String industry;
  final double currentPrice;
  final double marketCap;
  final double peRatio;
  final double dividendYield;
  final double volatility; // 0-1 scale
  final double beta;
  final String currency;
  final String description;
  final DateTime lastUpdated;

  const InvestmentAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    required this.exchange,
    required this.sector,
    required this.industry,
    required this.currentPrice,
    required this.marketCap,
    required this.peRatio,
    required this.dividendYield,
    required this.volatility,
    required this.beta,
    required this.currency,
    required this.description,
    required this.lastUpdated,
  });

  factory InvestmentAsset.fromJson(Map<String, dynamic> json) {
    return InvestmentAsset(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      exchange: json['exchange'] as String,
      sector: json['sector'] as String,
      industry: json['industry'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      marketCap: (json['marketCap'] as num?)?.toDouble() ?? 0.0,
      peRatio: (json['peRatio'] as num?)?.toDouble() ?? 0.0,
      dividendYield: (json['dividendYield'] as num?)?.toDouble() ?? 0.0,
      volatility: (json['volatility'] as num?)?.toDouble() ?? 0.5,
      beta: (json['beta'] as num?)?.toDouble() ?? 1.0,
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String? ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'type': type,
      'exchange': exchange,
      'sector': sector,
      'industry': industry,
      'currentPrice': currentPrice,
      'marketCap': marketCap,
      'peRatio': peRatio,
      'dividendYield': dividendYield,
      'volatility': volatility,
      'beta': beta,
      'currency': currency,
      'description': description,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Get asset color for UI
  Color get assetColor {
    switch (type) {
      case 'stock': return Colors.blue;
      case 'etf': return Colors.green;
      case 'crypto': return Colors.orange;
      case 'bond': return Colors.purple;
      default: return Colors.grey;
    }
  }

  /// Get risk level
  String get riskLevel {
    if (volatility < 0.3) return 'Low';
    if (volatility < 0.7) return 'Medium';
    return 'High';
  }

  /// Check if asset is dividend paying
  bool get isDividendStock => dividendYield > 0;

  /// Get formatted market cap
  String get formattedMarketCap {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(1)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(1)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap.toStringAsFixed(0)}';
  }
}

/// Investment goal for targeted saving/investing
class InvestmentGoal {
  final String id;
  final String portfolioId;
  final String name;
  final String description;
  final String category; // 'emergency', 'vacation', 'house', 'retirement', 'education'
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final double monthlyContribution;
  final bool isAutoInvest;
  final List<String> recommendedAssets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestmentGoal({
    required this.id,
    required this.portfolioId,
    required this.name,
    required this.description,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.monthlyContribution,
    required this.isAutoInvest,
    required this.recommendedAssets,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentGoal.fromJson(Map<String, dynamic> json) {
    return InvestmentGoal(
      id: json['id'] as String,
      portfolioId: json['portfolioId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      monthlyContribution: (json['monthlyContribution'] as num).toDouble(),
      isAutoInvest: json['isAutoInvest'] as bool? ?? false,
      recommendedAssets: (json['recommendedAssets'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolioId': portfolioId,
      'name': name,
      'description': description,
      'category': category,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'monthlyContribution': monthlyContribution,
      'isAutoInvest': isAutoInvest,
      'recommendedAssets': recommendedAssets,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate progress percentage
  double get progressPercent => (currentAmount / targetAmount).clamp(0.0, 1.0);

  /// Calculate months remaining
  int get monthsRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays ~/ 30;
  }

  /// Calculate required monthly contribution to reach goal
  double get requiredMonthlyContribution {
    final remaining = targetAmount - currentAmount;
    final months = monthsRemaining > 0 ? monthsRemaining : 1;
    return remaining / months;
  }

  /// Check if goal is on track
  bool get isOnTrack => monthlyContribution >= requiredMonthlyContribution * 0.8;

  /// Get goal status
  String get status {
    if (currentAmount >= targetAmount) return 'Completed';
    if (targetDate.isBefore(DateTime.now())) return 'Overdue';
    if (isOnTrack) return 'On Track';
    return 'Behind Schedule';
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'On Track': return Colors.blue;
      case 'Behind Schedule': return Colors.orange;
      case 'Overdue': return Colors.red;
      default: return Colors.grey;
    }
  }
}

/// Market data and trading information
class MarketData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final double volume;
  final double marketCap;
  final DateTime lastUpdated;
  final List<PricePoint> priceHistory;

  const MarketData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.marketCap,
    required this.lastUpdated,
    required this.priceHistory,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      priceHistory: (json['priceHistory'] as List<dynamic>?)
          ?.map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'marketCap': marketCap,
      'lastUpdated': lastUpdated.toIso8601String(),
      'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
    };
  }
}

/// Price point for charting
class PricePoint {
  final DateTime timestamp;
  final double price;
  final double volume;

  const PricePoint({
    required this.timestamp,
    required this.price,
    required this.volume,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      price: (json['price'] as num).toDouble(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
      'volume': volume,
    };
  }
}

/// Investment transaction record
class InvestmentTransaction {
  final String id;
  final String portfolioId;
  final String assetId;
  final String type; // 'buy', 'sell', 'dividend', 'fee'
  final double amount;
  final double shares;
  final double price;
  final double total;
  final DateTime timestamp;
  final String? notes;

  const InvestmentTransaction({
    required this.id,
    required this.portfolioId,
    required this.assetId,
    required this.type,
    required this.amount,
    required this.shares,
    required this.price,
    required this.total,
    required this.timestamp,
    this.notes,
  });

  factory InvestmentTransaction.fromJson(Map<String, dynamic> json) {
    return InvestmentTransaction(
      id: json['id'] as String,
      portfolioId: json['portfolioId'] as String,
      assetId: json['assetId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      shares: (json['shares'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolioId': portfolioId,
      'assetId': assetId,
      'type': type,
      'amount': amount,
      'shares': shares,
      'price': price,
      'total': total,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  bool get isBuy => type == 'buy';
  bool get isSell => type == 'sell';
  bool get isDividend => type == 'dividend';
  bool get isFee => type == 'fee';
}

/// Micro-investment settings
class MicroInvestmentSettings {
  final String id;
  final String userId;
  final bool isEnabled;
  final double dailyLimit;
  final double roundUpAmount;
  final List<String> excludedCategories;
  final String investmentStrategy; // 'conservative', 'balanced', 'aggressive'
  final bool autoRebalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MicroInvestmentSettings({
    required this.id,
    required this.userId,
    required this.isEnabled,
    required this.dailyLimit,
    required this.roundUpAmount,
    required this.excludedCategories,
    required this.investmentStrategy,
    required this.autoRebalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MicroInvestmentSettings.fromJson(Map<String, dynamic> json) {
    return MicroInvestmentSettings(
      id: json['id'] as String,
      userId: json['userId'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
      dailyLimit: (json['dailyLimit'] as num?)?.toDouble() ?? 10.0,
      roundUpAmount: (json['roundUpAmount'] as num?)?.toDouble() ?? 1.0,
      excludedCategories: (json['excludedCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      investmentStrategy: json['investmentStrategy'] as String? ?? 'balanced',
      autoRebalance: json['autoRebalance'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'isEnabled': isEnabled,
      'dailyLimit': dailyLimit,
      'roundUpAmount': roundUpAmount,
      'excludedCategories': excludedCategories,
      'investmentStrategy': investmentStrategy,
      'autoRebalance': autoRebalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get strategy risk level
  double get riskLevel {
    switch (investmentStrategy) {
      case 'conservative': return 0.3;
      case 'balanced': return 0.5;
      case 'aggressive': return 0.8;
      default: return 0.5;
    }
  }
}
