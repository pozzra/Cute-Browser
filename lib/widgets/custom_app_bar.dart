import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../screens/bookmarks_screen.dart';
import 'animated_press.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

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
    // Only rebuild when the fields the bar shows actually change, so webview
    // progress updates don't repaint the whole bar on every tick.
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
    // Only update the URL field when a page finished loading and the user is
    // not typing, so we never clobber in-progress edits.
    if (!browserProvider.isLoading && !FocusScope.of(context).hasFocus) {
      if (browserProvider.isHomePage) {
        if (_urlController.text.isNotEmpty) _urlController.text = "";
      } else if (_urlController.text != browserProvider.currentUrl) {
        _urlController.text = browserProvider.currentUrl;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: browserProvider.themeColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 8,
            top: 6,
          ),
          child: Row(
            children: [
              _buildCircleButton(
                icon: Icons.home_rounded,
                onTap: goHome,
                iconColor: browserProvider.adaptiveTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _urlController,
                    onSubmitted: (value) {
                      loadUrl(value);
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search_rounded,
                            color: CuteColors.lightText,
                            size: 20,
                          ),
                          if (browserProvider.isSafeBrowsingEnabled && browserProvider.currentUrl != "about:blank") ...[
                            const SizedBox(width: 4),
                            Text(
                              browserProvider.isSecureSite
                                  ? "Safe"
                                  : "Not Safe",
                              style: TextStyle(
                                color: browserProvider.isSecureSite
                                    ? Colors.blue 
                                    : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
                                width: 10,
                                height: 10,
                                // child: CircularProgressIndicator( color: CuteColors.pastelPink)
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: CuteColors.lightText,
                              ),
                              onPressed: reload,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: browserProvider.themeColor.withValues(
                            alpha: 0.5,
                          ),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    style: const TextStyle(
                      color: CuteColors.darkText,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
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
