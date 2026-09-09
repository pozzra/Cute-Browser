import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/browser_provider.dart';
import '../screens/tabs_screen.dart';
import 'cute_menu_overlay.dart';
import 'animated_press.dart';
import '../theme/colors.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.colorScheme.onSurface;
    final secondaryIconColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Floating Playback Dock ---
            Consumer<BrowserProvider>(
              builder: (context, browserProvider, _) {
                if (!(browserProvider.isCurrentlyPlaying || (browserProvider.tabs.isNotEmpty && browserProvider.currentTab.isPlaying))) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? CuteColors.surfaceDark : CuteColors.surfaceLight,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark ? CuteColors.glassBorderDark : CuteColors.glassBorderLight,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CuteColors.primary.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PlaybackButton(
                              onTap: browserProvider.previousVideo,
                              icon: Icons.skip_previous_rounded,
                              glowColor: CuteColors.secondary,
                              size: 44,
                            ),
                            const SizedBox(width: 24),
                            _PlaybackButton(
                              onTap: browserProvider.togglePlay,
                              icon: (browserProvider.isCurrentlyPlaying || browserProvider.currentTab.isPlaying)
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              glowColor: CuteColors.primary,
                              size: 56,
                              iconSize: 32,
                            ),
                            const SizedBox(width: 24),
                            _PlaybackButton(
                              onTap: browserProvider.nextVideo,
                              icon: Icons.skip_next_rounded,
                              glowColor: CuteColors.tertiary,
                              size: 44,
                            ),
                            const SizedBox(width: 24),
                            _PlaybackButton(
                              onTap: browserProvider.togglePiP,
                              icon: Icons.picture_in_picture_rounded,
                              glowColor: CuteColors.highlight,
                              size: 44,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- Main Navigation Dock ---
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? CuteColors.surfaceDark : CuteColors.surfaceLight,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark ? CuteColors.glassBorderDark : CuteColors.glassBorderLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Selector<BrowserProvider, bool>(
                        selector: (_, p) => p.canGoBack,
                        builder: (context, canGoBack, _) {
                          return _SmoothActionButton(
                            onTap: canGoBack ? context.read<BrowserProvider>().goBack : null,
                            icon: Icons.arrow_back_ios_new_rounded,
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
                      const SizedBox(width: 8),
                      Selector<BrowserProvider, Color>(
                        selector: (_, p) => p.themeColor,
                        builder: (context, themeColor, _) {
                          return _SmoothActionButton(
                            onTap: () => context.read<BrowserProvider>().addTab(),
                            icon: Icons.add_rounded,
                            color: Colors.white,
                            isFab: true,
                            fabColor: themeColor,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _SmoothActionButton(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TabsScreen()));
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
                        icon: Icons.more_horiz_rounded,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
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
  final Color glowColor;
  final double size;
  final double iconSize;

  const _PlaybackButton({
    required this.onTap,
    required this.icon,
    required this.glowColor,
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
          color: glowColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: glowColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: glowColor,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fabColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: fabColor!.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: iconWidget),
      );
    }

    return AnimatedPress(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: iconWidget,
      ),
    );
  }
}
