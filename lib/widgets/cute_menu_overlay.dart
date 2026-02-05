import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../screens/history_screen.dart';
import '../screens/bookmarks_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/update_service.dart';
import '../screens/downloads_screen.dart';
import '../screens/ai_chat_screen.dart';

class CuteMenuOverlay extends StatelessWidget {
  const CuteMenuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final backgroundColor = Colors.white;
    final dividerColor = Colors.grey[200];

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
            _buildMenuItem(
              context,
              icon: Icons.auto_awesome_outlined,
              title: "Cute AI",
              textColor: browserProvider.themeColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              },
            ),
            Divider(color: dividerColor),
            // Expanded Settings Section
            _buildThemeColorSelector(context),
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
            _buildMenuItem(
              context,
              icon: Icons.star_rounded,
              title: "Set current as Favorite",
              onTap: () {
                if (browserProvider.currentUrl.isNotEmpty &&
                    browserProvider.currentUrl != "about:blank") {
                  browserProvider.updateFavoriteUrl(browserProvider.currentUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Current page set as favorite! 💖"),
                    ),
                  );
                }
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.edit_note_rounded,
              title: "Edit Favorite URL",
              onTap: () => _showFavoriteDialog(context, browserProvider),
            ),
            Divider(color: dividerColor),
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
              icon: Icons.construction_outlined,
              title: "Set as default browser / Info",
              onTap: () async {
                final url = Uri.parse("https://t.me/kun_amra");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      browserProvider.goBack();
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DownloadsScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      browserProvider.reload();
                      Navigator.pop(context);
                    },
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
    final itemTextColor = textColor ?? CuteColors.darkText;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: itemTextColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: itemTextColor, fontSize: 14),
              ),
            ),
            if (shortcut != null)
              Text(
                shortcut,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            if (trailing != null) trailing,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: CuteColors.darkText, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: CuteColors.darkText, fontSize: 14),
            ),
          ),
          Text(
            value ? "On" : "Off",
            style: TextStyle(
              color: value ? browserProvider.themeColor : Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: browserProvider.themeColor,
              activeTrackColor: browserProvider.themeColor.withValues(
                alpha: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorSelector(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final List<Color> themeColors = [
      CuteColors.pastelPink,
      CuteColors.mintGreen,
      CuteColors.lavender,
      CuteColors.softPurple,
      Colors.blueAccent.withValues(alpha: 0.5),
      Colors.orangeAccent.withValues(alpha: 0.5),
      Colors.tealAccent.withValues(alpha: 0.5),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Theme Color",
            style: TextStyle(
              color: CuteColors.darkText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...themeColors.map((color) {
                  final isSelected = browserProvider.themeColor == color;
                  return GestureDetector(
                    onTap: () => browserProvider.updateThemeColor(color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black54, width: 2)
                            : null,
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pick a color!'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: browserProvider.themeColor,
                            onColorChanged: (color) =>
                                browserProvider.updateThemeColor(color),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.blue, Colors.green],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: const Icon(
                      Icons.colorize,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFavoriteDialog(BuildContext context, BrowserProvider provider) {
    final controller = TextEditingController(text: provider.favoriteUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text("Set Favorite Web Page"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "https://example.com",
              labelText: "URL",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                provider.updateFavoriteUrl(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
