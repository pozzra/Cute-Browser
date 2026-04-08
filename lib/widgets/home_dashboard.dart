import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return "Good Night 🌙";
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 17) return "Good Afternoon 🌤️";
    if (hour < 21) return "Good Evening ✨";
    return "Good Night 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [Colors.black, Colors.black87, browserProvider.themeColor.withValues(alpha: 0.1)]
            : [Colors.white, browserProvider.themeColor.withValues(alpha: 0.05), browserProvider.themeColor.withValues(alpha: 0.15)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo or Header with Animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: browserProvider.themeColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/image/logo.png',
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: browserProvider.themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.auto_awesome, color: browserProvider.themeColor, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: browserProvider.adaptiveTextColor == Colors.white 
                            ? Colors.white 
                            : CuteColors.darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Spread a little sparkle today! ✨",
                      style: TextStyle(
                        color: browserProvider.adaptiveTextColor == Colors.white
                            ? Colors.white70
                            : CuteColors.lightText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Glassmorphism Search Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _onSearch,
                      decoration: InputDecoration(
                        hintText: "Search anything cute...",
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: browserProvider.themeColor,
                          size: 26,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Shortcuts Grid with entry animation
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: browserProvider.themeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Quick Links",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: browserProvider.adaptiveTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildStaggeredGrid(browserProvider),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredGrid(BrowserProvider browserProvider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: browserProvider.shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = browserProvider.shortcuts[index];
        final color = Color(int.parse(shortcut.color));

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              browserProvider.loadUrl(shortcut.url);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showRemoveDialog(context, browserProvider, shortcut, index);
            },
            child: Column(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
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
                    fontSize: 11,
                    color: browserProvider.adaptiveTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, BrowserProvider provider, dynamic shortcut, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Shortcut?"),
        content: Text("Do you want to remove ${shortcut.name} from your quick links?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep it"),
          ),
          TextButton(
            onPressed: () {
              provider.removeShortcut(index);
              Navigator.pop(context);
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
