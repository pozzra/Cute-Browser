import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../screens/tabs_screen.dart';
import 'cute_menu_overlay.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;
    final iconColor = theme.colorScheme.onSurface;
    final secondaryIconColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light 
                  ? Colors.black12 
                  : Colors.white.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SmoothActionButton(
                onTap: browserProvider.canGoBack ? browserProvider.goBack : null,
                icon: Icons.arrow_back_ios_rounded,
                color: browserProvider.canGoBack ? iconColor : secondaryIconColor,
              ),
              _SmoothActionButton(
                onTap: browserProvider.canGoForward ? browserProvider.goForward : null,
                icon: Icons.arrow_forward_ios_rounded,
                color: browserProvider.canGoForward ? iconColor : secondaryIconColor,
              ),
              const SizedBox(width: 4),
              _SmoothActionButton(
                onTap: () => browserProvider.addTab(),
                icon: Icons.add,
                color: Colors.white,
                isFab: true,
                fabColor: browserProvider.themeColor,
              ),
              const SizedBox(width: 4),
              _SmoothActionButton(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TabsScreen()));
                },
                icon: Icons.grid_view_rounded,
                color: iconColor,
              ),
              _SmoothActionButton(
                onTap: () {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => const CuteMenuOverlay(),
                   );
                },
                icon: Icons.more_vert_rounded,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmoothActionButton extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final bool isFab;
  final Color? fabColor;

  const _SmoothActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    this.isFab = false,
    this.fabColor,
  });

  @override
  State<_SmoothActionButton> createState() => _SmoothActionButtonState();
}

class _SmoothActionButtonState extends State<_SmoothActionButton> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _scale = 0.85);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _scale = 1.0);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(widget.icon, color: widget.color, size: widget.isFab ? 28 : 24);

    if (widget.isFab) {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.fabColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.fabColor!.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: iconWidget),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: iconWidget,
        ),
      ),
    );
  }
}
