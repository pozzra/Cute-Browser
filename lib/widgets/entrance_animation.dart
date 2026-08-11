import 'package:flutter/material.dart';

/// Lightweight staggered entrance animation: fades in and slides up.
/// `index` is used to stagger items in a list/grid.
class EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offset;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 450),
    this.offset = 24,
  });

  @override
  Widget build(BuildContext context) {
    final curve = Curves.easeOutCubic;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: index * 60),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
