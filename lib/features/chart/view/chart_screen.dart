import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/price_alert_service.dart';
import 'package:gold/core/storage/currency_storage.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';
import 'package:gold/features/chart/view_model/chart_cubit.dart';
import 'package:gold/features/chart/view_model/chart_state.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/gold_market/view_model/gold_state.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final CurrencyStorage _currencyStorage = CurrencyStorage();
  String _persistedCurrency = 'EGP';
  double? _persistedFxRate;

  @override
  void initState() {
    super.initState();
    _loadPersistedCurrency();
  }

  Future<void> _loadPersistedCurrency() async {
    final String savedCurrency =
    await _currencyStorage.loadCurrency(fallback: 'EGP');
    final double? savedFx = await _currencyStorage.loadFxRate();
    if (!mounted) return;
    setState(() {
      _persistedCurrency = savedCurrency.toUpperCase();
      _persistedFxRate = savedFx;
    });
  }

  String _resolveActiveCurrency(GoldState goldState) {
    if (goldState is GetGoldSuccess && goldState.selectedCurrency.isNotEmpty) {
      return goldState.selectedCurrency.toUpperCase();
    }
    return _persistedCurrency.toUpperCase();
  }

  double _resolveFxRate(GoldState goldState, String activeCurrency) {
    final String code = activeCurrency.toUpperCase();
    if (code == 'USD') return 1.0;

    if (goldState is GetGoldSuccess) {
      // اربط هنا معامل التحويل المباشر لو متاح في GoldState / goldData
    }

    if (_persistedFxRate != null &&
        _persistedFxRate! > 0 &&
        code == _persistedCurrency.toUpperCase()) {
      return _persistedFxRate!;
    }

    return _currencyStorage.fallbackFxRateFor(code);
  }

  String _formatMoney(double value, String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$${value.toStringAsFixed(2)}';
      case 'EGP':
        return 'ج.م ${value.toStringAsFixed(2)}';
      case 'SAR':
        return 'ر.س ${value.toStringAsFixed(2)}';
      case 'EUR':
        return '€${value.toStringAsFixed(2)}';
      case 'GBP':
        return '£${value.toStringAsFixed(2)}';
      case 'AED':
        return 'د.إ ${value.toStringAsFixed(2)}';
      default:
        return '$currency ${value.toStringAsFixed(2)}';
    }
  }

  String _formatAxisDate(DateTime date, bool isAr) {
    const List<String> monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (isAr) {
      return '${date.day}/${date.month}';
    }
    final String dayStr = date.day.toString().padLeft(2, '0');
    return '${monthsEn[date.month - 1]} $dayStr';
  }

  String _karatUnitLabel(int karat, bool isAr) {
    if (isAr) {
      return '/ جرام عيار $karat';
    }
    return '/ g (${karat}K)';
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
    isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color surfaceColor =
    isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color elevatedColor =
    isDark ? AppColors.darkElevated : AppColors.lightElevated;
    final Color primaryText =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color secondaryText =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color borderColor =
    isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final Color accentColor = isDark ? AppColors.goldDark : AppColors.goldLight;
    final Color selectedTextColor = isDark ? Colors.black : Colors.white;

    final GoldState initialGoldState = context.read<GoldCubit>().state;
    final String initialCurrency = _resolveActiveCurrency(initialGoldState);
    final double initialFxRate =
    _resolveFxRate(initialGoldState, initialCurrency);

    return BlocProvider(
      create: (_) => ChartCubit()
        ..loadChart(
          range: ChartRange.month,
          karat: 21,
          currency: initialCurrency,
          fxRateToCurrency: initialFxRate,
        ),
      child: BlocListener<GoldCubit, GoldState>(
        listener: (context, goldState) async {
          final String selected = _resolveActiveCurrency(goldState);
          final double fxRate = _resolveFxRate(goldState, selected);
          await _currencyStorage.saveCurrency(selected, fxRate: fxRate);
          if (!context.mounted) return;
          setState(() {
            _persistedCurrency = selected;
            _persistedFxRate = fxRate;
          });

          final ChartCubit chartCubit = context.read<ChartCubit>();
          chartCubit.loadChart(
            range: chartCubit.currentRange,
            karat: chartCubit.currentKarat,
            currency: selected,
            fxRateToCurrency: fxRate,
          );
        },
        child: Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: BlocConsumer<ChartCubit, ChartState>(
              listener: (context, state) async {
                if (state is ChartLoaded && state.bars.isNotEmpty) {
                  final bool triggered =
                  await PriceAlertService().checkAndNotifyIfExceeded(
                    currentPrice: state.bars.last.close,
                    currency: state.currency,
                    isAr: isAr,
                  );
                  if (triggered && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr
                              ? 'تنبيه: سعر الجرام تجاوز الحد المستهدف!'
                              : 'Alert: Gold gram price exceeded your target!',
                        ),
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                final ChartCubit cubit = context.read<ChartCubit>();
                final GoldState goldState = context.watch<GoldCubit>().state;
                final String preferredCurrency =
                _resolveActiveCurrency(goldState);
                final double fxRate =
                _resolveFxRate(goldState, preferredCurrency);

                final ChartRange activeRange =
                state is ChartLoaded ? state.range : cubit.currentRange;
                final int activeKarat = cubit.currentKarat;
                final String displayCurrency = state is ChartLoaded
                    ? state.currency
                    : preferredCurrency;

                return RefreshIndicator(
                  color: accentColor,
                  backgroundColor: surfaceColor,
                  onRefresh: () => cubit.loadChart(
                    range: activeRange,
                    karat: activeKarat,
                    currency: preferredCurrency,
                    fxRateToCurrency: fxRate,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                    children: [
                      // العنوان الفرعي والشارة
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr
                                  ? 'تحليل الجرام • عيار $activeKarat / $displayCurrency'
                                  : 'GRAM METRIC • ${activeKarat}K / $displayCurrency',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                                color: secondaryText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: elevatedColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 3.5,
                                    backgroundColor: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr ? 'سعر الجرام' : 'Gram Chart',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // عنوان الشاشة والسعر ونسبة التغير
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'مؤشر سعر جرام الذهب'
                                  : 'Gold Gram Trend',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                            if (state is ChartLoaded) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _formatMoney(
                                      state.bars.last.close,
                                      state.currency,
                                    ),
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _karatUnitLabel(activeKarat, isAr),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _TrendChangeRow(
                                changePercent: state.changePercent,
                                firstClose: state.bars.first.close,
                                lastClose: state.bars.last.close,
                                currency: state.currency,
                                isAr: isAr,
                                secondaryText: secondaryText,
                                formatMoney: _formatMoney,
                              ),
                              if (state.isConvertedByCurrentFx) ...[
                                const SizedBox(height: 4),
                                Text(
                                  isAr
                                      ? 'ملاحظة: الأسعار محوّلة إلى الجرام حسب العيار وسعر الصرف الحالي'
                                      : 'Note: Gram prices reflect selected karat and current FX rate.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // أزرار الفترات الزمنية بعرض كامل
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _SegmentButton(
                              label: '1W',
                              isSelected: activeRange == ChartRange.week,
                              accentColor: accentColor,
                              selectedTextColor: selectedTextColor,
                              unselectedTextColor: secondaryText,
                              onTap: () => cubit.loadChart(
                                range: ChartRange.week,
                                karat: activeKarat,
                                currency: preferredCurrency,
                                fxRateToCurrency: fxRate,
                              ),
                            ),
                            _SegmentButton(
                              label: '1M',
                              isSelected: activeRange == ChartRange.month,
                              accentColor: accentColor,
                              selectedTextColor: selectedTextColor,
                              unselectedTextColor: secondaryText,
                              onTap: () => cubit.loadChart(
                                range: ChartRange.month,
                                karat: activeKarat,
                                currency: preferredCurrency,
                                fxRateToCurrency: fxRate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // شريط اختيار العيارات (24, 21, 18) بعرض كامل
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            for (final int k in [24, 21, 18])
                              _SegmentButton(
                                label: isAr ? 'عيار $k' : '${k}K',
                                isSelected: activeKarat == k,
                                accentColor: accentColor,
                                selectedTextColor: selectedTextColor,
                                unselectedTextColor: secondaryText,
                                onTap: () => cubit.loadChart(
                                  range: activeRange,
                                  karat: k,
                                  currency: preferredCurrency,
                                  fxRateToCurrency: fxRate,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // محتوى الشارت حسب الحالة (بعرض كامل)
                      if (state is ChartLoading || state is ChartInitial)
                        Container(
                          width: double.infinity,
                          height: 265,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: CircularProgressIndicator(color: accentColor),
                        )
                      else if (state is ChartError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.show_chart_rounded,
                                size: 36,
                                color: accentColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: secondaryText),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => cubit.loadChart(
                                  range: activeRange,
                                  karat: activeKarat,
                                  currency: preferredCurrency,
                                  fxRateToCurrency: fxRate,
                                ),
                                child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (state is ChartLoaded) ...[
                          _GoldLineChartCard(
                            bars: state.bars,
                            range: state.range,
                            karat: activeKarat,
                            currency: state.currency,
                            isAr: isAr,
                            surfaceColor: surfaceColor,
                            elevatedColor: elevatedColor,
                            borderColor: borderColor,
                            accentColor: accentColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            formatMoney: _formatMoney,
                            formatAxisDate: (d) => _formatAxisDate(d, isAr),
                          ),
                          const SizedBox(height: 14),

                          // ملخص الفترة الحقيقي للجرام
                          Row(
                            children: [
                              Expanded(
                                child: _StatSummaryCard(
                                  title: isAr ? 'أعلى جرام' : 'Gram High',
                                  value: _formatMoney(
                                    state.periodHigh,
                                    state.currency,
                                  ),
                                  subtitle: isAr
                                      ? 'عيار $activeKarat'
                                      : '${activeKarat}K In Range',
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatSummaryCard(
                                  title: isAr ? 'أقل جرام' : 'Gram Low',
                                  value: _formatMoney(
                                    state.periodLow,
                                    state.currency,
                                  ),
                                  subtitle: isAr
                                      ? 'عيار $activeKarat'
                                      : '${activeKarat}K In Range',
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StatSummaryCard(
                                  title: isAr ? 'القراءات' : 'Data Bars',
                                  value: '${state.bars.length}',
                                  subtitle: isAr ? 'نقطة فعلية' : 'Actual Bars',
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // كارت تنبيه السعر المستهدف للجرام
                          _PriceAlertCard(
                            currentPrice: state.bars.last.close,
                            currency: state.currency,
                            karat: activeKarat,
                            isAr: isAr,
                            surfaceColor: surfaceColor,
                            elevatedColor: elevatedColor,
                            borderColor: borderColor,
                            accentColor: accentColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            selectedTextColor: selectedTextColor,
                          ),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChangeRow extends StatelessWidget {
  final double changePercent;
  final double firstClose;
  final double lastClose;
  final String currency;
  final bool isAr;
  final Color secondaryText;
  final String Function(double value, String currency) formatMoney;

  const _TrendChangeRow({
    required this.changePercent,
    required this.firstClose,
    required this.lastClose,
    required this.currency,
    required this.isAr,
    required this.secondaryText,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final double diff = lastClose - firstClose;
    final bool isUp = diff >= 0;
    final Color color = isUp ? Colors.green : Colors.redAccent;
    final String sign = isUp ? '+' : '';

    return Row(
      children: [
        Icon(
          isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          '$sign${formatMoney(diff.abs(), currency)} ($sign${changePercent.toStringAsFixed(2)}%)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isAr ? 'خلال الفترة المحددة' : 'for selected period',
          style: TextStyle(
            fontSize: 12,
            color: secondaryText,
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? selectedTextColor : unselectedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldLineChartCard extends StatelessWidget {
  final List<GoldBarModel> bars;
  final ChartRange range;
  final int karat;
  final String currency;
  final bool isAr;
  final Color surfaceColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final String Function(double value, String currency) formatMoney;
  final String Function(DateTime date) formatAxisDate;

  const _GoldLineChartCard({
    required this.bars,
    required this.range,
    required this.karat,
    required this.currency,
    required this.isAr,
    required this.surfaceColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.formatMoney,
    required this.formatAxisDate,
  });

  int _totalDaysForRange(ChartRange r) {
    switch (r) {
      case ChartRange.week:
        return 7;
      case ChartRange.month:
        return 30;
      case ChartRange.quarter:
        return 90;
    }
  }

  bool _hasDistinctDates(List<GoldBarModel> items) {
    if (items.length < 2) return false;
    final Set<String> days = {};
    for (final b in items) {
      days.add('${b.date.year}-${b.date.month}-${b.date.day}');
    }
    return days.length >= 2;
  }

  DateTime _effectiveDateForIndex(int index, DateTime now) {
    if (_hasDistinctDates(bars)) {
      return bars[index].date;
    }
    final int count = bars.length;
    if (count <= 1) return now;
    final int totalDays = _totalDaysForRange(range);
    final DateTime startDate = now.subtract(Duration(days: totalDays));
    final double ratio = index / (count - 1);
    final int offsetDays = (ratio * totalDays).round();
    return startDate.add(Duration(days: offsetDays));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _spotXToBarIndex(double spotX) {
    final int count = bars.length;
    if (count <= 1) return 0;
    final int visualIdx = spotX.round().clamp(0, count - 1);
    if (isAr) {
      return (count - 1) - visualIdx;
    }
    return visualIdx;
  }

  List<String> _buildFooterLabels(DateTime now) {
    if (bars.isEmpty) {
      return [
        isAr ? 'البداية' : 'Start',
        isAr ? 'المنتصف' : 'Mid',
        isAr ? 'الأخير' : 'Recent',
        isAr ? 'اليوم' : 'Today',
      ];
    }

    final int lastIdx = bars.length - 1;
    final List<int> indices = [
      0,
      (lastIdx / 3).round().clamp(0, lastIdx),
      ((lastIdx * 2) / 3).round().clamp(0, lastIdx),
      lastIdx,
    ];

    final List<String> labels = [];
    for (int i = 0; i < indices.length; i++) {
      final int idx = indices[i];
      final DateTime d = _effectiveDateForIndex(idx, now);
      if (i == indices.length - 1 && _isSameDay(d, now)) {
        labels.add(isAr ? 'اليوم' : 'Today');
      } else {
        labels.add(formatAxisDate(d));
      }
    }
    return labels;
  }

  String _formatYAxisPrice(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    }
    if (value >= 100) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  Alignment _alignmentForIndex(int index, int total) {
    if (index == 0) return Alignment.centerLeft;
    if (index == total - 1) return Alignment.centerRight;
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    double minY = bars.first.close;
    double maxY = bars.first.close;

    final List<FlSpot> spots = [];
    for (int i = 0; i < bars.length; i++) {
      final int barIdx = isAr ? (bars.length - 1 - i) : i;
      final double val = bars[barIdx].close;
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    final double rawRange = (maxY - minY).abs();
    final double paddingY = (rawRange * 0.12).clamp(0.5, double.infinity);
    minY -= paddingY;
    maxY += paddingY;

    final double adjustedRange = (maxY - minY).abs();
    final double yInterval = adjustedRange > 0 ? (adjustedRange / 4) : 5.0;
    final List<String> footerLabels = _buildFooterLabels(now);
    const double rightAxisReservedSize = 64;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (bars.length - 1).toDouble().clamp(0, double.infinity),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: borderColor.withOpacity(0.6),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: rightAxisReservedSize,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if ((value - minY).abs() < yInterval * 0.25 ||
                            (maxY - value).abs() < yInterval * 0.25) {
                          return const SizedBox.shrink();
                        }
                        return Center(
                          child: Text(
                            _formatYAxisPrice(value),
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontSize: 10, color: secondaryText),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => elevatedColor,
                    tooltipBorder: BorderSide(color: borderColor),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final int barIdx = _spotXToBarIndex(spot.x);
                        final GoldBarModel bar = bars[barIdx];
                        final DateTime pointDate =
                        _effectiveDateForIndex(barIdx, now);
                        final String dateLabel = _isSameDay(pointDate, now)
                            ? (isAr ? 'اليوم' : 'Today')
                            : formatAxisDate(pointDate);

                        return LineTooltipItem(
                          '${formatMoney(bar.close, currency)}\n',
                          TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: isAr
                                  ? 'عيار $karat • $dateLabel'
                                  : '${karat}K • $dateLabel',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: accentColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withOpacity(0.28),
                          accentColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final List<String> displayLabels =
              isAr ? footerLabels.reversed.toList() : footerLabels;
              final int todayIndex = isAr ? 0 : displayLabels.length - 1;

              return Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.only(right: rightAxisReservedSize),
                  child: Row(
                    children: [
                      for (int i = 0; i < displayLabels.length; i++)
                        Expanded(
                          child: Align(
                            alignment:
                            _alignmentForIndex(i, displayLabels.length),
                            child: Text(
                              displayLabels[i],
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == todayIndex
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: i == todayIndex
                                    ? accentColor
                                    : secondaryText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;

  const _StatSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: secondaryText),
          ),
        ],
      ),
    );
  }
}

class _PriceAlertCard extends StatefulWidget {
  final double currentPrice;
  final String currency;
  final int karat;
  final bool isAr;
  final Color surfaceColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final Color selectedTextColor;

  const _PriceAlertCard({
    required this.currentPrice,
    required this.currency,
    required this.karat,
    required this.isAr,
    required this.surfaceColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.selectedTextColor,
  });

  @override
  State<_PriceAlertCard> createState() => _PriceAlertCardState();
}

class _PriceAlertCardState extends State<_PriceAlertCard> {
  final PriceAlertService _alertService = PriceAlertService();
  late final TextEditingController _controller;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentPrice * 1.02).toStringAsFixed(2),
    );
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final PriceAlertSettings saved = await _alertService.loadAlertSettings();
    if (!mounted) return;
    setState(() {
      _enabled = saved.enabled;
      if (saved.targetPrice != null && saved.targetPrice! > 0) {
        _controller.text = saved.targetPrice!.toStringAsFixed(2);
      }
      _loading = false;
    });
  }

  Future<void> _save({required bool enabled}) async {
    final double? parsed = double.tryParse(_controller.text.trim());
    if (enabled && (parsed == null || parsed <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'من فضلك أدخل سعراً مستهدفاً صحيحاً للجرام'
                : 'Please enter a valid gram target price',
          ),
        ),
      );
      return;
    }

    await _alertService.saveAlertSettings(
      enabled: enabled,
      targetPrice: parsed,
    );

    if (!mounted) return;
    setState(() => _enabled = enabled);

    if (enabled && parsed != null && widget.currentPrice > parsed) {
      await _alertService.checkAndNotifyIfExceeded(
        currentPrice: widget.currentPrice,
        currency: widget.currency,
        isAr: widget.isAr,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? (widget.isAr
              ? 'تم تفعيل التنبيه عند تجاوز ${parsed!.toStringAsFixed(2)} ${widget.currency} للجرام'
              : 'Alert set above ${parsed!.toStringAsFixed(2)} ${widget.currency} per gram')
              : (widget.isAr ? 'تم إيقاف التنبيه' : 'Price alert disabled'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _enabled ? widget.accentColor : widget.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: widget.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAr
                          ? 'تنبيه سعر الجرام (عيار ${widget.karat})'
                          : 'Set Gram Alert (${widget.karat}K)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryText,
                      ),
                    ),
                    Text(
                      widget.isAr
                          ? 'إشعار عند زيادة سعر الجرام عن الحد المحدد'
                          : 'Notify when gram price rises above target',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                activeColor: widget.accentColor,
                onChanged: (val) => _save(enabled: val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: widget.primaryText, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '${widget.currency} ',
                    labelText: widget.isAr
                        ? 'سعر الجرام المستهدف'
                        : 'Target Gram Price',
                    labelStyle:
                    TextStyle(color: widget.secondaryText, fontSize: 12),
                    filled: true,
                    fillColor: widget.elevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: widget.selectedTextColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _save(enabled: true),
                child: Text(
                  widget.isAr ? 'حفظ' : 'Save',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}