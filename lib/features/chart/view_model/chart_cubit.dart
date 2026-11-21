import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/chart_service.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';
import 'package:gold/features/chart/view_model/chart_state.dart';

class ChartCubit extends Cubit<ChartState> {
  static const double _gramsPerTroyOunce = 31.1034768;

  final ChartService _service;

  ChartRange _currentRange = ChartRange.month;
  int _currentKarat = 21;
  String _currentCurrency = 'EGP';
  double? _currentFxRate;

  ChartCubit({ChartService? service})
      : _service = service ?? ChartService(),
        super(ChartInitial());

  ChartRange get currentRange => _currentRange;
  int get currentKarat => _currentKarat;
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

  double _karatFactor(int karat) {
    switch (karat) {
      case 24:
        return 24.0 / 24.0;
      case 18:
        return 18.0 / 24.0;
      case 21:
      default:
        return 21.0 / 24.0;
    }
  }

  Future<void> loadChart({
    ChartRange? range,
    int? karat,
    String? currency,
    double? fxRateToCurrency,
  }) async {
    if (range != null) _currentRange = range;
    if (karat != null && (karat == 24 || karat == 21 || karat == 18)) {
      _currentKarat = karat;
    }
    if (currency != null && currency.trim().isNotEmpty) {
      _currentCurrency = currency.trim().toUpperCase();
    }
    if (_currentCurrency == 'USD') {
      _currentFxRate = 1.0;
    } else if (fxRateToCurrency != null && fxRateToCurrency > 0) {
      _currentFxRate = fxRateToCurrency;
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

      final bool isUsd = _currentCurrency == 'USD';
      final bool hasValidFx =
          !isUsd && _currentFxRate != null && _currentFxRate! > 0;
      final double fxMultiplier =
      isUsd ? 1.0 : (hasValidFx ? _currentFxRate! : 1.0);
      final String effectiveCurrency =
      (isUsd || hasValidFx) ? _currentCurrency : 'USD';

      // تحويل من سعر الأونصة إلى سعر الجرام للعيار المختار
      final double gramMultiplier =
          (fxMultiplier / _gramsPerTroyOunce) * _karatFactor(_currentKarat);

      final List<GoldBarModel> convertedBars = [];
      for (final bar in rawBars) {
        convertedBars.add(
          GoldBarModel(
            date: bar.date,
            open: bar.open * gramMultiplier,
            high: bar.high * gramMultiplier,
            low: bar.low * gramMultiplier,
            close: bar.close * gramMultiplier,
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
          isConvertedByCurrentFx: hasValidFx,
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