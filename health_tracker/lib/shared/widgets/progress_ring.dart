import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0+
  final double size;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Widget? child;
  final Duration duration;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 180.0,
    this.strokeWidth = 14.0,
    this.gradientColors = const [Color(0xFF6366F1), Color(0xFFF43F5E)],
    this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  gradientColors: widget.gradientColors,
                  themeBrightness: Theme.of(context).brightness,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Brightness themeBrightness;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.themeBrightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track paint
    final trackPaint = Paint()
      ..color = themeBrightness == Brightness.dark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc paint
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2;
    // Cap progress at slightly over 1.0 for rendering logic, but draw correct angle
    final sweepAngle = 2 * pi * min(progress, 1.0);

    if (sweepAngle > 0) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          startAngle: 0.0,
          endAngle: 2 * pi,
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.themeBrightness != themeBrightness;
  }
}
