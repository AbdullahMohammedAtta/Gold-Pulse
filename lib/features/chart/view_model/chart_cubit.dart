import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/chart_service.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';
import 'package:gold/features/chart/view_model/chart_state.dart';

class ChartCubit extends Cubit<ChartState> {
  final ChartService _service;

  ChartRange _currentRange = ChartRange.month;
  String _currentCurrency = 'USD';
  double? _currentFxRate;

  ChartCubit({ChartService? service})
      : _service = service ?? ChartService(),
        super(ChartInitial());

  ChartRange get currentRange => _currentRange;
  String get currentCurrency => _currentCurrency;
  double? get currentFxRate => _currentFxRate;

  int _daysForRange(ChartRange range) {
    switch (range) {
      case ChartRange.week:
        return 7;
      case ChartRange.month:
        return 30;
      case ChartRange.quarter:
        return 90;
    }
  }

  Future<void> loadChart({
    ChartRange? range,
    String? currency,
    double? fxRateToCurrency,
  }) async {
    if (range != null) _currentRange = range;
    if (currency != null) _currentCurrency = currency;
    if (fxRateToCurrency != null) {
      _currentFxRate = fxRateToCurrency;
    } else if (_currentCurrency == 'USD') {
      _currentFxRate = 1.0;
    }

    emit(ChartLoading());

    try {
      final DateTime to = DateTime.now();
      final DateTime from =
      to.subtract(Duration(days: _daysForRange(_currentRange)));

      final rawBars = await _service.fetchBars(
        symbol: 'XAU-USD-SPOT',
        from: from,
        to: to,
        interval: '1d',
        limit: 120,
      );

      if (rawBars.isEmpty) {
        emit(ChartError('لا توجد بيانات تاريخية متاحة لهذه الفترة حالياً'));
        return;
      }

      final bool applyFx = _currentCurrency != 'USD' &&
          _currentFxRate != null &&
          _currentFxRate! > 0;
      final double multiplier = applyFx ? _currentFxRate! : 1.0;
      final String effectiveCurrency = applyFx ? _currentCurrency : 'USD';

      final List<GoldBarModel> convertedBars = [];
      for (final bar in rawBars) {
        convertedBars.add(
          GoldBarModel(
            date: bar.date,
            open: bar.open * multiplier,
            high: bar.high * multiplier,
            low: bar.low * multiplier,
            close: bar.close * multiplier,
          ),
        );
      }

      double high = convertedBars.first.high;
      double low = convertedBars.first.low;

      for (final bar in convertedBars) {
        if (bar.high > high) high = bar.high;
        if (bar.low < low) low = bar.low;
      }

      final double firstClose = convertedBars.first.close;
      final double lastClose = convertedBars.last.close;
      final double changePercent = firstClose > 0
          ? ((lastClose - firstClose) / firstClose) * 100
          : 0.0;

      emit(
        ChartLoaded(
          bars: convertedBars,
          range: _currentRange,
          currency: effectiveCurrency,
          periodHigh: high,
          periodLow: low,
          changePercent: changePercent,
          isConvertedByCurrentFx: applyFx,
        ),
      );
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        emit(
          ChartError(
            'نقطة /v1/bars تتطلب صلاحية أو مفتاح API مناسب في خطتك الحالية',
          ),
        );
      } else {
        emit(
          ChartError(
            e.message ?? 'تعذر تحميل بيانات الرسم البياني، حاول مرة أخرى',
          ),
        );
      }
    } catch (e) {
      emit(ChartError('حدث خطأ غير متوقع أثناء جلب البيانات: $e'));
    }
  }
}