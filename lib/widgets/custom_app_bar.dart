import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../screens/bookmarks_screen.dart';

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
    final browserProvider = Provider.of<BrowserProvider>(context);

    // Only update text if the user is not potentially typing, or strictly on page finish.
    // simpler approach: Update text only if it's vastly different or on page load finish?
    // For this demo, let's keep it simple: sync when not focused or just sync on submit.
    // Actually, usually browsers update the URL bar when page changes.
    // We can check if the widget's current url in controller is different from provider's
    // AND the user isn't editing (no focus).
    // For simplicity: We will just update it when `browserProvider.currentUrl` changes
    // But we need to avoid overriding if user is typing.
    // Let's just set it in a listener or creating a new controller is fine if we accept the UX glitch.
    // BETTER FIX: Use `didUpdateWidget` or just setting it if (text != url).

    if (!browserProvider.isLoading && !FocusScope.of(context).hasFocus) {
      if (browserProvider.currentTab.isHomePage) {
        _urlController.text = "";
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
            bottom: 12,
            top: 10,
          ),
          child: Row(
            children: [
              _buildCircleButton(
                icon: Icons.home_rounded,
                onTap: browserProvider.goHome,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
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
                      browserProvider.loadUrl(value);
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
                          if (browserProvider.currentUrl != "about:blank") ...[
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
                              onPressed: browserProvider.reload,
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Provider.of<BrowserProvider>(context).adaptiveTextColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
