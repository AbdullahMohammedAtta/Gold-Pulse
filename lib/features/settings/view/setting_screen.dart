import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/storage/currency_storage.dart';
import 'package:gold/core/storage/portfolio_storage.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/gold_market/view_model/gold_state.dart';
import 'package:gold/features/settings/view_model/settings_cubit.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _currencies = [
  {'code': 'EGP', 'labelAr': 'ج.م (EGP)', 'labelEn': 'EGP (ج.م)'},
  {'code': 'USD', 'labelAr': 'دولار (USD)', 'labelEn': 'USD (\$)'},
  {'code': 'EUR', 'labelAr': 'يورو (EUR)', 'labelEn': 'EUR (€)'},
  {'code': 'GBP', 'labelAr': 'إسترليني (GBP)', 'labelEn': 'GBP (£)'},
  {'code': 'AED', 'labelAr': 'درهم (AED)', 'labelEn': 'AED (د.إ)'},
  {'code': 'SAR', 'labelAr': 'ريال (SAR)', 'labelEn': 'SAR (ر.س)'},
  ];

  final CurrencyStorage _currencyStorage = CurrencyStorage();
  final PortfolioStorage _portfolioStorage = PortfolioStorage();

  String _selectedCurrency = 'EGP';
  bool _loadingCurrency = true;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final saved = await _currencyStorage.loadCurrency(fallback: 'EGP');
    if (!mounted) return;
    setState(() {
      _selectedCurrency = saved.toUpperCase();
      _loadingCurrency = false;
    });
  }

  Future<void> _selectCurrency(BuildContext context, String code) async {
    final normalized = code.toUpperCase();
    final fx = _currencyStorage.fallbackFxRateFor(normalized);
    await _currencyStorage.saveCurrency(normalized, fxRate: fx);
    if (!mounted) return;
    setState(() => _selectedCurrency = normalized);

    final goldCubit = context.read<GoldCubit>();
    try {
      await goldCubit.changeCurrency(normalized);
    } catch (_) {
      await goldCubit.fetchGoldPrices(currency: normalized);
    }

    if (!context.mounted) return;
    final bool isAr = context.read<SettingsCubit>().state.isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم تغيير العملة الافتراضية إلى $normalized'
              : 'Default currency set to $normalized',
        ),
      ),
    );
  }

  Future<void> _exportPortfolioSummary(
      BuildContext context, {
        required bool isAr,
        required Color surfaceColor,
        required Color elevatedColor,
        required Color borderColor,
        required Color accentColor,
        required Color primaryText,
        required Color secondaryText,
        required Color selectedTextColor,
      }) async {
    final items = await _portfolioStorage.loadHoldings();
    if (!context.mounted) return;

    double totalGrams = 0;
    double totalCost = 0;
    final buffer = StringBuffer();

    if (isAr) {
      buffer.writeln('ملخص المحفظة الذهبية ($_selectedCurrency)');
      buffer.writeln('------------------------------');
    } else {
      buffer.writeln('Gold Portfolio Summary ($_selectedCurrency)');
      buffer.writeln('------------------------------');
    }

    if (items.isEmpty) {
      buffer.writeln(
        isAr
            ? 'لا توجد قطع مسجلة في المحفظة حالياً.'
            : 'No gold holdings recorded yet.',
      );
    } else {
      for (final item in items) {
        totalGrams += item.grams;
        totalCost += item.totalCost;
        if (isAr) {
          buffer.writeln(
            '• ${item.name} | عيار ${item.karat}K | ${item.grams.toStringAsFixed(1)} جرام | تكلفة: ${item.totalCost.toStringAsFixed(2)} $_selectedCurrency',
          );
        } else {
          buffer.writeln(
            '• ${item.name} | ${item.karat}K | ${item.grams.toStringAsFixed(1)} g | Cost: ${item.totalCost.toStringAsFixed(2)} $_selectedCurrency',
          );
        }
      }
      buffer.writeln('------------------------------');
      if (isAr) {
        buffer.writeln('إجمالي الوزن: ${totalGrams.toStringAsFixed(1)} جرام');
        buffer.writeln(
          'إجمالي تكلفة الشراء: ${totalCost.toStringAsFixed(2)} $_selectedCurrency',
        );
      } else {
        buffer.writeln('Total Weight: ${totalGrams.toStringAsFixed(1)} g');
        buffer.writeln(
          'Total Buy Cost: ${totalCost.toStringAsFixed(2)} $_selectedCurrency',
        );
      }
    }

    final reportText = buffer.toString().trim();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'تصدير ملخص المحفظة' : 'Export Portfolio Summary',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),
                  Icon(Icons.file_download_outlined, color: accentColor),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    reportText,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: primaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: selectedTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: reportText));
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم نسخ ملخص المحفظة إلى الحافظة'
                            : 'Portfolio summary copied to clipboard',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(
                  isAr ? 'نسخ الملخص' : 'Copy Summary',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final bool isAr = settings.isArabic;
    final bool isDark = settings.isDark;

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

    return BlocListener<GoldCubit, GoldState>(
      listener: (context, goldState) {
        if (goldState is GetGoldSuccess &&
            goldState.selectedCurrency.isNotEmpty) {
          final code = goldState.selectedCurrency.toUpperCase();
          if (code != _selectedCurrency && mounted) {
            setState(() => _selectedCurrency = code);
          }
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // العنوان الرئيسي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الإعدادات' : 'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'تفضيلات العرض والعملة والمحفظة'
                            : 'Preferences & display options',
                        style: TextStyle(fontSize: 12, color: secondaryText),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      isAr ? 'مزامنة فورية' : 'Instant Sync',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. إعداد اللغة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: accentColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'لغة التطبيق' : 'App Language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionTile(
                            title: 'العربية',
                            subtitle: 'Arabic',
                            isSelected: isAr,
                            accent: accentColor,
                            surfaceColor: elevatedColor,
                            borderColor: borderColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            customBadge: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAr
                                    ? accentColor.withOpacity(0.16)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAr ? accentColor : borderColor,
                                ),
                              ),
                              child: Text(
                                'ع',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isAr ? accentColor : primaryText,
                                ),
                              ),
                            ),
                            onTap: () =>
                                context.read<SettingsCubit>().changeLanguage('ar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OptionTile(
                            title: 'English',
                            subtitle: 'الإنجليزية',
                            icon: Icons.abc,
                            isSelected: !isAr,
                            accent: accentColor,
                            surfaceColor: elevatedColor,
                            borderColor: borderColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onTap: () =>
                                context.read<SettingsCubit>().changeLanguage('en'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. العملة الافتراضية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.currency_exchange_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isAr ? 'العملة الافتراضية' : 'Default Currency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedCurrency,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'تُستخدم في الأسعار المباشرة والرسوم البيانية والمحفظة'
                          : 'Applied to live rates, chart, and portfolio',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingCurrency)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(color: accentColor),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currencies.map((item) {
                          final code = item['code']!;
                          final label = isAr ? item['labelAr']! : item['labelEn']!;
                          final bool active = _selectedCurrency == code;

                          return ChoiceChip(
                            label: Text(label),
                            selected: active,
                            selectedColor: accentColor,
                            backgroundColor: elevatedColor,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: active ? selectedTextColor : primaryText,
                            ),
                            side: BorderSide(
                              color: active ? accentColor : borderColor,
                            ),
                            onSelected: (_) => _selectCurrency(context, code),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. إعداد المظهر (Dark / Light)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'مظهر التطبيق' : 'App Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionTile(
                            title: isAr ? 'ليلي' : 'Dark',
                            subtitle: isAr ? 'وضع داكن' : 'Dark Mode',
                            icon: Icons.dark_mode_outlined,
                            isSelected: isDark,
                            accent: accentColor,
                            surfaceColor: elevatedColor,
                            borderColor: borderColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onTap: () => context
                                .read<SettingsCubit>()
                                .changeThemeMode(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OptionTile(
                            title: isAr ? 'نهاري' : 'Light',
                            subtitle: isAr ? 'وضع فاتح' : 'Light Mode',
                            icon: Icons.light_mode_outlined,
                            isSelected: !isDark,
                            accent: accentColor,
                            surfaceColor: elevatedColor,
                            borderColor: borderColor,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onTap: () => context
                                .read<SettingsCubit>()
                                .changeThemeMode(ThemeMode.light),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. تصدير ملخص المحفظة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _exportPortfolioSummary(
                    context,
                    isAr: isAr,
                    surfaceColor: surfaceColor,
                    elevatedColor: elevatedColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    selectedTextColor: selectedTextColor,
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
                          Icons.copy_all,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'تصدير ملخص المحفظة'
                                  : 'Export Portfolio',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? 'عرض ونسخ سجل قطع الذهب والأوزان والتكلفة'
                                  : 'View & copy gold holdings and total weight',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. بطاقة الخصوصية والإصدار
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'تخزين محلي آمن'
                                : 'SECURE LOCAL STORAGE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr
                                ? 'جميع إعداداتك وقطع المحفظة محفوظة محلياً على جهازك.'
                                : 'All preferences and holdings are stored locally on your device.',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'GOLD TRACKER • V1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
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

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? customBadge;
  final bool isSelected;
  final Color accent;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.customBadge,
    required this.isSelected,
    required this.accent,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.onTap,
  }) : assert(
  icon != null || customBadge != null,
  'Provide either icon or customBadge',
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            customBadge ??
                Icon(
                  icon!,
                  size: 20,
                  color: isSelected ? accent : primaryText,
                ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? accent : primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}