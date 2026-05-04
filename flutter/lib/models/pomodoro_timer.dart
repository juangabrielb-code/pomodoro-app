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

  // ── Settings ─────────────────────────────────────────────────
  int workMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int sessionsUntilLongBreak;
  bool autoStart;

  // ── Overtime stats ───────────────────────────────────────────
  Duration totalWorkOvertime;
  Duration totalBreakOvertime;

  // ── Private state ────────────────────────────────────────────
  CycleType _currentCycle = CycleType.work;
  bool _isRunning = false;
  int _completedSessions = 0;
  Duration _timeRemaining;
  Duration _totalDuration;
  bool _isOvertime = false;
  Duration _overtimeElapsed = Duration.zero;

  Timer? _ticker;
  DateTime? _cycleEndDate;  // absolute moment the cycle should end
  DateTime? _pauseDate;     // moment we paused (null when running)

  void Function(CycleType next)? onCycleComplete;

  PomodoroTimer({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsUntilLongBreak = 4,
    this.autoStart = false,
    this.totalWorkOvertime = Duration.zero,
    this.totalBreakOvertime = Duration.zero,
  })  : _timeRemaining = const Duration(minutes: 25),
        _totalDuration = const Duration(minutes: 25);

  // ── Getters ──────────────────────────────────────────────────

  CycleType get currentCycle      => _currentCycle;
  bool      get isRunning         => _isRunning;
  int       get completedSessions => _completedSessions;
  bool      get isOvertime        => _isOvertime;
  Duration  get overtimeElapsed   => _overtimeElapsed;

  double get progress {
    if (_isOvertime) return 0.0;
    final total = _totalDuration.inMilliseconds;
    return total == 0 ? 1.0 : (_timeRemaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String get formattedTime {
    if (_isOvertime) {
      final s = _overtimeElapsed.inSeconds;
      return '+${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    }
    final m = _timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get filledDots {
    if (sessionsUntilLongBreak == 0) return 0;
    return _completedSessions % sessionsUntilLongBreak;
  }

  Duration get _cycleDuration {
    switch (_currentCycle) {
      case CycleType.work:       return Duration(minutes: workMinutes);
      case CycleType.shortBreak: return Duration(minutes: shortBreakMinutes);
      case CycleType.longBreak:  return Duration(minutes: longBreakMinutes);
    }
  }

  // Preview the next cycle without mutating state (used for notification on overtime entry)
  CycleType get _peekNextCycle {
    switch (_currentCycle) {
      case CycleType.work:
        if (sessionsUntilLongBreak == 0) return CycleType.shortBreak;
        final next = _completedSessions + 1;
        return (next % sessionsUntilLongBreak == 0) ? CycleType.longBreak : CycleType.shortBreak;
      case CycleType.shortBreak:
      case CycleType.longBreak:
        return CycleType.work;
    }
  }

  // ── Factory ──────────────────────────────────────────────────

  static Future<PomodoroTimer> load() async {
    final p = await SharedPreferences.getInstance();
    return PomodoroTimer(
      workMinutes:            p.getInt('workMinutes')              ?? 25,
      shortBreakMinutes:      p.getInt('shortBreakMinutes')        ?? 5,
      longBreakMinutes:       p.getInt('longBreakMinutes')         ?? 15,
      sessionsUntilLongBreak: p.getInt('sessionsUntilLongBreak')   ?? 4,
      autoStart:              p.getBool('autoStart')               ?? false,
      totalWorkOvertime:      Duration(seconds: p.getInt('totalWorkOvertimeSecs')  ?? 0),
      totalBreakOvertime:     Duration(seconds: p.getInt('totalBreakOvertimeSecs') ?? 0),
    );
  }

  Future<void> saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('workMinutes', workMinutes);
    await p.setInt('shortBreakMinutes', shortBreakMinutes);
    await p.setInt('longBreakMinutes', longBreakMinutes);
    await p.setInt('sessionsUntilLongBreak', sessionsUntilLongBreak);
    await p.setBool('autoStart', autoStart);
    await p.setInt('totalWorkOvertimeSecs',  totalWorkOvertime.inSeconds);
    await p.setInt('totalBreakOvertimeSecs', totalBreakOvertime.inSeconds);
  }

  // ── Controls ─────────────────────────────────────────────────

  void togglePlayPause() => _isRunning ? pause() : start();

  void start() {
    if (_isRunning) return;

    final now = DateTime.now();
    if (_pauseDate != null && _cycleEndDate != null) {
      // Resume: shift the end date forward by the time we were paused.
      // Works correctly both in normal mode and in overtime (cycleEndDate stays in the past,
      // and the shift keeps the overtime duration where we left off).
      final pausedFor = now.difference(_pauseDate!);
      _cycleEndDate = _cycleEndDate!.add(pausedFor);
      _pauseDate = null;
    } else {
      // Fresh start
      _pauseDate = null;
      _cycleEndDate = now.add(_timeRemaining);
    }

    _isRunning = true;
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _pauseDate = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _cycleEndDate = null;
    _pauseDate = null;
    _isOvertime = false;
    _overtimeElapsed = Duration.zero;
    _timeRemaining = _cycleDuration;
    _totalDuration = _cycleDuration;
    notifyListeners();
  }

  void skip() {
    // Count the session only if the timer reached 0 naturally (overtime was active)
    final shouldCount = _isOvertime && _currentCycle == CycleType.work;
    _accumulateOvertime();

    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _cycleEndDate = null;
    _pauseDate = null;
    _isOvertime = false;
    _overtimeElapsed = Duration.zero;

    _advance(countSession: shouldCount);
    if (autoStart) start();
  }

  void fullReset() {
    _isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    _cycleEndDate = null;
    _pauseDate = null;
    _isOvertime = false;
    _overtimeElapsed = Duration.zero;

    _currentCycle = CycleType.work;
    _timeRemaining = Duration(minutes: workMinutes);
    _totalDuration = Duration(minutes: workMinutes);

    _completedSessions = 0;
    totalWorkOvertime = Duration.zero;
    totalBreakOvertime = Duration.zero;

    saveSettings(); // fire-and-forget, igual que en _accumulateOvertime()
    notifyListeners();
  }

  void applySettings() {
    saveSettings();
    if (!_isRunning) {
      _cycleEndDate = null;
      _pauseDate = null;
      _isOvertime = false;
      _overtimeElapsed = Duration.zero;
      _timeRemaining = _cycleDuration;
      _totalDuration = _cycleDuration;
      notifyListeners();
    }
  }

  // ── Private ──────────────────────────────────────────────────

  void _tick() {
    if (_cycleEndDate == null) return;

    // diff > 0: time still remaining. diff < 0: we're in overtime.
    final diff = _cycleEndDate!.difference(DateTime.now());

    if (diff > Duration.zero) {
      _timeRemaining = diff;
      notifyListeners();
    } else {
      _timeRemaining = Duration.zero;
      final elapsed = Duration(microseconds: diff.inMicroseconds.abs());

      if (!_isOvertime) {
        // First tick past 0 — enter overtime
        _isOvertime = true;
        onCycleComplete?.call(_peekNextCycle);
      }
      _overtimeElapsed = elapsed;
      notifyListeners();
    }
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

  // Add current overtime to the running total before clearing it.
  void _accumulateOvertime() {
    if (!_isOvertime || _overtimeElapsed == Duration.zero) return;
    if (_currentCycle == CycleType.work) {
      totalWorkOvertime += _overtimeElapsed;
    } else {
      totalBreakOvertime += _overtimeElapsed;
    }
    saveSettings(); // fire-and-forget; persists updated stats
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
