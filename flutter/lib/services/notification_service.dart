import 'dart:io' show Platform;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../l10n/app_localizations.dart';
import '../models/pomodoro_timer.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const macos   = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, macOS: macos),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showCycleComplete(CycleType next) async {
    final l10n = _l10n();

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_cycle',
      'Pomodoro',
      channelDescription: 'Cycle complete notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const macosDetails = DarwinNotificationDetails(sound: 'default');
    const details = NotificationDetails(
      android: androidDetails,
      macOS: macosDetails,
    );

    final title = next == CycleType.work ? l10n.notifWorkTitle : l10n.notifBreakTitle;
    final body  = switch (next) {
      CycleType.work       => l10n.cycleWork,
      CycleType.shortBreak => l10n.cycleShortBreak,
      CycleType.longBreak  => l10n.cycleLongBreak,
    };

    await _plugin.show(0, title, body, details);
  }

  // Resolves localization without a BuildContext using the device locale.
  static AppLocalizations _l10n() {
    try {
      final tag = Platform.localeName.split('_').first;
      return lookupAppLocalizations(Locale(tag));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }
}
