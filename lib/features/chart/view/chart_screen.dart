import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/services/price_alert_service.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/chart/model/gold_bar_model.dart';
import 'package:gold/features/chart/view_model/chart_cubit.dart';
import 'package:gold/features/chart/view_model/chart_state.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/gold_market/view_model/gold_state.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  String _formatMoney(double value, String currency) {
    switch (currency) {
      case 'USD':
        return '\$${value.toStringAsFixed(2)}';
      case 'EGP':
        return 'ج.م ${value.toStringAsFixed(2)}';
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

  String _formatShortDate(DateTime date, bool isAr) {
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
    return '${monthsEn[date.month - 1]} ${date.day}';
  }

  double? _resolveFxRateFromGoldState(GoldState goldState) {
    if (goldState is! GetGoldSuccess) return null;
    if (goldState.selectedCurrency == 'USD') return 1.0;

    // لو GoldPriceModel فيه حقل لسعر الصرف أو الأونصة بالدولار اربطه هنا
    // مثال: لو عندك goldState.fxRateToUsd أو goldState.goldData.usdOuncePrice
    return null;
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

    return BlocProvider(
      create: (ctx) {
        final goldState = ctx.read<GoldCubit>().state;
        final String currency = goldState is GetGoldSuccess
            ? goldState.selectedCurrency
            : 'USD';
        final double? fxRate = _resolveFxRateFromGoldState(goldState);

        return ChartCubit()
          ..loadChart(
            range: ChartRange.month,
            currency: currency,
            fxRateToCurrency: fxRate,
          );
      },
      child: BlocListener<GoldCubit, GoldState>(
        listener: (context, goldState) {
          if (goldState is GetGoldSuccess) {
            final chartCubit = context.read<ChartCubit>();
            final String currency = goldState.selectedCurrency;
            final double? fxRate = _resolveFxRateFromGoldState(goldState);
            chartCubit.loadChart(
              range: chartCubit.currentRange,
              currency: currency,
              fxRateToCurrency: fxRate,
            );
          }
        },
        child: Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: BlocConsumer<ChartCubit, ChartState>(
              listener: (context, state) async {
                if (state is ChartLoaded && state.bars.isNotEmpty) {
                  final triggered =
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
                              ? 'تنبيه: سعر الذهب تجاوز الحد المستهدف!'
                              : 'Alert: Gold price exceeded your target!',
                        ),
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                final ChartCubit cubit = context.read<ChartCubit>();
                final ChartRange activeRange =
                state is ChartLoaded ? state.range : cubit.currentRange;
                final String activeCurrency = state is ChartLoaded
                    ? state.currency
                    : cubit.currentCurrency;

                return RefreshIndicator(
                  color: accentColor,
                  backgroundColor: surfaceColor,
                  onRefresh: () => cubit.loadChart(
                    range: activeRange,
                    currency: cubit.currentCurrency,
                    fxRateToCurrency: cubit.currentFxRate,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      // العنوان الفرعي والشارة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr
                                ? 'تحليل الأداء • XAU / $activeCurrency'
                                : 'ASSET METRIC • XAU / $activeCurrency',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.6,
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
                                  isAr ? 'بيانات تاريخية' : 'Historical',
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
                      const SizedBox(height: 8),

                      // عنوان الشاشة والسعر ونسبة التغير
                      if (state is ChartLoaded) ...[
                        Text(
                          isAr ? 'اتجاه الذهب' : 'Gold Trend',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
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
                              isAr ? '/ أونصة' : '/ t oz',
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
                                ? 'ملاحظة: الأسعار التاريخية محوّلة باستخدام سعر الصرف الحالي (Current FX)'
                                : 'Note: Historical values are converted at the current FX rate.',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          isAr ? 'اتجاه الذهب' : 'Gold Trend',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // أزرار الفترات الزمنية
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _RangeButton(
                              label: '1W',
                              isSelected: activeRange == ChartRange.week,
                              accentColor: accentColor,
                              selectedTextColor: selectedTextColor,
                              unselectedTextColor: secondaryText,
                              onTap: () => cubit.loadChart(
                                range: ChartRange.week,
                                currency: cubit.currentCurrency,
                                fxRateToCurrency: cubit.currentFxRate,
                              ),
                            ),
                            _RangeButton(
                              label: '1M',
                              isSelected: activeRange == ChartRange.month,
                              accentColor: accentColor,
                              selectedTextColor: selectedTextColor,
                              unselectedTextColor: secondaryText,
                              onTap: () => cubit.loadChart(
                                range: ChartRange.month,
                                currency: cubit.currentCurrency,
                                fxRateToCurrency: cubit.currentFxRate,
                              ),
                            ),
                            _RangeButton(
                              label: '3M',
                              isSelected: activeRange == ChartRange.quarter,
                              accentColor: accentColor,
                              selectedTextColor: selectedTextColor,
                              unselectedTextColor: secondaryText,
                              onTap: () => cubit.loadChart(
                                range: ChartRange.quarter,
                                currency: cubit.currentCurrency,
                                fxRateToCurrency: cubit.currentFxRate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // محتوى الشارت حسب الحالة
                      if (state is ChartLoading || state is ChartInitial)
                        Container(
                          height: 270,
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
                                  currency: cubit.currentCurrency,
                                  fxRateToCurrency: cubit.currentFxRate,
                                ),
                                child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (state is ChartLoaded) ...[
                          _GoldLineChartCard(
                            bars: state.bars,
                            currency: state.currency,
                            isAr: isAr,
                            surfaceColor: surfaceColor,
                            elevatedColor: elevatedColor,
                            borderColor: borderColor,
                            accentColor: accentColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            formatMoney: _formatMoney,
                            formatShortDate: (d) => _formatShortDate(d, isAr),
                          ),
                          const SizedBox(height: 16),

                          // ملخص الفترة الحقيقي
                          Row(
                            children: [
                              Expanded(
                                child: _StatSummaryCard(
                                  title: isAr ? 'أعلى سعر' : 'Period High',
                                  value: _formatMoney(
                                    state.periodHigh,
                                    state.currency,
                                  ),
                                  subtitle: isAr ? 'خلال الفترة' : 'In Range',
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatSummaryCard(
                                  title: isAr ? 'أقل سعر' : 'Period Low',
                                  value: _formatMoney(
                                    state.periodLow,
                                    state.currency,
                                  ),
                                  subtitle: isAr ? 'خلال الفترة' : 'In Range',
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                          const SizedBox(height: 16),

                          // كارت تنبيه السعر المستهدف
                          _PriceAlertCard(
                            currentPrice: state.bars.last.close,
                            currency: state.currency,
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

class _RangeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _RangeButton({
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
            borderRadius: BorderRadius.circular(20),
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
  final String currency;
  final bool isAr;
  final Color surfaceColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final String Function(double value, String currency) formatMoney;
  final String Function(DateTime date) formatShortDate;

  const _GoldLineChartCard({
    required this.bars,
    required this.currency,
    required this.isAr,
    required this.surfaceColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.formatMoney,
    required this.formatShortDate,
  });

  @override
  Widget build(BuildContext context) {
    double minY = bars.first.close;
    double maxY = bars.first.close;

    final List<FlSpot> spots = [];
    for (int i = 0; i < bars.length; i++) {
      final double val = bars[i].close;
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    final double rawRange = (maxY - minY).abs();
    final double paddingY = (rawRange * 0.12).clamp(1.0, double.infinity);
    minY -= paddingY;
    maxY += paddingY;

    final double adjustedRange = (maxY - minY).abs();
    final double yInterval = adjustedRange > 0 ? (adjustedRange / 4) : 10.0;
    final int xStep = bars.length > 5 ? ((bars.length - 1) / 4).ceil() : 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
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
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 64,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if ((value - minY).abs() < yInterval * 0.25 ||
                        (maxY - value).abs() < yInterval * 0.25) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        value.toStringAsFixed(0),
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(fontSize: 10, color: secondaryText),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: xStep.toDouble(),
                  getTitlesWidget: (value, meta) {
                    final int idx = value.round();
                    if (idx < 0 || idx >= bars.length) {
                      return const SizedBox.shrink();
                    }

                    final bool isStepped = idx % xStep == 0;
                    final bool isLast = idx == bars.length - 1;
                    if (!isStepped && !isLast) {
                      return const SizedBox.shrink();
                    }

                    if (isLast &&
                        bars.length > 2 &&
                        (bars.length - 1) % xStep != 0) {
                      final int prevShown =
                          ((bars.length - 1) ~/ xStep) * xStep;
                      if ((bars.length - 1 - prevShown) < (xStep * 0.6)) {
                        return const SizedBox.shrink();
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        formatShortDate(bars[idx].date),
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          isLast ? FontWeight.bold : FontWeight.normal,
                          color: isLast ? accentColor : secondaryText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => elevatedColor,
                tooltipBorder: BorderSide(color: borderColor),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final int idx = spot.x.round().clamp(0, bars.length - 1);
                    final bar = bars[idx];
                    return LineTooltipItem(
                      '${formatMoney(bar.close, currency)}\n',
                      TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: formatShortDate(bar.date),
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
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
      text: (widget.currentPrice * 1.02).toStringAsFixed(0),
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
    final parsed = double.tryParse(_controller.text.trim());
    if (enabled && (parsed == null || parsed <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'من فضلك أدخل سعراً مستهدفاً صحيحاً'
                : 'Please enter a valid target price',
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
              ? 'تم تفعيل التنبيه عند تجاوز ${parsed!.toStringAsFixed(2)} ${widget.currency}'
              : 'Alert set above ${parsed!.toStringAsFixed(2)} ${widget.currency}')
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
                      widget.isAr ? 'تنبيه السعر المستهدف' : 'Set Price Alert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryText,
                      ),
                    ),
                    Text(
                      widget.isAr
                          ? 'إشعار عند زيادة السعر عن الحد المحدد'
                          : 'Notify when gold rises above target',
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
                    labelText: widget.isAr ? 'السعر المستهدف' : 'Target Price',
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