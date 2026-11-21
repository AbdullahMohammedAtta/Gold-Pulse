import 'package:dio/dio.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';

class ChartService {
  final Dio _dio;

  ChartService({Dio? dio})
      : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: 'https://api.goldprice.dev',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  Future<List<GoldBarModel>> fetchBars({
    String symbol = 'XAU-USD-SPOT',
    required DateTime from,
    required DateTime to,
    String interval = '1d',
    int limit = 100,
    String? apiKey,
  }) async {
    final String fromStr = _formatDate(from);
    final String toStr = _formatDate(to);

    final response = await _dio.get(
      '/v1/bars',
      queryParameters: {
        'symbol': symbol,
        'from': fromStr,
        'to': toStr,
        'interval': interval,
        'limit': limit,
      },
      options: apiKey != null && apiKey.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $apiKey'})
          : null,
    );

    final data = response.data;
    List<dynamic> rawList = const [];

    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      if (data['bars'] is List) {
        rawList = data['bars'] as List;
      } else if (data['data'] is List) {
        rawList = data['data'] as List;
      } else if (data['items'] is List) {
        rawList = data['items'] as List;
      }
    }

    final bars = rawList
        .whereType>()
        .map(GoldBarModel.fromJson)
        .toList();

    bars.sort((a, b) => a.date.compareTo(b.date));
    return bars;
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}