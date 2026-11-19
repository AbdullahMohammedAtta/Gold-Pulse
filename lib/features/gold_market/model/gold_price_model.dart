class GoldPriceModel {
  final double priceOunce;
  final double priceGram24k;
  final double priceGram22k;
  final double priceGram21k;
  final double priceGram18k;
  final double changePercentage;
  final String currency;
  final DateTime lastUpdated;

  GoldPriceModel({
    required this.priceOunce,
    required this.priceGram24k,
    required this.priceGram22k,
    required this.priceGram21k,
    required this.priceGram18k,
    required this.changePercentage,
    required this.currency,
    required this.lastUpdated,
  });

  /// بناء الموديل من استجابة goldprice.dev أو من الكاش المحلي
  factory GoldPriceModel.fromApiResponse({
    required Map<String, dynamic> json,
    required String currency,
    double fxRate = 1.0,
    DateTime? cachedTime,
  }) {
    // في goldprice.dev السعر الأساسي للأونصة بيكون غالباً تحت مفتاح 'price' أو 'spot' أو 'gold'
    final double rawOunceUsd =
    ((json['price'] ?? json['spot'] ?? json['gold'] ?? 0) as num)
        .toDouble();

    // تحويل الأونصة إلى جرام عيار 24 (الأونصة التروي = 31.1034768 جرام)
    const double gramsPerTroyOunce = 31.1034768;
    double gram24Usd =
    rawOunceUsd > 0 ? (rawOunceUsd / gramsPerTroyOunce) : 0.0;

    // لو الاستجابة فيها أسعار عيارات جاهزة (عند استخدام ?include=karat) نستخدمها لو متاحة
    final Map<String, dynamic>? karats =
    json['karats'] is Map<String, dynamic>
        ? json['karats'] as Map<String, dynamic>
        : (json['karat'] is Map<String, dynamic>
        ? json['karat'] as Map<String, dynamic>
        : null);

    double gram24 = gram24Usd;
    double gram22 = gram24 * (22 / 24);
    double gram21 = gram24 * (21 / 24);
    double gram18 = gram24 * (18 / 24);

    if (karats != null) {
      gram24 = ((karats['24k'] ?? karats['24K'] ?? gram24) as num).toDouble();
      gram22 = ((karats['22k'] ?? karats['22K'] ?? gram22) as num).toDouble();
      gram21 = ((karats['21k'] ?? karats['21K'] ?? gram21) as num).toDouble();
      gram18 = ((karats['18k'] ?? karats['18K'] ?? gram18) as num).toDouble();
    }

    // تطبيق معامل تحويل العملة (1.0 للدولار، أو سعر الصرف للعملة المختارة)
    final double ounceInCurrency = rawOunceUsd * fxRate;
    final double g24InCurrency = gram24 * fxRate;
    final double g22InCurrency = gram22 * fxRate;
    final double g21InCurrency = gram21 * fxRate;
    final double g18InCurrency = gram18 * fxRate;

    final double chp =
    ((json['chp'] ?? json['change_percent'] ?? json['changePercent'] ?? 0)
    as num)
        .toDouble();

    return GoldPriceModel(
      priceOunce: ounceInCurrency,
      priceGram24k: g24InCurrency,
      priceGram22k: g22InCurrency,
      priceGram21k: g21InCurrency,
      priceGram18k: g18InCurrency,
      changePercentage: chp,
      currency: currency.toUpperCase(),
      lastUpdated: cachedTime ?? DateTime.now(),
    );
  }

  /// تحويل الموديل لـ JSON لحفظه في SharedPreferences
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

  /// قراءة مباشرة من بيانات مخزنة مسبقاً بالعملة المطلوبة
  factory GoldPriceModel.fromCacheJson(Map<String, dynamic> map) {
    return GoldPriceModel(
      priceOunce: ((map['price'] ?? 0) as num).toDouble(),
      priceGram24k: ((map['price_gram_24k'] ?? 0) as num).toDouble(),
      priceGram22k: ((map['price_gram_22k'] ?? 0) as num).toDouble(),
      priceGram21k: ((map['price_gram_21k'] ?? 0) as num).toDouble(),
      priceGram18k: ((map['price_gram_18k'] ?? 0) as num).toDouble(),
      changePercentage: ((map['chp'] ?? 0) as num).toDouble(),
      currency: (map['currency'] ?? 'USD').toString(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
    );
  }
}