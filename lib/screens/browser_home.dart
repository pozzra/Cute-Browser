import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/home_dashboard.dart';

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  String? _lastWarnedUrl;

  void _showSecurityAlert(BuildContext context, BrowserProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Website Not Safe"),
          ],
        ),
        content: const Text(
          "This website does not use a secure connection (HTTPS). Your data could be at risk.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.goHome(); // Safe exit
            },
            child: const Text(
              "Leave Website",
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Proceed Anyway",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    // Security Interceptor Logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (browserProvider.isSafeBrowsingEnabled &&
          !browserProvider.isSecureSite &&
          !browserProvider.currentTab.isHomePage &&
          browserProvider.currentUrl != "about:blank" &&
          browserProvider.currentUrl != _lastWarnedUrl) {
        _lastWarnedUrl = browserProvider.currentUrl;
        _showSecurityAlert(context, browserProvider);
      }
    });

    return Scaffold(
      backgroundColor: CuteColors.cream,
      extendBodyBehindAppBar: false,
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          if (browserProvider.backgroundImagePath != null)
            Positioned.fill(
              child: Image.file(
                File(browserProvider.backgroundImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          Column(
            children: [
              if (browserProvider.isLoading)
                LinearProgressIndicator(
                  value: browserProvider.progress,
                  backgroundColor: Colors.transparent,
                  color: browserProvider.themeColor,
                  minHeight: 2,
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                  child: browserProvider.tabs.isEmpty
                      ? Container(
                          color: browserProvider.themeColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/image/logo.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                CircularProgressIndicator(
                                  color: browserProvider.themeColor,
                                ),
                              ],
                            ),
                          ),
                        )
                      : IndexedStack(
                          index: browserProvider.currentIndex,
                          children: browserProvider.tabs.map((tab) {
                            if (tab.isHomePage) {
                              return const HomeDashboard();
                            } else {
                              return WebViewWidget(controller: tab.controller);
                            }
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
          if (browserProvider.isAppStarting &&
              browserProvider.isLoading &&
              browserProvider.tabs.isNotEmpty &&
              !browserProvider.currentTab.isHomePage)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/image/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CircularProgressIndicator(
                      color: browserProvider.themeColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomControls(),
    );
  }
}
