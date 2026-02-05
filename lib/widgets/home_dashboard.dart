import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> shortcuts = [
    {
      'name': 'Google',
      'url': 'https://www.google.com',
      'icon': '🔍',
      'color': '0xFFFFB7B2',
    },
    {
      'name': 'YouTube',
      'url': 'https://www.youtube.com',
      'icon': '📺',
      'color': '0xFFFFE1AF',
    },
    {
      'name': 'Facebook',
      'url': 'https://www.facebook.com',
      'icon': '👥',
      'color': '0xFFB2E2F2',
    },
    {
      'name': 'Instagram',
      'url': 'https://www.instagram.com',
      'icon': '📸',
      'color': '0xFFE2B2F2',
    },
    {
      'name': 'Twitter',
      'url': 'https://www.twitter.com',
      'icon': '🐦',
      'color': '0xFFB2F2CC',
    },
    {
      'name': 'GitHub',
      'url': 'https://www.github.com',
      'icon': '💻',
      'color': '0xFFD1D1D1',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.isNotEmpty) {
      context.read<BrowserProvider>().loadUrl(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    return Container(
      width: double.infinity,
      color: browserProvider.themeColor.withValues(alpha: 0.08),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo or Header
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/image/logo.png',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  "CuteBrowser",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: browserProvider.adaptiveTextColor == Colors.white
                        ? Colors.white
                        : browserProvider.themeColor,
                    fontFamily: 'Outfit',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Spread a little sparkle today! ✨",
              style: TextStyle(
                color: browserProvider.adaptiveTextColor == Colors.white
                    ? Colors.white70
                    : CuteColors.lightText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: browserProvider.themeColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                decoration: InputDecoration(
                  hintText: "Search anything cute...",
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: browserProvider.themeColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: browserProvider.themeColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Shortcuts Grid
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Links",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: browserProvider.adaptiveTextColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.9,
              ),
              itemCount: browserProvider.shortcuts.length,
              itemBuilder: (context, index) {
                final shortcut = browserProvider.shortcuts[index];
                final color = Color(int.parse(shortcut.color));

                return GestureDetector(
                  onTap: () => browserProvider.loadUrl(shortcut.url),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Remove Shortcut?"),
                        content: Text(
                          "Do you want to remove ${shortcut.name}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              browserProvider.removeShortcut(index);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Remove",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                shortcut.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shortcut.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: browserProvider.adaptiveTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
