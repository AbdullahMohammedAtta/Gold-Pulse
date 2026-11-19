import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/gold_market/model/gold_price_model.dart';
import 'package:material_ui/material_ui.dart';

// عدّل مسارات الاستيراد حسب مكان الملفات عندك في المشروع
import '../view_model/gold_cubit.dart';
import '../view_model/gold_state.dart';

class HomeScreen extends StatelessWidget {
   HomeScreen({super.key});

   final currencies = [
     {'code': 'USD', 'label': 'USD (\$)', 'symbol': '\$'},
     {'code': 'EUR', 'label': 'EUR (€)', 'symbol': '€'},
     {'code': 'GBP', 'label': 'GBP (£)', 'symbol': '£'},
     {'code': 'AED', 'label': 'AED (د.إ)', 'symbol': 'د.إ '},
   ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<GoldCubit, GoldState>(
          listener: (context, state) {
            if (state is GetGoldError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade900,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final GoldPriceModel? goldData = _resolveGoldData(state);
            final String selectedCurrency = _resolveCurrency(context, state);
            final bool isRefreshing =
                state is GetGoldSuccess && state.isRefreshing;

            if (state is GetGoldLoading && goldData == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              );
            }

            if (state is GetGoldError && goldData == null) {
              return _buildInitialErrorView(context, state.message);
            }

            final String symbol = _currencySymbol(selectedCurrency);
            final double ouncePrice = goldData?.priceOunce ?? 0.0;
            final double changePct = goldData?.changePercentage ?? 0.0;
            final double estimatedDelta = ouncePrice * (changePct / 100);
            final bool isPositive = changePct >= 0;

            final double g24 = goldData?.priceGram24k ?? 0.0;
            final double g22 = goldData?.priceGram22k ?? 0.0;
            final double g21 = goldData?.priceGram21k ?? 0.0;
            final double g18 = goldData?.priceGram18k ?? 0.0;

            // التولة التروية القياسية ≈ 11.6638 جرام
            const double gramsPerTola = 11.6638;

            return RefreshIndicator(
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF1E1E24),
              onRefresh: () => context.read<GoldCubit>().refreshPrices(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Top Badges ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '● LIVE LBMA SPOT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              if (isRefreshing) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '⏱ ${_formatLastUpdated(goldData?.lastUpdated)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Global Spot Price Card ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1E24), Color(0xFF25252D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GOLD SPOT PRICE (OZ / $selectedCurrency)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'XAU/$selectedCurrency',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$symbol${_formatNumber(ouncePrice)}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? const Color.fromRGBO(0, 255, 0, 0.2)
                                      : const Color.fromRGBO(255, 0, 0, 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}% '
                                      '(${estimatedDelta >= 0 ? '+' : '-'}$symbol${_formatNumber(estimatedDelta.abs())} today)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPositive
                                        ? Colors.green
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Low: $symbol${_formatNumber(ouncePrice * 0.986)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const Text(
                                'Day Range',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              Text(
                                'High: $symbol${_formatNumber(ouncePrice * 1.004)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(
                            value: 0.7,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Currency Selector Chips ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: currencies.map((item) {
                        final String code = item['code']!;
                        final String label = item['label']!;
                        final bool isSelected = selectedCurrency == code;

                        return GestureDetector(
                          onTap: () {
                            context.read<GoldCubit>().changeCurrency(code);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF1E1E24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFD700)
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // --- Karat Rates Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '⭐ Karat Rates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '● PER GRAM',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Karat Items List ---
                    _buildKaratCard(
                      '24K',
                      'Pure Gold',
                      '99.9% Purity • Investment Bullion',
                      '$symbol${_formatNumber(g24)}',
                      'Tola: $symbol${_formatNumber(g24 * gramsPerTola)}',
                      _formatDailyChange(g24, changePct, symbol),
                      isPositive: isPositive,
                    ),
                    _buildKaratCard(
                      '22K',
                      '91.6% Purity',
                      'Sovereign & Eastern Ornaments',
                      '$symbol${_formatNumber(g22)}',
                      'Tola: $symbol${_formatNumber(g22 * gramsPerTola)}',
                      _formatDailyChange(g22, changePct, symbol),
                      isPositive: isPositive,
                    ),
                    _buildKaratCard(
                      '21K',
                      'Most Popular Jewelry',
                      '87.5% Standard • Bridal & Modern',
                      '$symbol${_formatNumber(g21)}',
                      'Tola: $symbol${_formatNumber(g21 * gramsPerTola)}',
                      _formatDailyChange(g21, changePct, symbol),
                      isPositive: isPositive,
                    ),
                    _buildKaratCard(
                      '18K',
                      '75.0% Fine',
                      'European Standard & Gem Settings',
                      '$symbol${_formatNumber(g18)}',
                      'Tola: $symbol${_formatNumber(g18 * gramsPerTola)}',
                      _formatDailyChange(g18, changePct, symbol),
                      isPositive: isPositive,
                    ),

                    const SizedBox(height: 16),

                    // --- Weight Calculator Button ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calculate,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Weight Calculator',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Estimate physical bullion value',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'Convert',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFFFD700),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              onPressed: () => context.read<GoldCubit>().refreshPrices(),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKaratCard(
      String karat,
      String badge,
      String subtitle,
      String price,
      String tola,
      String change, {
        required bool isPositive,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    karat,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                tola,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                '/ gram',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 11,
                  color: isPositive ? Colors.green : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  GoldPriceModel? _resolveGoldData(GoldState state) {
    if (state is GetGoldSuccess) return state.goldData;
    if (state is GetGoldLoading) return state.previousData;
    if (state is GetGoldError) return state.previousData;
    return null;
  }

  String _resolveCurrency(BuildContext context, GoldState state) {
    if (state is GetGoldSuccess) return state.selectedCurrency;
    return context.read<GoldCubit>().currentCurrency;
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ ';
      case 'EGP':
        return 'ج.م ';
      case 'USD':
      default:
        return '\$';
    }
  }

  String _formatNumber(double value) {
    final bool isNegative = value < 0;
    final String fixed = value.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );
    return '${isNegative ? '-' : ''}$intPart.${parts[1]}';
  }

  String _formatDailyChange(double gramPrice, double chp, String symbol) {
    final double diff = gramPrice * (chp / 100);
    final String sign = diff >= 0 ? '+ ' : '- ';
    return '$sign$symbol${_formatNumber(diff.abs())} today';
  }

  String _formatLastUpdated(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'Updated just now';
    final Duration diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}