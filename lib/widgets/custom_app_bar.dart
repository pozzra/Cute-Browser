import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../screens/bookmarks_screen.dart';
import 'animated_press.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BrowserProvider, _AppBarSnapshot>(
      selector: (_, p) => _AppBarSnapshot(
        themeColor: p.themeColor,
        isLoading: p.isLoading,
        currentUrl: p.currentUrl,
        isHomePage: p.currentTab.isHomePage,
        isSafeBrowsingEnabled: p.isSafeBrowsingEnabled,
        isSecureSite: p.isSecureSite,
        adaptiveTextColor: p.adaptiveTextColor,
      ),
      builder: (context, snapshot, _) {
        final actions = Provider.of<BrowserProvider>(context, listen: false);
        return _buildBar(
          context,
          snapshot,
          actions.goHome,
          actions.reload,
          actions.loadUrl,
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    _AppBarSnapshot browserProvider,
    VoidCallback goHome,
    VoidCallback reload,
    ValueChanged<String> loadUrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!browserProvider.isLoading && !FocusScope.of(context).hasFocus) {
      if (browserProvider.isHomePage) {
        if (_urlController.text.isNotEmpty) _urlController.text = "";
      } else if (_urlController.text != browserProvider.currentUrl) {
        _urlController.text = browserProvider.currentUrl;
      }
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? CuteColors.surfaceDark : CuteColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? CuteColors.glassBorderDark : CuteColors.glassBorderLight,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.home_rounded,
                    onTap: goHome,
                    iconColor: browserProvider.adaptiveTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _urlController,
                        onSubmitted: (value) {
                          loadUrl(value);
                          FocusScope.of(context).unfocus();
                        },
                        style: TextStyle(
                          color: browserProvider.adaptiveTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search or enter URL...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              Icon(
                                Icons.search_rounded,
                                color: CuteColors.primary,
                                size: 20,
                              ),
                              if (browserProvider.isSafeBrowsingEnabled && browserProvider.currentUrl != "about:blank") ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: browserProvider.isSecureSite
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    browserProvider.isSecureSite ? "🔒" : "⚠️",
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                            ],
                          ),
                          suffixIcon: browserProvider.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: CuteColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: browserProvider.adaptiveTextColor.withValues(alpha: 0.6),
                                  ),
                                  onPressed: reload,
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    icon: Icons.bookmark_border_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                      );
                    },
                    iconColor: browserProvider.adaptiveTextColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }
}

class _AppBarSnapshot {
  final Color themeColor;
  final bool isLoading;
  final String currentUrl;
  final bool isHomePage;
  final bool isSafeBrowsingEnabled;
  final bool isSecureSite;
  final Color adaptiveTextColor;

  const _AppBarSnapshot({
    required this.themeColor,
    required this.isLoading,
    required this.currentUrl,
    required this.isHomePage,
    required this.isSafeBrowsingEnabled,
    required this.isSecureSite,
    required this.adaptiveTextColor,
  });

  @override
  bool operator ==(Object other) =>
      other is _AppBarSnapshot &&
      other.themeColor == themeColor &&
      other.isLoading == isLoading &&
      other.currentUrl == currentUrl &&
      other.isHomePage == isHomePage &&
      other.isSafeBrowsingEnabled == isSafeBrowsingEnabled &&
      other.isSecureSite == isSecureSite &&
      other.adaptiveTextColor == adaptiveTextColor;

  @override
  int get hashCode => Object.hash(
        themeColor,
        isLoading,
        currentUrl,
        isHomePage,
        isSafeBrowsingEnabled,
        isSecureSite,
        adaptiveTextColor,
      );
}
