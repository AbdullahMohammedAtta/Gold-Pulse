import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceAlertSettings {
  final bool enabled;
  final double? targetPrice;

  const PriceAlertSettings({
    required this.enabled,
    required this.targetPrice,
  });
}

class PriceAlertService {
  static const String _keyEnabled = 'gold_alert_enabled';
  static const String _keyTarget = 'gold_alert_target_price';
  static const String _keyLastTriggeredPrice = 'gold_alert_last_triggered';

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);


    await _notifications.initialize(settings: initSettings);

    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<PriceAlertSettings> loadAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final target = prefs.getDouble(_keyTarget);
    return PriceAlertSettings(enabled: enabled, targetPrice: target);
  }

  Future<void> saveAlertSettings({
    required bool enabled,
    required double? targetPrice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    if (targetPrice != null) {
      await prefs.setDouble(_keyTarget, targetPrice);
    }
    await prefs.remove(_keyLastTriggeredPrice);
  }

  Future<bool> checkAndNotifyIfExceeded({
    required double currentPrice,
    required String currency,
    required bool isAr,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final target = prefs.getDouble(_keyTarget);

    if (!enabled || target == null || target <= 0) return false;
    if (currentPrice <= target) return false;

    final lastTriggered = prefs.getDouble(_keyLastTriggeredPrice);
    if (lastTriggered != null && (currentPrice - lastTriggered).abs() < 0.01) {
      return false;
    }

    await init();
    const androidDetails = AndroidNotificationDetails(
      'gold_price_alerts',
      'Gold Price Alerts',
      channelDescription: 'Notifications when gold exceeds target price',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final title = isAr
        ? 'تنبيه ارتفاع سعر الذهب'
        : 'Gold Price Alert Triggered';
    final body = isAr
        ? 'سعر الأونصة وصل إلى ${currentPrice.toStringAsFixed(2)} $currency (تجاوز الحد ${target.toStringAsFixed(2)})'
        : 'Gold reached ${currentPrice.toStringAsFixed(2)} $currency (above ${target.toStringAsFixed(2)})';

    await _notifications.show(id: 1001,title: title,body: body, notificationDetails: details);
    await prefs.setDouble(_keyLastTriggeredPrice, currentPrice);
    return true;
  }
}