import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/chart_service.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';
import 'package:gold/features/chart/view_model/chart_state.dart';

class ChartCubit extends Cubit<ChartState> {
  static const double _gramsPerTroyOunce = 31.1034768;
  static List<GoldBarModel> _sessionSortedBars = const [];

  final ChartService _service;

  ChartRange _currentRange = ChartRange.month;
  int _currentKarat = 21;
  String _currentCurrency = 'EGP';
  double? _currentFxRate;
  double? _liveGramPriceFromHome;

  ChartCubit({ChartService? service})
      : _service = service ?? ChartService(),
        super(ChartInitial()) {
    if (_sessionSortedBars.isNotEmpty) {
      _emitForCurrentRange();
    }
  }

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
        return 1.0;
      case 18:
        return 18.0 / 24.0;
      case 21:
      default:
        return 21.0 / 24.0;
    }
  }

  List<GoldBarModel> _sortAscending(List<GoldBarModel> items) {
    final sorted = List<GoldBarModel>.from(items)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  List<GoldBarModel> _sliceForRange(
      List<GoldBarModel> sortedBars,
      ChartRange range,
      ) {
    if (sortedBars.isEmpty || sortedBars.length <= 2) return sortedBars;
    final int count = _daysForRange(range).clamp(2, sortedBars.length);
    return sortedBars.sublist(sortedBars.length - count);
  }

  void _emitForCurrentRange() {
    if (_sessionSortedBars.isEmpty) return;
    final rangeBars = _sliceForRange(_sessionSortedBars, _currentRange);
    if (rangeBars.isEmpty) {
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

    double gramMultiplier =
        (fxMultiplier / _gramsPerTroyOunce) * _karatFactor(_currentKarat);

    if (_liveGramPriceFromHome != null &&
        _liveGramPriceFromHome! > 0 &&
        rangeBars.last.close > 0) {
      gramMultiplier = _liveGramPriceFromHome! / rangeBars.last.close;
    }

    final List<GoldBarModel> converted = [];
    for (int i = 0; i < rangeBars.length; i++) {
      final bar = rangeBars[i];
      final bool isLast = i == rangeBars.length - 1;
      final double closeVal = (isLast &&
          _liveGramPriceFromHome != null &&
          _liveGramPriceFromHome! > 0)
          ? _liveGramPriceFromHome!
          : bar.close * gramMultiplier;

      converted.add(
        GoldBarModel(
          date: bar.date,
          open: bar.open * gramMultiplier,
          high: bar.high * gramMultiplier,
          low: bar.low * gramMultiplier,
          close: closeVal,
        ),
      );
    }

    double high = converted.first.close;
    double low = converted.first.close;
    for (final bar in converted) {
      if (bar.close > high) high = bar.close;
      if (bar.high > high) high = bar.high;
      if (bar.close < low) low = bar.close;
      if (bar.low < low) low = bar.low;
    }

    final double firstClose = converted.first.close;
    final double lastClose = converted.last.close;
    final double changePercent =
    firstClose > 0 ? ((lastClose - firstClose) / firstClose) * 100 : 0.0;

    emit(
      ChartLoaded(
        bars: converted,
        range: _currentRange,
        currency: effectiveCurrency,
        periodHigh: high,
        periodLow: low,
        changePercent: changePercent,
        isConvertedByCurrentFx: hasValidFx || _liveGramPriceFromHome != null,
      ),
    );
  }

  Future<void> loadChart({
    ChartRange? range,
    int? karat,
    String? currency,
    double? fxRateToCurrency,
    double? liveGramPriceFromHome,
    bool forceRefresh = false,
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
    if (liveGramPriceFromHome != null && liveGramPriceFromHome > 0) {
      _liveGramPriceFromHome = liveGramPriceFromHome;
    }

    final int requestedDays = _daysForRange(_currentRange);
    final bool hasSufficientCache = !forceRefresh &&
        _sessionSortedBars.isNotEmpty &&
        (_sessionSortedBars.length >= requestedDays || requestedDays <= 30);

    if (hasSufficientCache) {
      _emitForCurrentRange();
      return;
    }

    if (state is! ChartLoaded || forceRefresh) {
      emit(ChartLoading());
    }

    try {
      final int fetchDays = requestedDays > 30 ? requestedDays : 30;
      final DateTime to = DateTime.now();
      final DateTime from = to.subtract(Duration(days: fetchDays));

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

      _sessionSortedBars = _sortAscending(rawBars);
      _emitForCurrentRange();
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      emit(
        ChartError(
          (status == 401 || status == 403)
              ? 'نقطة /v1/bars تتطلب صلاحية أو مفتاح API مناسب في خطتك الحالية'
              : (e.message ?? 'تعذر تحميل بيانات الرسم البياني، حاول مرة أخرى'),
        ),
      );
    } catch (e) {
      emit(ChartError('حدث خطأ غير متوقع أثناء جلب البيانات: $e'));
    }
  }
}