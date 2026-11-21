class GoldBarModel {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  const GoldBarModel({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory GoldBarModel.fromJson(Map<String, dynamic> json) {
    final DateTime parsedDate = _parseDate(
      json['timestamp'] ?? json['time'] ?? json['date'] ?? json['t'],
    );
    final double closeVal = _toDouble(
      json['close'] ?? json['c'] ?? json['price'] ?? json['value'],
    );
    final double openVal = _toDouble(
      json['open'] ?? json['o'] ?? closeVal,
    );
    final double highVal = _toDouble(
      json['high'] ?? json['h'] ?? (openVal > closeVal ? openVal : closeVal),
    );
    final double lowVal = _toDouble(
      json['low'] ?? json['l'] ?? (openVal < closeVal ? openVal : closeVal),
    );

    return GoldBarModel(
      date: parsedDate,
      open: openVal,
      high: highVal,
      low: lowVal,
      close: closeVal,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) {
      // لو بالثواني أو بالميلي ثانية
      return raw > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true)
          .toLocal();
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}