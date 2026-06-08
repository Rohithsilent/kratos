import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/continue_button.dart';
import 'package:go_router/go_router.dart';

class CompleteStep extends StatefulWidget {
  const CompleteStep({super.key});

  @override
  State<CompleteStep> createState() => _CompleteStepState();
}

class _CompleteStepState extends State<CompleteStep>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: Duration(milliseconds: 800))
      ..forward();
    _pulseController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _textController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(flex: 2),

          // Animated checkmark
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1 + _pulseController.value * 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _checkController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CheckPainter(progress: _checkController.value),
                    );
                  },
                ),
              );
            },
          ),

          SizedBox(height: 40),

          // Title
          FadeTransition(
            opacity: _textController,
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic)),
              child: Column(
                children: [
                  Text(
                    AppStrings.completeTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 36),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.completeSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400, height: 1.7),
                  ),
                ],
              ),
            ),
          ),

          Spacer(flex: 2),

          FadeTransition(
            opacity: _textController,
            child: ContinueButton(
              text: AppStrings.beginJourney,
              onPressed: () {
                // Navigate to home / main app
                context.go('/dashboard');
              },
              icon: Icons.rocket_launch_rounded,
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) * 0.3;

    // Draw circle
    final circleProg = (progress * 2).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -pi / 2,
      2 * pi * circleProg,
      false,
      paint,
    );

    // Draw check
    if (progress > 0.5) {
      final checkProg = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final p1 = Offset(center.dx - r * 0.35, center.dy + r * 0.05);
      final p2 = Offset(center.dx - r * 0.05, center.dy + r * 0.35);
      final p3 = Offset(center.dx + r * 0.4, center.dy - r * 0.3);

      paint.color = AppColors.primary;
      if (checkProg <= 0.5) {
        final t = checkProg * 2;
        canvas.drawLine(p1, Offset.lerp(p1, p2, t)!, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
        final t = (checkProg - 0.5) * 2;
        canvas.drawLine(p2, Offset.lerp(p2, p3, t)!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}
