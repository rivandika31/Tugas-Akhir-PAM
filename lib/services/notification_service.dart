import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'Default channel for general notifications',
    importance: Importance.high,
  );

  Future<void> init() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      // Create channel (safe to call multiple times)
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_defaultChannel);

  // Android 13+ runtime permission
  await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> showPaymentReminder({
    required String planName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _NotificationIds.defaultChannelId,
      'General Notifications',
      channelDescription: 'Default channel for general notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      _NotificationIds.paymentReminderId,
      'Selesaikan Pembayaran',
      'Anda belum menyelesaikan pembayaran untuk $planName. Ketuk untuk melanjutkan.',
      notificationDetails,
    );
  }
}

class _NotificationIds {
  static const int paymentReminderId = 1001;
  static const String defaultChannelId = 'default_channel';
}
