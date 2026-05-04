import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/pomodoro_timer.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _work;
  late int _short;
  late int _long;
  late int _sessions;
  late bool _autoStart;

  @override
  void initState() {
    super.initState();
    final t  = context.read<PomodoroTimer>();
    _work      = t.workMinutes;
    _short     = t.shortBreakMinutes;
    _long      = t.longBreakMinutes;
    _sessions  = t.sessionsUntilLongBreak;
    _autoStart = t.autoStart;
  }

  void _apply() {
    final t = context.read<PomodoroTimer>()
      ..workMinutes            = _work
      ..shortBreakMinutes      = _short
      ..longBreakMinutes       = _long
      ..sessionsUntilLongBreak = _sessions
      ..autoStart              = _autoStart;
    t.applySettings();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: greige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, l10n),
              const SizedBox(height: 20),
              const Divider(color: Color(0x33722F37)),
              const SizedBox(height: 24),
              _durationRow(l10n.cycleWork,       _work,  1, 90, (v) => setState(() => _work  = v), l10n),
              const SizedBox(height: 20),
              _durationRow(l10n.cycleShortBreak, _short, 1, 30, (v) => setState(() => _short = v), l10n),
              const SizedBox(height: 20),
              _durationRow(l10n.cycleLongBreak,  _long,  1, 60, (v) => setState(() => _long  = v), l10n),
              const SizedBox(height: 20),
              _sessionRow(l10n),
              const SizedBox(height: 20),
              _autoStartRow(l10n),
              const Spacer(),
              _applyButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: wineDark,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close, color: wineDark.withAlpha(153), size: 18),
        ),
      ],
    );
  }

  Widget _durationRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChange,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: wineDark.withAlpha(153),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   wineDark,
                  thumbColor:         wineDark,
                  inactiveTrackColor: wineDark.withAlpha(40),
                  overlayColor:       wineDark.withAlpha(20),
                  trackHeight:        2,
                ),
                child: Slider(
                  value:     value.toDouble(),
                  min:       min.toDouble(),
                  max:       max.toDouble(),
                  divisions: max - min,
                  onChanged: (v) => onChange(v.round()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 52,
              child: Text(
                l10n.minutes(value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  color: wineDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sessionRow(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sessionsLabel,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: wineDark.withAlpha(153),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:   wineDark,
                  thumbColor:         wineDark,
                  inactiveTrackColor: wineDark.withAlpha(40),
                  overlayColor:       wineDark.withAlpha(20),
                  trackHeight:        2,
                ),
                child: Slider(
                  value:     _sessions.toDouble(),
                  min:       2,
                  max:       8,
                  divisions: 6,
                  onChanged: (v) => setState(() => _sessions = v.round()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              child: Text(
                '$_sessions',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  color: wineDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _autoStartRow(AppLocalizations l10n) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.autoStartLabel,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: wineDark.withAlpha(153),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.autoStartDesc,
              style: TextStyle(fontSize: 10, color: wineDark.withAlpha(128)),
            ),
          ],
        ),
        const Spacer(),
        Switch(
          value:              _autoStart,
          onChanged:          (v) => setState(() => _autoStart = v),
          activeThumbColor:   wineDark,
          activeTrackColor:   wineDark.withAlpha(180),
          inactiveTrackColor: wineDark.withAlpha(40),
        ),
      ],
    );
  }

  Widget _applyButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _apply,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: wineDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          l10n.apply,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: greige,
          ),
        ),
      ),
    );
  }
}
