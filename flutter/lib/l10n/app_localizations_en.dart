// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cycleWork => 'WORK';

  @override
  String get cycleShortBreak => 'SHORT BREAK';

  @override
  String get cycleLongBreak => 'LONG BREAK';

  @override
  String get resetAll => 'Reset all';

  @override
  String get resetAllMessage =>
      'Completed sessions and accumulated overtime will be cleared.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get reset => 'RESET';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get sessionsLabel => 'SESSIONS BEFORE LONG BREAK';

  @override
  String get autoStartLabel => 'AUTO-START';

  @override
  String get autoStartDesc => 'Start next cycle automatically';

  @override
  String get apply => 'APPLY';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get notifWorkTitle => 'Time to work!';

  @override
  String get notifBreakTitle => 'Time to rest!';
}
