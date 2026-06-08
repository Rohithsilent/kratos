import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../core/theme/app_colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _particleController;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 12),
    )..repeat();

    _particles = List.generate(
      20,
      (_) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 2 + 0.5,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _orbController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(color: context.colors.surface),

        // Animated red orbs
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, _) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _OrbPainter(
                progress: _orbController.value,
                primaryColor: context.colors.primary,
              ),
            );
          },
        ),

        // Floating particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  primaryColor: context.colors.primary,
                ),
              );
            },
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _OrbPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 80);

    // Large red orb - top right, slowly drifting
    final orb1X = size.width * 0.75 + sin(progress * 2 * pi) * 40;
    final orb1Y = size.height * 0.15 + cos(progress * 2 * pi) * 30;
    paint.color = primaryColor.withOpacity(0.12);
    canvas.drawCircle(Offset(orb1X, orb1Y), 120, paint);

    // Medium red orb - bottom left
    final orb2X = size.width * 0.2 + cos(progress * 2 * pi + 1) * 50;
    final orb2Y = size.height * 0.7 + sin(progress * 2 * pi + 1) * 40;
    paint.color = primaryColor.withOpacity(0.08);
    canvas.drawCircle(Offset(orb2X, orb2Y), 90, paint);

    // Small accent orb - center
    final orb3X = size.width * 0.5 + sin(progress * 2 * pi + 2.5) * 60;
    final orb3Y = size.height * 0.45 + cos(progress * 2 * pi + 2.5) * 35;
    paint.color = primaryColor.withOpacity(0.06);
    canvas.drawCircle(Offset(orb3X, orb3Y), 70, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color primaryColor;

  _ParticlePainter({required this.particles, required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed) % 1.0;
      final opacity = p.opacity * (1.0 - (y - 0.5).abs() * 1.2).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

class _Particle {
  final double x, y, radius, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}
