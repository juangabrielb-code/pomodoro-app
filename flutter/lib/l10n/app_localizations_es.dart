// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cycleWork => 'TRABAJO';

  @override
  String get cycleShortBreak => 'DESCANSO CORTO';

  @override
  String get cycleLongBreak => 'DESCANSO LARGO';

  @override
  String get resetAll => 'Reiniciar todo';

  @override
  String get resetAllMessage =>
      'Se borrarán las sesiones completadas y el tiempo extra acumulado.';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get reset => 'REINICIAR';

  @override
  String get settingsTitle => 'CONFIGURACIÓN';

  @override
  String get sessionsLabel => 'SESIONES ANTES DE DESCANSO LARGO';

  @override
  String get autoStartLabel => 'AUTO-INICIO';

  @override
  String get autoStartDesc => 'Iniciar el siguiente ciclo automáticamente';

  @override
  String get apply => 'APLICAR';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get notifWorkTitle => '¡A trabajar!';

  @override
  String get notifBreakTitle => '¡Es hora de descansar!';
}
