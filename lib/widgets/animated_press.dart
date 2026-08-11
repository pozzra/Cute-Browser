import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress> {
  double _currentScale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _currentScale = widget.scale);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _currentScale = 1.0);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _currentScale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _currentScale,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
