import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_timer.dart';
import '../theme.dart';

class SessionDots extends StatelessWidget {
  const SessionDots({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroTimer>();
    final filled = timer.filledDots;
    final total  = timer.sessionsUntilLongBreak;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
                ? wineDark
                : wineDark.withAlpha(46),
          ),
        );
      }),
    );
  }
}
