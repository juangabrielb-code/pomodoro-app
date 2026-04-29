import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CycleType {
  work,
  shortBreak,
  longBreak;

  String get label {
    switch (this) {
      case CycleType.work:       return 'TRABAJO';
      case CycleType.shortBreak: return 'DESCANSO CORTO';
      case CycleType.longBreak:  return 'DESCANSO LARGO';
    }
  }
}

class PomodoroTimer extends ChangeNotifier {
  int workMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int sessionsUntilLongBreak;
  bool autoStart;

  CycleType _currentCycle = CycleType.work;
  bool _isRunning = false;
  int _completedSessions = 0;
  Duration _timeRemaining;
  Duration _totalDuration;

  Timer? _ticker;
  DateTime? _startDate;
  Duration _timeOnStart = Duration.zero;

  void Function(CycleType next)? onCycleComplete;

  PomodoroTimer({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsUntilLongBreak = 4,
    this.autoStart = false,
  })  : _timeRemaining = Duration(minutes: 25),
        _totalDuration = Duration(minutes: 25);

  // ── Getters ──────────────────────────────────────────────────

  CycleType get currentCycle        => _currentCycle;
  bool      get isRunning           => _isRunning;
  int       get completedSessions   => _completedSessions;

  double get progress {
    final total = _totalDuration.inMilliseconds;
    return total == 0 ? 1.0 : _timeRemaining.inMilliseconds / total;
  }

  String get formattedTime {
    final m = _timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Duration get _cycleDuration {
    switch (_currentCycle) {
      case CycleType.work:       return Duration(minutes: workMinutes);
      case CycleType.shortBreak: return Duration(minutes: shortBreakMinutes);
      case CycleType.longBreak:  return Duration(minutes: longBreakMinutes);
    }
  }

  int get filledDots {
    if (sessionsUntilLongBreak == 0) return 0;
    return _completedSessions % sessionsUntilLongBreak;
  }

  // ── Factory ──────────────────────────────────────────────────

  static Future<PomodoroTimer> load() async {
    final p = await SharedPreferences.getInstance();
    return PomodoroTimer(
      workMinutes:           p.getInt('workMinutes')           ?? 25,
      shortBreakMinutes:     p.getInt('shortBreakMinutes')     ?? 5,
      longBreakMinutes:      p.getInt('longBreakMinutes')      ?? 15,
      sessionsUntilLongBreak: p.getInt('sessionsUntilLongBreak') ?? 4,
      autoStart:             p.getBool('autoStart')            ?? false,
    );
  }

  Future<void> saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('workMinutes', workMinutes);
    await p.setInt('shortBreakMinutes', shortBreakMinutes);
    await p.setInt('longBreakMinutes', longBreakMinutes);
    await p.setInt('sessionsUntilLongBreak', sessionsUntilLongBreak);
    await p.setBool('autoStart', autoStart);
  }

  // ── Controls ─────────────────────────────────────────────────

  void togglePlayPause() => _isRunning ? pause() : start();

  void start() {
    if (_isRunning) return;
    _timeOnStart = _timeRemaining;
    _startDate   = DateTime.now();
    _isRunning   = true;
    _ticker = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _tick(),
    );
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _startDate = null;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() {
    pause();
    _timeRemaining = _cycleDuration;
    _totalDuration = _cycleDuration;
    notifyListeners();
  }

  void skip() {
    pause();
    _advance(countSession: false);
  }

  void applySettings() {
    saveSettings();
    if (!_isRunning) {
      _timeRemaining = _cycleDuration;
      _totalDuration = _cycleDuration;
      notifyListeners();
    }
  }

  // ── Private ──────────────────────────────────────────────────

  void _tick() {
    if (_startDate == null) return;
    final elapsed   = DateTime.now().difference(_startDate!);
    final remaining = _timeOnStart - elapsed;

    if (remaining <= Duration.zero) {
      _timeRemaining = Duration.zero;
      notifyListeners();
      _completeCycle();
    } else {
      _timeRemaining = remaining;
      notifyListeners();
    }
  }

  void _completeCycle() {
    pause();
    _advance(countSession: _currentCycle == CycleType.work);
    onCycleComplete?.call(_currentCycle); // currentCycle is now the next one
    if (autoStart) start();
  }

  void _advance({required bool countSession}) {
    switch (_currentCycle) {
      case CycleType.work:
        if (countSession) _completedSessions++;
        final goLong = _completedSessions > 0 &&
            _completedSessions % sessionsUntilLongBreak == 0;
        _currentCycle = goLong ? CycleType.longBreak : CycleType.shortBreak;
      case CycleType.shortBreak:
      case CycleType.longBreak:
        _currentCycle = CycleType.work;
    }
    _totalDuration = _cycleDuration;
    _timeRemaining = _cycleDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
