import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import 'history_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    // Seven preset colors
    final List<Color> themeColors = [
      CuteColors.pastelPink,
      CuteColors.mintGreen,
      CuteColors.lavender,
      CuteColors.softPurple,
      Colors.blueAccent.withValues(alpha: 0.5),
      Colors.orangeAccent.withValues(alpha: 0.5),
      Colors.tealAccent.withValues(alpha: 0.5),
    ];

    return Scaffold(
      backgroundColor: CuteColors.cream,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: browserProvider.adaptiveTextColor)),
        backgroundColor: browserProvider.themeColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: browserProvider.adaptiveTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(context, "Appearance"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Theme Color", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...themeColors.map((color) {
                      return GestureDetector(
                        onTap: () => browserProvider.updateThemeColor(color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: browserProvider.themeColor == color
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
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Pick a color!'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: browserProvider.themeColor,
                                  onColorChanged: (color) {
                                    browserProvider.updateThemeColor(color);
                                  },
                                ),
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  child: const Text('Got it'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 40, 
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.red, Colors.blue, Colors.green]),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: const Icon(Icons.colorize, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, "General"),
          const SizedBox(height: 10),
           Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: CuteColors.darkText),
                  title: const Text("Browsing History"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("Block Ads"),
                  subtitle: const Text("Hide common ads on webpages"),
                  secondary: const Icon(Icons.block_rounded, color: CuteColors.darkText),
                  value: browserProvider.isAdBlockEnabled,
                  activeThumbColor: browserProvider.themeColor,
                  onChanged: (value) {
                     browserProvider.toggleAdBlock(value);
                  },
                ),
                SwitchListTile(
                  title: const Text("Background Play"),
                  subtitle: const Text("Keep audio playing when screen is off (YouTube)"),
                  secondary: const Icon(Icons.music_note_rounded, color: CuteColors.darkText),
                  value: browserProvider.isBackgroundPlayEnabled,
                  activeThumbColor: browserProvider.themeColor,
                  onChanged: (value) {
                     browserProvider.toggleBackgroundPlay(value);
                  },
                ),
                SwitchListTile(
                  title: const Text("Desktop Mode"),
                  subtitle: const Text("Request desktop version of websites"),
                  secondary: const Icon(Icons.desktop_mac_rounded, color: CuteColors.darkText),
                  value: browserProvider.isDesktopMode,
                  activeThumbColor: browserProvider.themeColor,
                  onChanged: (value) {
                     browserProvider.toggleDesktopMode(value);
                  },
                ),
                SwitchListTile(
                  title: const Text("Safe Browsing"),
                  subtitle: const Text("Alert when a website is not safe (HTTP)"),
                  secondary: const Icon(Icons.security_rounded, color: CuteColors.darkText),
                  value: browserProvider.isSafeBrowsingEnabled,
                  activeThumbColor: browserProvider.themeColor,
                  onChanged: (value) {
                     browserProvider.toggleSafeBrowsing(value);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: CuteColors.darkText),
                  title: const Text("Favorite Web Page"),
                  subtitle: Text(browserProvider.favoriteUrl.isEmpty ? "None (Loads Dashboard)" : browserProvider.favoriteUrl),
                  trailing: const Icon(Icons.edit_rounded, size: 20),
                  onTap: () {
                    _showFavoriteDialog(context, browserProvider);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_to_home_screen_rounded, color: CuteColors.darkText),
                  title: const Text("Set Current Page as Favorite"),
                  subtitle: const Text("Quickly set the active tab as your home"),
                  onTap: () {
                    if (browserProvider.currentUrl.isNotEmpty && browserProvider.currentUrl != "about:blank") {
                      browserProvider.updateFavoriteUrl(browserProvider.currentUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Current page set as favorite! 💖")),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Can't favorite the home dashboard! ✨")),
                      );
                    }
                  },
                ),
                const Divider(), 
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: CuteColors.darkText),
                  title: const Text("About Cute Browser"),
                   trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                   onTap: () => _showAboutDialog(context, browserProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, BrowserProvider browserProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                'assets/image/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.star_rounded, size: 30, color: browserProvider.themeColor),
              ),
            ),
            const SizedBox(width: 10),
            const Text("Cute Browser"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Text("Version: 2.0.0", style: TextStyle(color: CuteColors.lightText, fontSize: 13)),
            // const SizedBox(height: 15),
            const Text("The cutest browser in the world!💖"),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse("https://t.me/kun_amra");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Telegram: Admin",
                style: TextStyle(
                  color: Colors.blue, 
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "© ${DateTime.now().year} by KUN AMRA",
              style: const TextStyle(fontSize: 12, color: CuteColors.lightText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: browserProvider.themeColor)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final browserProvider = Provider.of<BrowserProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: browserProvider.adaptiveTextColor
        )
      ),
    );
  }
}
