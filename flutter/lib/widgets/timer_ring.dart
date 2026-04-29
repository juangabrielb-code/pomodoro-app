import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_timer.dart';
import '../theme.dart';

class TimerRing extends StatelessWidget {
  const TimerRing({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroTimer>();
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _RingPainter(progress: timer.progress),
          ),
          Text(
            timer.formattedTime,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w100,
              fontFamily: 'monospace',
              color: timer.isOvertime ? wineMid : wineDark,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = wineDark.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final ringPaint = Paint()
      ..color = wineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
