import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldService {
  static const String _goldBaseUrl = 'https://api.goldprice.dev/v1/';
  static const String _fxBaseUrl = 'https://open.er-api.com/v6/latest/';

  // مدة الكاش: 1 ساعة
  static const Duration cacheDuration = Duration(hours: 6);

  final Dio _goldDio;
  final Dio _fxDio;

  /// يمكنك تمرير [apiKey] إذا كان لديك مفتاح من goldprice.dev، أو تركه فارغاً للخطة المجانية
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
        ) {
    // Interceptor خفيف لطباعة الطلبات والأخطاء أثناء التطوير
    _goldDio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// جلب أسعار الذهب بالعملة المطلوبة (الافتراضي: USD أو EGP)
  /// [forceRefresh] = true عند ضغط المستخدم على زر تحديث يدوي

  Future<GoldPriceModel> getGoldPrices({
    String currency = 'USD',
    bool forceRefresh = false,
  }) async {
    final String normalizedCurrency = currency.trim().toUpperCase();
    final String cacheKey = 'gold_price_cache_$normalizedCurrency';
    final prefs = await SharedPreferences.getInstance();

    // 1. التحقق من الكاش المحلي (لو أقل من 6 ساعات ومفيش Force Refresh)
    if (!forceRefresh && prefs.containsKey(cacheKey)) {
      final String? cachedRaw = prefs.getString(cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final Map<String, dynamic> cachedMap = jsonDecode(cachedRaw);
        final DateTime savedAt = DateTime.parse(cachedMap['lastUpdated']);

        if (DateTime.now().difference(savedAt) < cacheDuration) {
          return GoldPriceModel.fromCacheJson(cachedMap);
        }
      }
    }

    // 2. جلب البيانات الجديدة من goldprice.dev عبر Dio
    try {
      final Response goldResponse = await _goldDio.get(
        'prices',
        queryParameters: {
          'include': 'karat',
        },
      );

      if (goldResponse.statusCode == 200 && goldResponse.data != null) {
        final Map<String, dynamic> goldData =
        goldResponse.data is Map<String, dynamic>
            ? goldResponse.data as Map<String, dynamic>
            : jsonDecode(goldResponse.data.toString());

        // حساب معامل تحويل العملة لو العملة مش USD
        double fxRate = 1.0;
        if (normalizedCurrency != 'USD') {
          fxRate = await _getUsdToCurrencyRate(normalizedCurrency);
        }

        final GoldPriceModel model = GoldPriceModel.fromApiResponse(
          json: goldData,
          currency: normalizedCurrency,
          fxRate: fxRate,
          cachedTime: DateTime.now(),
        );

        // حفظ النتيجة في الكاش المحلي
        await prefs.setString(cacheKey, jsonEncode(model.toCacheJson()));

        return model;
      } else {
        throw Exception(
          'تعذر جلب أسعار الذهب (رمز الحالة: ${goldResponse.statusCode})',
        );
      }
    } on DioException catch (e) {
      // في حالة فشل الشبكة أو Timeout، نرجع آخر كاش متاح إن وجد
      final GoldPriceModel? fallback = await _tryReadCache(prefs, cacheKey);
      if (fallback != null) {
        return fallback;
      }
      throw Exception(_mapDioError(e));
    } catch (e) {
      final GoldPriceModel? fallback = await _tryReadCache(prefs, cacheKey);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }

  /// جلب سعر صرف الدولار مقابل العملة المطلوبة (مثلاً USD -> EGP)
  Future<double> _getUsdToCurrencyRate(String targetCurrency) async {
    try {
      final Response fxResponse = await _fxDio.get('USD');
      if (fxResponse.statusCode == 200 && fxResponse.data != null) {
        final Map<String, dynamic> data =
        fxResponse.data is Map<String, dynamic>
            ? fxResponse.data as Map<String, dynamic>
            : jsonDecode(fxResponse.data.toString());

        final dynamic rates = data['rates'];
        if (rates is Map<String, dynamic> && rates[targetCurrency] != null) {
          return ((rates[targetCurrency]) as num).toDouble();
        }
      }
      throw Exception('العملة $targetCurrency غير متوفرة حالياً');
    } on DioException {
      throw Exception('تعذر تحديث سعر صرف العملة $targetCurrency');
    }
  }

  Future<GoldPriceModel?> _tryReadCache(
      SharedPreferences prefs,
      String cacheKey,
      ) async {
    if (!prefs.containsKey(cacheKey)) return null;
    final String? cachedRaw = prefs.getString(cacheKey);
    if (cachedRaw == null || cachedRaw.isEmpty) return null;
    return GoldPriceModel.fromCacheJson(jsonDecode(cachedRaw));
  }

  String _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بالسيرفر، حاول مرة أخرى.';
      case DioExceptionType.connectionError:
        return 'لا يوجد اتصال بالإنترنت حالياً.';
      case DioExceptionType.badResponse:
        return 'حدث خطأ من السيرفر (${error.response?.statusCode ?? ''}).';
      default:
        return 'حدث خطأ غير متوقع أثناء جلب الأسعار.';
    }
  }
}