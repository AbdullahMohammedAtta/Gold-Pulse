import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/gold_market/view_model/gold_state.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final currencies = [
    {'code': 'EGP', 'label': 'EGP (ج.م)', 'symbol': 'ج.م '},
    {'code': 'USD', 'label': 'USD (\$)', 'symbol': '\$'},
    {'code': 'EUR', 'label': 'EUR (€)', 'symbol': '€'},
    {'code': 'GBP', 'label': 'GBP (£)', 'symbol': '£'},
    {'code': 'AED', 'label': 'AED (د.إ)', 'symbol': 'د.إ '},
  ];

  String _symbolFor(String currency) {
    for (final item in currencies) {
      if (item['code'] == currency) return item['symbol']!;
    }
    return '$currency ';
  }

  String _formatPrice(double value, String currency) {
    return '${_symbolFor(currency)}${value.toStringAsFixed(2)}';
  }

  // حساب سعر الجرام حسب العيار (مع دعم عيار 22K)
  double _rateForKarat(GoldPriceModel gold, String karat) {
    switch (karat) {
      case '24K':
        return gold.priceGram24k;
      case '22K':
      // لو عندك getter جاهز في الموديل باسم priceGram22k استخدمه مباشرة
        return gold.priceGram24k * (22 / 24);
      case '18K':
        return gold.priceGram18k;
      case '21K':
      default:
        return gold.priceGram21k;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

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
    final Color selectedChipText = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: BlocBuilder<GoldCubit, GoldState>(
          builder: (context, state) {
            if (state is GetGoldLoading) {
              return Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }

            if (state is GetGoldError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondaryText),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GoldCubit>().fetchGoldPrices(
                            forceRefresh: true,
                          );
                        },
                        child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is GetGoldSuccess) {
              final GoldPriceModel gold = state.goldData;
              final String selectedCurrency = state.selectedCurrency;

              // لو الموديل فيه high/low حقيقيين استبدل القيمتين دول بحقول الموديل
              final double highPrice = gold.priceOunce * 1.008;
              final double lowPrice = gold.priceOunce * 0.992;

              return RefreshIndicator(
                color: accentColor,
                backgroundColor: surfaceColor,
                onRefresh: () async {
                  await context.read<GoldCubit>().fetchGoldPrices(
                    currency: selectedCurrency,
                    forceRefresh: true,
                  );
                },
                child: ListView(

                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // Header + Refresh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'أسعار الذهب المباشرة' : 'Live Gold Rates',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? 'آخر تحديث: ${_formatTime(gold.lastUpdated)}'
                                  : 'Updated: ${_formatTime(gold.lastUpdated)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: state.isRefreshing
                              ? null
                              : () {
                            context.read<GoldCubit>().fetchGoldPrices(
                              currency: selectedCurrency,
                              forceRefresh: true,
                            );
                          },
                          icon: state.isRefreshing
                              ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          )
                              : Icon(
                            Icons.refresh_rounded,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // شريط العملات الأفقي (EGP افتراضي)
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: currencies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = currencies[index];
                          final String code = item['code']!;
                          final String label = item['label']!;
                          final bool isSelected = selectedCurrency == code;

                          return GestureDetector(
                            onTap: () {
                              context.read<GoldCubit>().changeCurrency(code);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? accentColor : surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? accentColor : borderColor,
                                ),
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? selectedChipText
                                      : secondaryText,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // كارت سعر الأونصة الرئيسي + شريط أعلى وأقل قيمة
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr
                                    ? 'سعر الأونصة (تروي)'
                                    : 'GOLD SPOT (TROY OZ)',
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                  color: secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'XAU / $selectedCurrency',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatPrice(gold.priceOunce, selectedCurrency),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // شريط أعلى وأقل قيمة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: elevatedColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'أعلى قيمة' : 'High',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: secondaryText,
                                            ),
                                          ),
                                          Text(
                                            _formatPrice(
                                              highPrice,
                                              selectedCurrency,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: primaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: borderColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'أقل قيمة' : 'Low',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: secondaryText,
                                            ),
                                          ),
                                          Text(
                                            _formatPrice(
                                              lowPrice,
                                              selectedCurrency,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: primaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // عنوان العيارات
                    Text(
                      isAr ? 'أسعار الجرام حسب العيار' : 'Karat Rates (Per Gram)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _KaratTile(
                      karatLabel: '24K',
                      subtitle: isAr ? 'ذهب نقي (99.9%)' : 'Pure Gold (99.9%)',
                      priceText: _formatPrice(
                        _rateForKarat(gold, '24K'),
                        selectedCurrency,
                      ),
                      perGramText: isAr ? '/ جرام' : '/ gram',
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                    const SizedBox(height: 10),
                    _KaratTile(
                      karatLabel: '22K',
                      subtitle:
                      isAr ? 'عيار 22 (91.6%)' : 'Karat 22 (91.6%)',
                      priceText: _formatPrice(
                        _rateForKarat(gold, '22K'),
                        selectedCurrency,
                      ),
                      perGramText: isAr ? '/ جرام' : '/ gram',
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                    const SizedBox(height: 10),
                    _KaratTile(
                      karatLabel: '21K',
                      subtitle: isAr
                          ? 'الأكثر تداولاً للمشغولات'
                          : 'Most Popular Jewelry',
                      priceText: _formatPrice(
                        _rateForKarat(gold, '21K'),
                        selectedCurrency,
                      ),
                      perGramText: isAr ? '/ جرام' : '/ gram',
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                    const SizedBox(height: 10),
                    _KaratTile(
                      karatLabel: '18K',
                      subtitle: isAr
                          ? 'مشغولات عصرية (75%)'
                          : 'Modern Standard (75%)',
                      priceText: _formatPrice(
                        _rateForKarat(gold, '18K'),
                        selectedCurrency,
                      ),
                      perGramText: isAr ? '/ جرام' : '/ gram',
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                    ),
                    const SizedBox(height: 20),

                    // حاسبة الوزن
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calculate_outlined,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'حاسبة الوزن' : 'Weight Calculator',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAr
                                      ? 'احسب قيمة وزن معين بالجرام'
                                      : 'Estimate value by gram weight',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _openCalculatorSheet(
                              context,
                              gold: gold,
                              currency: selectedCurrency,
                              isAr: isAr,
                              surfaceColor: surfaceColor,
                              elevatedColor: elevatedColor,
                              borderColor: borderColor,
                              accentColor: accentColor,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              selectedChipText: selectedChipText,
                            ),
                            child: Text(
                              isAr ? 'احسب' : 'Convert',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _openCalculatorSheet(
      BuildContext context, {
        required GoldPriceModel gold,
        required String currency,
        required bool isAr,
        required Color surfaceColor,
        required Color elevatedColor,
        required Color borderColor,
        required Color accentColor,
        required Color primaryText,
        required Color secondaryText,
        required Color selectedChipText,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return _GoldCalculatorSheet(
          gold: gold,
          currency: currency,
          isAr: isAr,
          elevatedColor: elevatedColor,
          borderColor: borderColor,
          accentColor: accentColor,
          primaryText: primaryText,
          secondaryText: secondaryText,
          selectedChipText: selectedChipText,
          rateForKarat: (karat) => _rateForKarat(gold, karat),
          formatPrice: (value) => _formatPrice(value, currency),
        );
      },
    );
  }
}

class _KaratTile extends StatelessWidget {
  final String karatLabel;
  final String subtitle;
  final String priceText;
  final String perGramText;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;

  const _KaratTile({
    required this.karatLabel,
    required this.subtitle,
    required this.priceText,
    required this.perGramText,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              karatLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: secondaryText),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              Text(
                perGramText,
                style: TextStyle(fontSize: 11, color: secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _GoldCalculatorSheet extends StatefulWidget {
  final GoldPriceModel gold;
  final String currency;
  final bool isAr;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final Color selectedChipText;
  final double Function(String karat) rateForKarat;
  final String Function(double value) formatPrice;

  const _GoldCalculatorSheet({
    required this.gold,
    required this.currency,
    required this.isAr,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.selectedChipText,
    required this.rateForKarat,
    required this.formatPrice,
  });

  @override
  State<_GoldCalculatorSheet> createState() => _GoldCalculatorSheetState();
}

class _GoldCalculatorSheetState extends State<_GoldCalculatorSheet> {
  late final TextEditingController _gramsController;
  String _selectedKarat = '21K';

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double grams = double.tryParse(_gramsController.text) ?? 0.0;
    final double ratePerGram = widget.rateForKarat(_selectedKarat);
    final double total = grams * ratePerGram;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isAr ? 'حاسبة قيمة الذهب' : 'Gold Value Calculator',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: widget.primaryText),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: widget.isAr ? 'الوزن بالجرام' : 'Weight (grams)',
              labelStyle: TextStyle(color: widget.secondaryText),
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
          const SizedBox(height: 12),
          Row(
            children: ['24K', '22K', '21K', '18K'].map((karat) {
              final bool active = _selectedKarat == karat;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(karat),
                    selected: active,
                    selectedColor: widget.accentColor,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: active ? widget.selectedChipText : widget.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: widget.elevatedColor,
                    side: BorderSide(
                      color: active ? widget.accentColor : widget.borderColor,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedKarat = karat);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.elevatedColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isAr ? 'الإجمالي المتوقع' : 'Estimated Total',
                  style: TextStyle(color: widget.secondaryText),
                ),
                Text(
                  widget.formatPrice(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}