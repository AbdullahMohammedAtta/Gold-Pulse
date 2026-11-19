class GoldPriceModel {
  final double priceOunce;
  final double priceGram24k;
  final double priceGram22k;
  final double priceGram21k;
  final double priceGram18k;
  final double changePercentage;
  final String currency;
  final DateTime lastUpdated;

  const GoldPriceModel({
    required this.priceOunce,
    required this.priceGram24k,
    required this.priceGram22k,
    required this.priceGram21k,
    required this.priceGram18k,
    required this.changePercentage,
    required this.currency,
    required this.lastUpdated,
  });

  static const double _gramsPerTroyOunce = 31.1034768;

  factory GoldPriceModel.fromApiResponse({
    required Map<String, dynamic> json,
    required String currency,
    double fxRate = 1.0,
    DateTime? cachedTime,
  }) {
    final String targetCurrency = currency.trim().toUpperCase();
    final List<dynamic> symbols =
    json['symbols'] is List ? json['symbols'] as List : const [];

    Map<String, dynamic>? directMatch;
    Map<String, dynamic>? usdMatch;

    for (final item in symbols) {
      if (item is Map) {
        final String sym =
        (item['symbol'] ?? '').toString().trim().toUpperCase();
        final String quote =
        (item['quote_currency'] ?? '').toString().trim().toUpperCase();

        if (sym == 'XAU' && quote == targetCurrency) {
          directMatch = Map<String, dynamic>.from(item);
          break;
        }
        if (sym == 'XAU' && quote == 'USD') {
          usdMatch = Map<String, dynamic>.from(item);
        }
      }
    }

    double ouncePrice = 0.0;
    DateTime resolvedDate = cachedTime ?? DateTime.now();

    if (directMatch != null) {
      ouncePrice = _parseDouble(directMatch['price']);
      resolvedDate =
          DateTime.tryParse((directMatch['computed_at'] ?? '').toString())
              ?.toLocal() ??
              resolvedDate;
    } else if (usdMatch != null) {
      final double usdOunce = _parseDouble(usdMatch['price']);
      ouncePrice = usdOunce * (fxRate > 0 ? fxRate : 1.0);
      resolvedDate =
          DateTime.tryParse((usdMatch['computed_at'] ?? '').toString())
              ?.toLocal() ??
              resolvedDate;
    }

    final double gram24 =
    ouncePrice > 0 ? (ouncePrice / _gramsPerTroyOunce) : 0.0;

    final double chp = _parseDouble(
      json['chp'] ?? json['change_percent'] ?? json['changePercent'] ?? 0,
    );

    return GoldPriceModel(
      priceOunce: ouncePrice,
      priceGram24k: gram24,
      priceGram22k: gram24 * (22 / 24),
      priceGram21k: gram24 * (21 / 24),
      priceGram18k: gram24 * (18 / 24),
      changePercentage: chp,
      currency: targetCurrency,
      lastUpdated: resolvedDate,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'price': priceOunce,
      'price_gram_24k': priceGram24k,
      'price_gram_22k': priceGram22k,
      'price_gram_21k': priceGram21k,
      'price_gram_18k': priceGram18k,
      'chp': changePercentage,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory GoldPriceModel.fromCacheJson(Map<String, dynamic> map) {
    return GoldPriceModel(
      priceOunce: _parseDouble(map['price']),
      priceGram24k: _parseDouble(map['price_gram_24k']),
      priceGram22k: _parseDouble(map['price_gram_22k']),
      priceGram21k: _parseDouble(map['price_gram_21k']),
      priceGram18k: _parseDouble(map['price_gram_18k']),
      changePercentage: _parseDouble(map['chp']),
      currency: (map['currency'] ?? 'USD').toString(),
      lastUpdated: map['lastUpdated'] != null
          ? (DateTime.tryParse(map['lastUpdated'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }
}