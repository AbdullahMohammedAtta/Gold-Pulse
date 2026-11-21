import 'package:shared_preferences/shared_preferences.dart';

class CurrencyStorage {
  static const String _keySelectedCurrency = 'selected_gold_currency';
  static const String _keySelectedFxRate = 'selected_gold_fx_rate';

  Future<void> saveCurrency(String currency, {double? fxRate}) async {
    final prefs = await SharedPreferences.getInstance();
    final String clean = currency.trim().toUpperCase();
    if (clean.isEmpty) return;

    await prefs.setString(_keySelectedCurrency, clean);
    if (clean == 'USD') {
      await prefs.setDouble(_keySelectedFxRate, 1.0);
    } else if (fxRate != null && fxRate > 0) {
      await prefs.setDouble(_keySelectedFxRate, fxRate);
    }
  }

  Future<String> loadCurrency({String fallback = 'EGP'}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_keySelectedCurrency);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().toUpperCase();
    }
    return fallback.toUpperCase();
  }

  Future<double?> loadFxRate() async {
    final prefs = await SharedPreferences.getInstance();
    final double? val = prefs.getDouble(_keySelectedFxRate);
    if (val != null && val > 0) return val;
    return null;
  }

  // معامل تحويل احتياطي للعملات الشائعة في حال عدم توفره لحظياً من الحالة
  double fallbackFxRateFor(String currency) {
    switch (currency.trim().toUpperCase()) {
      case 'USD':
        return 1.0;
      case 'EGP':
        return 50.0;
      case 'AED':
        return 3.6725;
      case 'SAR':
        return 3.75;
      case 'EUR':
        return 0.92;
      case 'GBP':
        return 0.79;
      default:
        return 1.0;
    }
  }
}