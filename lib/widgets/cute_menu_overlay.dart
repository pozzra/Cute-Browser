import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/browser_provider.dart';
import '../screens/history_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../services/update_service.dart';
import '../screens/downloads_screen.dart';
import 'animated_press.dart';

class CuteMenuOverlay extends StatelessWidget {
  const CuteMenuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;
    final dividerColor = theme.dividerColor;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              context,
              icon: Icons.add_box_outlined,
              title: "New tab",
              onTap: () {
                browserProvider.addTab();
                Navigator.pop(context);
              },
            ),
            Divider(color: dividerColor),
            _buildMenuItem(
              context,
              icon: Icons.history_rounded,
              title: "History",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.download_outlined,
              title: "Downloads",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmarks_outlined,
              title: "Bookmarks",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
            ),
            Divider(color: dividerColor),
            // Expanded Settings Section
            _buildThemeModeSelector(context),
            _buildToggleItem(
              context,
              icon: Icons.block_rounded,
              title: "Ad Block",
              value: browserProvider.isAdBlockEnabled,
              onChanged: (val) => browserProvider.toggleAdBlock(val),
            ),
            _buildToggleItem(
              context,
              icon: Icons.music_note_rounded,
              title: "Background Play",
              value: browserProvider.isBackgroundPlayEnabled,
              onChanged: (val) => browserProvider.toggleBackgroundPlay(val),
            ),
            _buildToggleItem(
              context,
              icon: Icons.security_rounded,
              title: "Safe Browsing",
              value: browserProvider.isSafeBrowsingEnabled,
              onChanged: (val) => browserProvider.toggleSafeBrowsing(val),
            ),
            _buildToggleItem(
              context,
              icon: Icons.desktop_mac_rounded,
              title: "Desktop Mode",
              value: browserProvider.isDesktopMode,
              onChanged: (val) => browserProvider.toggleDesktopMode(val),
            ),
            Divider(color: dividerColor),
            _buildMenuItem(
              context,
              icon: Icons.system_update_alt_rounded,
              title: "Check for updates",
              onTap: () {
                Navigator.pop(context);
                UpdateService.checkAndPromptUpdate(context);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.home_rounded,
              title: "Home",
              onTap: () {
                Navigator.pop(context);
                browserProvider.goHome();
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedPress(
                    onTap: () {
                      browserProvider.goBack();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back_rounded, color: textColor),
                    ),
                  ),
                  AnimatedPress(
                    onTap: () {
                      final url = browserProvider.currentUrl;
                      final title = browserProvider.currentTitle;
                      if (url.isNotEmpty && url != "about:blank") {
                        SharePlus.instance.share(
                          ShareParams(text: '$title\n$url'),
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.share_outlined, color: textColor),
                    ),
                  ),
                  AnimatedPress(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DownloadsScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.download_rounded, color: textColor),
                    ),
                  ),
                  AnimatedPress(
                    onTap: () {
                      browserProvider.reload();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.refresh_rounded, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? shortcut,
    bool showArrow = false,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final itemTextColor = textColor ?? theme.colorScheme.onSurface;

    return AnimatedPress(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: itemTextColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: itemTextColor, fontSize: 13),
              ),
            ),
            if (shortcut != null)
              Text(
                shortcut,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ?trailing,
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[500],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final browserProvider = Provider.of<BrowserProvider>(
      context,
      listen: false,
    );
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          Text(
            value ? "On" : "Off",
            style: TextStyle(
              color: value ? browserProvider.themeColor : Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: browserProvider.themeColor,
              activeTrackColor: browserProvider.themeColor.withValues(
                alpha: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildThemeModeSelector(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Theme Mode",
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModeOption(
                context,
                icon: Icons.light_mode_rounded,
                label: "Light",
                isSelected: browserProvider.themeMode == ThemeMode.light,
                onTap: () => browserProvider.updateThemeMode(ThemeMode.light),
              ),
              _buildModeOption(
                context,
                icon: Icons.dark_mode_rounded,
                label: "Dark",
                isSelected: browserProvider.themeMode == ThemeMode.dark,
                onTap: () => browserProvider.updateThemeMode(ThemeMode.dark),
              ),
              _buildModeOption(
                context,
                icon: Icons.brightness_auto_rounded,
                label: "System",
                isSelected: browserProvider.themeMode == ThemeMode.system,
                onTap: () => browserProvider.updateThemeMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeColor = Provider.of<BrowserProvider>(context).themeColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? themeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? themeColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? themeColor : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? themeColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
