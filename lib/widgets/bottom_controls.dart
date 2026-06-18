import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../screens/tabs_screen.dart';
import 'cute_menu_overlay.dart';
import 'animated_press.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<BrowserProvider>(
              builder: (context, browserProvider, _) {
                if (!(browserProvider.isCurrentlyPlaying || (browserProvider.tabs.isNotEmpty && browserProvider.currentTab.isPlaying))) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PlaybackButton(
                        onTap: browserProvider.previousVideo,
                        icon: Icons.skip_previous_rounded,
                        color: const Color(0xFFB2E2F2), // Pastel Blue
                        size: 40,
                      ),
                      const SizedBox(width: 20),
                      _PlaybackButton(
                        onTap: browserProvider.togglePlay,
                        icon: (browserProvider.isCurrentlyPlaying || browserProvider.currentTab.isPlaying)
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFFFFB7B2), // Pastel Pink
                        size: 56,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 20),
                      _PlaybackButton(
                        onTap: browserProvider.nextVideo,
                        icon: Icons.skip_next_rounded,
                        color: const Color(0xFFE2B2F2), // Pastel Purple
                        size: 40,
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Selector<BrowserProvider, bool>(
                    selector: (_, p) => p.canGoBack,
                    builder: (context, canGoBack, _) {
                      return _SmoothActionButton(
                        onTap: canGoBack ? context.read<BrowserProvider>().goBack : null,
                        icon: Icons.arrow_back_ios_rounded,
                        color: canGoBack ? iconColor : secondaryIconColor,
                      );
                    },
                  ),
                  Selector<BrowserProvider, bool>(
                    selector: (_, p) => p.canGoForward,
                    builder: (context, canGoForward, _) {
                      return _SmoothActionButton(
                        onTap: canGoForward ? context.read<BrowserProvider>().goForward : null,
                        icon: Icons.arrow_forward_ios_rounded,
                        color: canGoForward ? iconColor : secondaryIconColor,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Selector<BrowserProvider, Color>(
                    selector: (_, p) => p.themeColor,
                    builder: (context, themeColor, _) {
                      return _SmoothActionButton(
                        onTap: () => context.read<BrowserProvider>().addTab(),
                        icon: Icons.add,
                        color: Colors.white,
                        isFab: true,
                        fabColor: themeColor,
                      );
                    },
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
          ],
        ),
      ),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _PlaybackButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.size,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

class _SmoothActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: color, size: isFab ? 28 : 24);

    if (isFab) {
      iconWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: fabColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: fabColor!.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: iconWidget),
      );
    }

    return AnimatedPress(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: iconWidget,
      ),
    );
  }
}
