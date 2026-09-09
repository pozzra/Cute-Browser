import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import 'animated_press.dart';

class CuteMenuOverlay extends StatelessWidget {
  const CuteMenuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? CuteColors.surfaceDark : CuteColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: isDark ? CuteColors.glassBorderDark : CuteColors.glassBorderLight,
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Handle ---
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Header ---
              Text(
                "Settings & More",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // --- Theme Selector ---
              _buildSectionTitle("Appearance"),
              const SizedBox(height: 12),
              _buildThemeSelector(context, browserProvider),
              const SizedBox(height: 24),

              // --- Feature Toggles ---
              _buildSectionTitle("Features"),
              const SizedBox(height: 12),
              _buildToggleItem(
                context,
                "Ad Blocker",
                Icons.block_flipped_rounded,
                browserProvider.isAdBlockEnabled,
                (val) => browserProvider.toggleAdBlock(val),
              ),
              _buildToggleItem(
                context,
                "Background Play",
                Icons.play_circle_outline_rounded,
                browserProvider.isBackgroundPlayEnabled,
                (val) => browserProvider.toggleBackgroundPlay(val),
              ),
              _buildToggleItem(
                context,
                "Desktop Mode",
                Icons.desktop_windows_rounded,
                browserProvider.isDesktopMode,
                (val) => browserProvider.toggleDesktopMode(val),
              ),
              _buildToggleItem(
                context,
                "Safe Browsing",
                Icons.security_rounded,
                browserProvider.isSafeBrowsingEnabled,
                (val) => browserProvider.toggleSafeBrowsing(val),
              ),
              const SizedBox(height: 32),

              // --- Action Bar ---
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.arrow_back_rounded,
                      label: "Back",
                      onTap: () => Navigator.pop(context),
                      color: theme.colorScheme.primary,
                    ),
                    _ActionButton(
                      icon: Icons.share_rounded,
                      label: "Share",
                      onTap: () => Navigator.pop(context),
                      color: CuteColors.secondary,
                    ),
                    _ActionButton(
                      icon: Icons.download_rounded,
                      label: "Save",
                      onTap: () => Navigator.pop(context),
                      color: CuteColors.tertiary,
                    ),
                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: "Reset",
                      onTap: () => Navigator.pop(context),
                      color: CuteColors.highlight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: CuteColors.lightText,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, BrowserProvider provider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildThemeOption(context, provider, ThemeMode.light, "Light", Icons.wb_sunny_rounded),
          _buildThemeOption(context, provider, ThemeMode.system, "System", Icons.settings_suggest_rounded),
          _buildThemeOption(context, provider, ThemeMode.dark, "Dark", Icons.nightlight_round),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, BrowserProvider provider, ThemeMode mode, String label, IconData icon) {
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: AnimatedPress(
        onTap: () => provider.updateThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? CuteColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: CuteColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : provider.adaptiveTextColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : provider.adaptiveTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, String label, IconData icon, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: CuteColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: CuteColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
