import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/pomodoro_timer.dart';
import '../widgets/timer_ring.dart';
import '../widgets/session_dots.dart';
import '../widgets/controls.dart';
import '../theme.dart';
import 'settings_screen.dart';

String _cycleLabel(CycleType cycle, AppLocalizations l10n) => switch (cycle) {
  CycleType.work       => l10n.cycleWork,
  CycleType.shortBreak => l10n.cycleShortBreak,
  CycleType.longBreak  => l10n.cycleLongBreak,
};

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final cycle = context.select<PomodoroTimer, CycleType>((t) => t.currentCycle);

    return Scaffold(
      backgroundColor: greige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context, l10n),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _cycleLabel(cycle, l10n),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: wineDark,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Center(child: TimerRing()),
              const SizedBox(height: 32),
              const Center(child: SessionDots()),
              const SizedBox(height: 40),
              const Controls(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        const Text(
          'pomodoro',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            color: wineMid,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _confirmFullReset(context, l10n),
          child: Icon(Icons.autorenew, color: wineDark.withAlpha(128), size: 20),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Icon(Icons.tune_rounded, color: wineDark, size: 20),
        ),
      ],
    );
  }

  void _confirmFullReset(BuildContext context, AppLocalizations l10n) {
    final timer = context.read<PomodoroTimer>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: greige,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          l10n.resetAll,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: wineDark,
          ),
        ),
        content: Text(
          l10n.resetAllMessage,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: wineDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: wineDark.withAlpha(153),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              timer.fullReset();
              Navigator.of(ctx).pop();
            },
            child: Text(
              l10n.reset,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: wineDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
