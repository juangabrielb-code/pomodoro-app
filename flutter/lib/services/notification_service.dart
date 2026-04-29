import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_cycle',
      'Pomodoro',
      channelDescription: 'Avisos de ciclo completado',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const macosDetails = DarwinNotificationDetails(sound: 'default');
    const details = NotificationDetails(
      android: androidDetails,
      macOS: macosDetails,
    );

    await _plugin.show(
      0,
      next == CycleType.work ? '¡A trabajar!' : '¡Tiempo!',
      next.label,
      details,
    );
  }
}
