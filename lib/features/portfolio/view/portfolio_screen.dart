import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/core/storage/currency_storage.dart';
import 'package:gold/core/storage/portfolio_storage.dart';
import 'package:gold/core/theme/app_colors.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';
import 'package:gold/features/gold_market/view_model/gold_cubit.dart';
import 'package:gold/features/gold_market/view_model/gold_state.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const double _gramsPerTroyOunce = 31.1034768;

  final PortfolioStorage _portfolioStorage = PortfolioStorage();
  final CurrencyStorage _currencyStorage = CurrencyStorage();

  List<GoldHoldingItem> _items = const [];
  String _persistedCurrency = 'EGP';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final savedCurrency = await _currencyStorage.loadCurrency(fallback: 'EGP');
    final savedItems = await _portfolioStorage.loadHoldings();
    if (!mounted) return;
    setState(() {
      _persistedCurrency = savedCurrency.toUpperCase();
      _items = savedItems;
      _loading = false;
    });
  }

  String _resolveCurrency(GoldState goldState) {
    if (goldState is GetGoldSuccess && goldState.selectedCurrency.isNotEmpty) {
      return goldState.selectedCurrency.toUpperCase();
    }
    return _persistedCurrency.toUpperCase();
  }

  double _liveGramPrice(GoldPriceModel? gold, int karat, String currency) {
    final double factor = karat / 24.0;
    if (gold != null) {
      switch (karat) {
        case 24:
          return gold.priceGram24k;
        case 22:
          return gold.priceGram24k * (22.0 / 24.0);
        case 21:
          return gold.priceGram21k;
        case 18:
          return gold.priceGram18k;
        default:
          return gold.priceGram24k * factor;
      }
    }
    final fx = _currencyStorage.fallbackFxRateFor(currency);
    return (2650.0 / _gramsPerTroyOunce) * fx * factor;
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

  String _formatShortDate(DateTime date, bool isAr) {
    const monthsEn = [
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
    if (isAr) return '${date.day}/${date.month}/${date.year}';
    return '${monthsEn[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _addOrEditItem({
    required BuildContext context,
    required GoldPriceModel? gold,
    required String currency,
    required bool isAr,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color borderColor,
    required Color accentColor,
    required Color primaryText,
    required Color secondaryText,
    required Color selectedTextColor,
    GoldHoldingItem? existing,
  }) async {
    _dismissKeyboard();

    final GoldHoldingItem? result = await showModalBottomSheet<GoldHoldingItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _HoldingBottomSheet(
        existing: existing,
        isAr: isAr,
        elevatedColor: elevatedColor,
        borderColor: borderColor,
        accentColor: accentColor,
        primaryText: primaryText,
        secondaryText: secondaryText,
        selectedTextColor: selectedTextColor,
        initialTotalCostFor: (karat, grams) =>
        _liveGramPrice(gold, karat, currency) * grams,
      ),
    );

    if (result == null || !mounted) return;

    final updatedList = List<GoldHoldingItem>.from(_items);
    if (existing != null) {
      final idx = updatedList.indexWhere((e) => e.id == existing.id);
      if (idx != -1) {
        updatedList[idx] = result;
      }
    } else {
      updatedList.add(result);
    }

    await _portfolioStorage.saveHoldings(updatedList);
    if (!mounted) return;
    setState(() => _items = updatedList);
  }

  Future<void> _deleteItem(String id) async {
    _dismissKeyboard();
    final updated = _items.where((e) => e.id != id).toList();
    await _portfolioStorage.saveHoldings(updated);
    if (!mounted) return;
    setState(() => _items = updated);
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

    final GoldState goldState = context.watch<GoldCubit>().state;
    final GoldPriceModel? gold =
    goldState is GetGoldSuccess ? goldState.goldData : null;
    final String currency = _resolveCurrency(goldState);

    double totalCurrentValue = 0;
    double totalCostValue = 0;
    double totalGrams = 0;

    for (final item in _items) {
      final double currentGramPrice =
      _liveGramPrice(gold, item.karat, currency);
      final double itemCurrentVal = item.grams * currentGramPrice;
      totalCurrentValue += itemCurrentVal;
      totalCostValue += item.totalCost;
      totalGrams += item.grams;

      debugPrint(
        'PORTFOLIO ITEM [${item.name}]: karat=${item.karat}, grams=${item.grams}, '
            'liveGram=$currentGramPrice, currentVal=$itemCurrentVal, totalCost=${item.totalCost}',
      );
    }

    final double totalPnl = totalCurrentValue - totalCostValue;
    final double pnlPercent =
    totalCostValue > 0 ? (totalPnl / totalCostValue) * 100 : 0.0;

    // تحديد الحالة بدقة: ربح واضح، خسارة واضحة، أو تعادل قريب جداً من الصفر
    final bool isLoss = totalPnl < -0.01;
    final bool isProfit = totalPnl > 0.01;
    final Color pnlColor = isLoss
        ? Colors.redAccent
        : (isProfit ? Colors.green : secondaryText);
    final String pnlSign = isLoss ? '-' : (isProfit ? '+' : '');

    final double totalOunces = totalGrams / _gramsPerTroyOunce;
    final double spot24Gram = _liveGramPrice(gold, 24, currency);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? 'محفظتي الذهبية' : 'My Gold Vault',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 3.5,
                          backgroundColor: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? 'مباشر • $currency' : 'LIVE • $currency',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(22),
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
                              ? 'إجمالي قيمة الذهب'
                              : 'TOTAL GOLD VALUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: secondaryText,
                          ),
                        ),
                        if (_items.isNotEmpty && totalCostValue > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pnlColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pnlSign${pnlPercent.abs().toStringAsFixed(1)}% ($pnlSign${_formatMoney(totalPnl.abs(), currency)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pnlColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatMoney(totalCurrentValue, currency),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.scale_outlined,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr
                              ? 'إجمالي الوزن: ${totalGrams.toStringAsFixed(1)} جرام (~${totalOunces.toStringAsFixed(2)} أونصة)'
                              : 'Total Weight: ${totalGrams.toStringAsFixed(1)} grams (~${totalOunces.toStringAsFixed(2)} oz)',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                    if (_items.isNotEmpty && totalCostValue > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'تكلفة الشراء الإجمالية: ${_formatMoney(totalCostValue, currency)}'
                            : 'Total Buy Cost: ${_formatMoney(totalCostValue, currency)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr
                              ? '• السعر الفوري: ${_formatMoney(spot24Gram, currency)}/جرام (24K)'
                              : '• Live Spot: ${_formatMoney(spot24Gram, currency)}/g (24K)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        Icon(
                          Icons.show_chart_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isAr ? 'مقتنياتي من الذهب' : 'My Gold Holdings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: elevatedColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          isAr
                              ? '${_items.length} قطع'
                              : '${_items.length} items',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: selectedTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _addOrEditItem(
                      context: context,
                      gold: gold,
                      currency: currency,
                      isAr: isAr,
                      surfaceColor: surfaceColor,
                      elevatedColor: elevatedColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      selectedTextColor: selectedTextColor,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      isAr ? 'إضافة قطعة' : 'Add Item',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 36,
                        color: accentColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'لا توجد قطع ذهب مسجلة بعد. أضف سبائكك أو مشغولاتك لمتابعة قيمتها لحظياً.'
                            : 'No gold holdings yet. Add bars or jewelry to track live value.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondaryText),
                      ),
                    ],
                  ),
                )
              else
                for (final item in _items) ...[
                  _HoldingItemCard(
                    item: item,
                    currentGramPrice:
                    _liveGramPrice(gold, item.karat, currency),
                    currency: currency,
                    isAr: isAr,
                    surfaceColor: surfaceColor,
                    elevatedColor: elevatedColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    formatMoney: _formatMoney,
                    formatDate: (d) => _formatShortDate(d, isAr),
                    onEdit: () => _addOrEditItem(
                      context: context,
                      gold: gold,
                      currency: currency,
                      isAr: isAr,
                      surfaceColor: surfaceColor,
                      elevatedColor: elevatedColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      selectedTextColor: selectedTextColor,
                      existing: item,
                    ),
                    onDelete: () => _deleteItem(item.id),
                  ),
                  const SizedBox(height: 10),
                ],

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
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
                                ? 'نصيحة المحفظة الذهبية'
                                : 'Physical Vault Tip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'أضف سبائكك أو مشغولاتك بالجرام والعيار وإجمالي سعر الشراء لمتابعة القيمة السوقية والربح أو الخسارة بدقة.'
                                : 'Tap + Add Item to log grams, karat, and total buy price. Live valuation updates in real-time.',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              height: 1.4,
                            ),
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
      ),
    );
  }
}

class _HoldingBottomSheet extends StatefulWidget {
  final GoldHoldingItem? existing;
  final bool isAr;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final Color selectedTextColor;
  final double Function(int karat, double grams) initialTotalCostFor;

  const _HoldingBottomSheet({
    required this.existing,
    required this.isAr,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.selectedTextColor,
    required this.initialTotalCostFor,
  });

  @override
  State<_HoldingBottomSheet> createState() => _HoldingBottomSheetState();
}

class _HoldingBottomSheetState extends State<_HoldingBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;
  late final TextEditingController _totalBuyController;
  late final FocusNode _nameFocus;
  late final FocusNode _gramsFocus;
  late final FocusNode _buyFocus;
  late int _selectedKarat;

  @override
  void initState() {
    super.initState();
    _selectedKarat = widget.existing?.karat ?? 21;
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    final double initialGrams = widget.existing?.grams ?? 4.0;
    _gramsController = TextEditingController(
      text: initialGrams.toString(),
    );
    final double initialTotalCost = widget.existing?.totalCost ??
        widget.initialTotalCostFor(_selectedKarat, initialGrams);
    _totalBuyController = TextEditingController(
      text: initialTotalCost.toStringAsFixed(2),
    );
    _nameFocus = FocusNode();
    _gramsFocus = FocusNode();
    _buyFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _gramsFocus.dispose();
    _buyFocus.dispose();
    _nameController.dispose();
    _gramsController.dispose();
    _totalBuyController.dispose();
    super.dispose();
  }

  void _unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submit() {
    _unfocus();
    final double grams = double.tryParse(_gramsController.text.trim()) ?? 0;
    final double totalCost =
        double.tryParse(_totalBuyController.text.trim()) ?? 0;
    if (grams <= 0 || totalCost <= 0) return;

    final String cleanName = _nameController.text.trim().isEmpty
        ? (widget.isAr
        ? 'ذهب عيار $_selectedKarat'
        : '$_selectedKarat Gold Item')
        : _nameController.text.trim();

    final item = GoldHoldingItem(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      karat: _selectedKarat,
      grams: grams,
      buyPricePerGram: totalCost / grams,
      explicitTotalCost: totalCost,
      boughtAt: widget.existing?.boughtAt ?? DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _unfocus,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? (widget.isAr ? 'إضافة قطعة ذهب' : 'Add Gold Holding')
                  : (widget.isAr ? 'تعديل قطعة ذهب' : 'Edit Gold Holding'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.primaryText,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('portfolio_item_name'),
              controller: _nameController,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: widget.primaryText),
              decoration: InputDecoration(
                labelText: widget.isAr
                    ? 'اسم القطعة (مثال: سبيكة، جنيه ذهب، خاتم)'
                    : 'Item Name (e.g. Bar, Coin, Ring)',
                labelStyle:
                TextStyle(color: widget.secondaryText, fontSize: 13),
                filled: true,
                fillColor: widget.elevatedColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('portfolio_item_grams'),
                    controller: _gramsController,
                    focusNode: _gramsFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: widget.primaryText),
                    decoration: InputDecoration(
                      labelText: widget.isAr ? 'الوزن (جرام)' : 'Weight (g)',
                      labelStyle: TextStyle(
                        color: widget.secondaryText,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.elevatedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const ValueKey('portfolio_item_total_buy'),
                    controller: _totalBuyController,
                    focusNode: _buyFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unfocus(),
                    style: TextStyle(color: widget.primaryText),
                    decoration: InputDecoration(
                      labelText: widget.isAr
                          ? 'إجمالي سعر الشراء'
                          : 'Total Buy Price',
                      labelStyle: TextStyle(
                        color: widget.secondaryText,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.elevatedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: widget.borderColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [24, 22, 21, 18].map((k) {
                final bool active = _selectedKarat == k;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('${k}K'),
                      selected: active,
                      selectedColor: widget.accentColor,
                      backgroundColor: widget.elevatedColor,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: active
                            ? widget.selectedTextColor
                            : widget.primaryText,
                      ),
                      side: BorderSide(
                        color: active ? widget.accentColor : widget.borderColor,
                      ),
                      onSelected: (_) {
                        _unfocus();
                        final double currentGrams =
                            double.tryParse(_gramsController.text.trim()) ??
                                1.0;
                        setState(() {
                          _selectedKarat = k;
                          if (widget.existing == null && currentGrams > 0) {
                            _totalBuyController.text =
                                widget.initialTotalCostFor(k, currentGrams)
                                    .toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: widget.selectedTextColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submit,
              child: Text(
                widget.isAr ? 'حفظ القطعة' : 'Save Holding',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingItemCard extends StatelessWidget {
  final GoldHoldingItem item;
  final double currentGramPrice;
  final String currency;
  final bool isAr;
  final Color surfaceColor;
  final Color elevatedColor;
  final Color borderColor;
  final Color accentColor;
  final Color primaryText;
  final Color secondaryText;
  final String Function(double value, String currency) formatMoney;
  final String Function(DateTime date) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoldingItemCard({
    required this.item,
    required this.currentGramPrice,
    required this.currency,
    required this.isAr,
    required this.surfaceColor,
    required this.elevatedColor,
    required this.borderColor,
    required this.accentColor,
    required this.primaryText,
    required this.secondaryText,
    required this.formatMoney,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double currentValue = item.grams * currentGramPrice;
    final double diff = currentValue - item.totalCost;
    final double diffPct =
    item.totalCost > 0 ? (diff / item.totalCost) * 100 : 0.0;
    final bool isLoss = diff < -0.01;
    final bool isProfit = diff > 0.01;
    final Color diffColor = isLoss
        ? Colors.redAccent
        : (isProfit ? Colors.green : secondaryText);
    final String sign = isLoss ? '-' : (isProfit ? '+' : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '${item.karat}K',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? '${item.karat}K • ${item.grams.toStringAsFixed(1)} جرام • ${formatDate(item.boughtAt)}'
                      : '${item.karat}K • ${item.grams.toStringAsFixed(1)} grams • ${formatDate(item.boughtAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(currentValue, currency),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$sign${formatMoney(diff.abs(), currency)} ($sign${diffPct.abs().toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: secondaryText, size: 18),
            color: elevatedColor,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  isAr ? 'تعديل' : 'Edit',
                  style: TextStyle(color: primaryText, fontSize: 13),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  isAr ? 'حذف' : 'Delete',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}