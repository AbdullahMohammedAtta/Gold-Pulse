import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldService {
  static const String _goldBaseUrl = 'https://api.goldprice.dev/v1/';
  static const String _fxBaseUrl = 'https://open.er-api.com/v6/latest/';

  static const Duration cacheDuration = Duration(hours: 6);
  static const String _rawSymbolsKey = 'gold_raw_symbols_v2';
  static const String _rawSymbolsTimeKey = 'gold_raw_symbols_time_v2';

  final Dio _goldDio;
  final Dio _fxDio;

  GoldService({String? apiKey})
      : _goldDio = Dio(
    BaseOptions(
      baseUrl: _goldBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        if (apiKey != null && apiKey.isNotEmpty) 'x-api-key': apiKey,
      },
    ),
  ),
        _fxDio = Dio(
          BaseOptions(
            baseUrl: _fxBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  Future<GoldPriceModel> getGoldPrices({
    String currency = 'USD',
    bool forceRefresh = false,
  }) async {
    final String targetCurrency = currency.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();

    // 1. لو في raw JSON صالح في الكاش ومفيش forceRefresh، استخدمه
    if (!forceRefresh) {
      final String? cachedJson = prefs.getString(_rawSymbolsKey);
      final String? cachedTimeStr = prefs.getString(_rawSymbolsTimeKey);
      if (cachedJson != null && cachedTimeStr != null) {
        final DateTime? savedAt = DateTime.tryParse(cachedTimeStr);
        if (savedAt != null &&
            DateTime.now().difference(savedAt) < cacheDuration) {
          final Map<String, dynamic> decoded =
          jsonDecode(cachedJson) as Map<String, dynamic>;
          return _buildFromRaw(decoded, targetCurrency);
        }
      }
    }

    // 2. سحب جديد من السيرفر
    try {
      final Response response = await _goldDio.get('prices');
      print('GOLD API STATUS: ${response.statusCode}');
      print('GOLD API DATA: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> dataMap = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        await prefs.setString(_rawSymbolsKey, jsonEncode(dataMap));
        await prefs.setString(
          _rawSymbolsTimeKey,
          DateTime.now().toIso8601String(),
        );

        return await _buildFromRaw(dataMap, targetCurrency);
      }

      throw Exception('فشل تحميل البيانات (${response.statusCode})');
    } on DioException catch (e) {
      print('DIO ERROR: ${e.message} | RESPONSE: ${e.response?.data}');
      final String? cachedJson = prefs.getString(_rawSymbolsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        return _buildFromRaw(
          jsonDecode(cachedJson) as Map<String, dynamic>,
          targetCurrency,
        );
      }
      throw Exception('تعذر الاتصال بالسيرفر');
    }
  }

  Future<GoldPriceModel> _buildFromRaw(
      Map<String, dynamic> rawData,
      String targetCurrency,
      ) async {
    double fxRate = 1.0;
    if (targetCurrency != 'USD' && !_containsXauForCurrency(rawData, targetCurrency)) {
      fxRate = await _fetchFxFromUsd(targetCurrency);
    }

    return GoldPriceModel.fromApiResponse(
      json: rawData,
      currency: targetCurrency,
      fxRate: fxRate,
      cachedTime: DateTime.now(),
    );
  }

  bool _containsXauForCurrency(Map<String, dynamic> rawData, String currency) {
    final dynamic list = rawData['symbols'];
    if (list is! List) return false;
    for (final item in list) {
      if (item is Map) {
        final String sym = (item['symbol'] ?? '').toString().trim().toUpperCase();
        final String quote =
        (item['quote_currency'] ?? '').toString().trim().toUpperCase();
        if (sym == 'XAU' && quote == currency) return true;
      }
    }
    return false;
  }

  Future<double> _fetchFxFromUsd(String currency) async {
    try {
      final Response res = await _fxDio.get('USD');
      if (res.statusCode == 200 && res.data != null) {
        final Map<String, dynamic> map = res.data is Map<String, dynamic>
            ? res.data as Map<String, dynamic>
            : jsonDecode(res.data.toString()) as Map<String, dynamic>;
        final dynamic rates = map['rates'];
        if (rates is Map && rates[currency] != null) {
          return ((rates[currency]) as num).toDouble();
        }
      }
      return 1.0;
    } catch (_) {
      return 1.0;
    }
  }
}