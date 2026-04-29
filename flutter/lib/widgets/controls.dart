import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_timer.dart';
import '../theme.dart';

class Controls extends StatelessWidget {
  const Controls({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroTimer>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconBtn(
          icon: Icons.replay_rounded,
          size: 22,
          onTap: timer.reset,
        ),
        const SizedBox(width: 44),
        GestureDetector(
          onTap: timer.togglePlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wineDark.withAlpha(26),
            ),
            child: Icon(
              timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: wineDark,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 44),
        _IconBtn(
          icon: Icons.skip_next_rounded,
          size: 22,
          onTap: timer.skip,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: wineDark.withAlpha(166), size: size),
    );
  }
}
