import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GoldHoldingItem {
  final String id;
  final String name;
  final int karat; // 24, 22, 21, 18
  final double grams;
  final double buyPricePerGram; // سعر الشراء للجرام بالعملة المختارة أو الأساس
  final DateTime boughtAt;

  const GoldHoldingItem({
    required this.id,
    required this.name,
    required this.karat,
    required this.grams,
    required this.buyPricePerGram,
    required this.boughtAt,
  });

  double get totalCost => grams * buyPricePerGram;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'karat': karat,
    'grams': grams,
    'buyPricePerGram': buyPricePerGram,
    'boughtAt': boughtAt.toIso8601String(),
  };

  factory GoldHoldingItem.fromJson(Map<String, dynamic> json) {
    return GoldHoldingItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Gold Item',
      karat: (json['karat'] as num?)?.toInt() ?? 21,
      grams: (json['grams'] as num?)?.toDouble() ?? 0.0,
      buyPricePerGram: (json['buyPricePerGram'] as num?)?.toDouble() ?? 0.0,
      boughtAt: DateTime.tryParse(json['boughtAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PortfolioStorage {
  static const String _keyHoldings = 'gold_portfolio_holdings_v1';

  Future<List<GoldHoldingItem>> loadHoldings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyHoldings);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => GoldHoldingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHoldings(List<GoldHoldingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHoldings, encoded);
  }
}