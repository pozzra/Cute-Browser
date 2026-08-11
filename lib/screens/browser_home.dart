import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
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
    // Security Interceptor Logic — only schedule a check when a new unsafe
    // page is actually showing (avoids a post-frame callback on every rebuild).
    final provider = context.read<BrowserProvider>();
    final bool shouldCheckSecurity =
        provider.tabs.isNotEmpty &&
        provider.isSafeBrowsingEnabled &&
        !provider.isSecureSite &&
        !provider.currentTab.isHomePage &&
        provider.currentUrl != "about:blank" &&
        provider.currentUrl != _lastWarnedUrl;
    if (shouldCheckSecurity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = context.read<BrowserProvider>();
        _lastWarnedUrl = p.currentUrl;
        _showSecurityAlert(context, p);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          Selector<BrowserProvider, String?>(
            selector: (_, provider) => provider.backgroundImagePath,
            builder: (context, path, _) {
              if (path == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Column(
            children: [
              Consumer<BrowserProvider>(
                builder: (context, provider, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: provider.currentProgress,
                    builder: (context, progress, child) {
                      if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        color: provider.themeColor,
                        minHeight: 2.5,
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: Selector<BrowserProvider, int>(
                  selector: (_, provider) => provider.currentIndex,
                  builder: (context, currentIndex, _) {
                    return Selector<BrowserProvider, int>(
                      selector: (_, provider) => provider.tabs.length,
                      builder: (context, tabsLength, _) {
                        final provider = context.read<BrowserProvider>();
                        if (provider.tabs.isEmpty) {
                          return Container(
                            color: provider.themeColor.withValues(alpha: 0.1),
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
                                    color: provider.themeColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return RepaintBoundary(
                          child: IndexedStack(
                            index: currentIndex,
                            children: provider.tabs.map((tab) {
                              if (tab.isHomePage) {
                                return const HomeDashboard();
                              } else {
                                return RepaintBoundary(
                                  child: WebViewWidget(controller: tab.controller),
                                );
                              }
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Consumer<BrowserProvider>(
            builder: (context, provider, _) {
              if (provider.isAppStarting &&
                  provider.isLoading &&
                  provider.tabs.isNotEmpty &&
                  !provider.currentTab.isHomePage) {
                return Container(
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
                          color: provider.themeColor,
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
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomControls(),
    );
  }
}
