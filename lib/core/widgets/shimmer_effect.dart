import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const ShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.colors.onSurface.withValues(alpha: _animation.value),
            borderRadius: widget.shape == BoxShape.circle ? null : widget.borderRadius ?? BorderRadius.circular(8),
            shape: widget.shape,
          ),
        );
      },
    );
  }
}
