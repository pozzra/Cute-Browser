import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/ad_blocker_script.dart';
import '../utils/background_play_script.dart';
import '../services/notification_service.dart';
import '../services/download_service.dart';
import '../utils/google_login_fix_script.dart';
import 'dart:convert';
import 'dart:math';

class BrowserTab {
  late WebViewController controller;
  String currentUrl = "about:blank";
  double progress = 0;
  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;
  bool isHomePage = true;
  String title = "Home";

  // Callback to notify the provider when state changes in this tab
  final VoidCallback onStateChanged;
  final Function(String title, String url) onPageLoaded;
  final ValueGetter<bool>? shouldBlockAds;
  final ValueGetter<bool>? shouldEnableBackgroundPlay;
  final ValueGetter<bool>? shouldEnableDesktopMode;

  static const String desktopUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36";

  static const String mobileUserAgent =
      "Mozilla/5.0 (Linux; Android 14; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";

  final Function(Map<String, dynamic> event) onPlaybackEvent;

  BrowserTab({
    required this.onStateChanged,
    required this.onPageLoaded,
    required this.onPlaybackEvent,
    this.shouldBlockAds,
    this.shouldEnableBackgroundPlay,
    this.shouldEnableDesktopMode,
  }) {
    isHomePage =
        currentUrl == "https://www.google.com" || currentUrl == "about:blank";
    controller = WebViewController();
    if (!kIsWeb) {
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          this.progress = progress / 100;
          isLoading = progress != 100;
          onStateChanged();
        },
        onPageStarted: (String url) {
          isHomePage = url == "about:blank";
          currentUrl = url;
          isLoading = true;
          // Identity hardening
          controller.runJavaScript(googleLoginFixScript);
          onStateChanged();
        },
        onPageFinished: (String url) async {
          isLoading = false;
          currentUrl = url;
          title = (await controller.getTitle()) ?? "New Tab";
          await _checkNavigationHistory();
          // Add to history
          onPageLoaded(title, currentUrl);

          // Inject AdBlocker
          if (shouldBlockAds != null && shouldBlockAds!()) {
            controller.runJavaScript(adBlockerScript);
          }
          if (shouldEnableBackgroundPlay != null &&
              shouldEnableBackgroundPlay!()) {
            controller.runJavaScript(backgroundPlayScript);
          }
          // Identity hardening (run again after load)
          controller.runJavaScript(googleLoginFixScript);
          if (shouldEnableDesktopMode != null && shouldEnableDesktopMode!()) {
            controller.runJavaScript("""
                 var meta = document.querySelector('meta[name="viewport"]');
                 if (meta) {
                   meta.setAttribute('content', 'width=1280, initial-scale=0.25');
                 } else {
                   meta = document.createElement('meta');
                   meta.name = "viewport";
                   meta.content = "width=1280, initial-scale=0.25";
                   document.getElementsByTagName('head')[0].appendChild(meta);
                 }
               """);
          }

          onStateChanged();
        },
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          final url = request.url.toLowerCase();
          final downloadExtensions = [
            '.apk',
            '.zip',
            '.rar',
            '.pdf',
            '.mp4',
            '.mp3',
            '.exe',
            '.dmg',
            '.iso',
            '.7z',
            '.gz',
            '.deb',
          ];

          bool isDownload = downloadExtensions.any(
            (ext) => url.split('?').first.endsWith(ext),
          );

          if (isDownload) {
            String fileName = request.url.split("/").last.split("?").first;
            if (fileName.isEmpty) fileName = "download";

            DownloadService.downloadFile(url: request.url, fileName: fileName);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    controller.setBackgroundColor(const Color(0x00000000));

    // Aggressively ensure User-Agent is applied immediately after controller init
    updateWebViewSettings(initialUrl: currentUrl);

    if (!kIsWeb) {
      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      controller.addJavaScriptChannel(
        'PlaybackChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            onPlaybackEvent(data);
          } catch (e) {
            debugPrint("Error parsing playback message: $e");
          }
        },
      );
    }
    controller.loadRequest(Uri.parse(currentUrl));
    if (currentUrl != "about:blank") {
      isHomePage = false;
    }
  }

  void loadUrl(String url) {
    isLoading = true;
    isHomePage = false;
    onStateChanged();
    // Simple heuristic: if it contains space or no dots (and not localhost), it's a search.
    // Also check if it starts with http/https.
    if (!url.startsWith('http')) {
      if (url.contains(' ') || (!url.contains('.') && url != 'localhost')) {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      } else {
        url = 'https://$url';
      }
    }

    // Google Login Fix: Use Desktop UA and spoof X-Requested-With for Google login
    final bool isGoogleLogin = url.contains("accounts.google.com");
    final headers = <String, String>{};

    if (isGoogleLogin) {
      // Chrome Android package name - Google trusts this
      headers["X-Requested-With"] = "com.android.chrome";
      controller.setUserAgent(desktopUserAgent);
    } else if (url.contains("google.com") || url.contains("youtube.com")) {
      headers["X-Requested-With"] = "com.android.chrome";
    }

    controller.loadRequest(Uri.parse(url), headers: headers);
  }

  void updateWebViewSettings({String? initialUrl}) {
    final String url = initialUrl ?? currentUrl;
    final bool isGoogleLogin = url.contains("accounts.google.com");

    final useDesktopUA =
        (shouldEnableBackgroundPlay != null && shouldEnableBackgroundPlay!()) ||
        (shouldEnableDesktopMode != null && shouldEnableDesktopMode!()) ||
        isGoogleLogin;

    // Explicitly set User-Agent for both modes to ensure clean switch
    if (useDesktopUA) {
      controller.setUserAgent(desktopUserAgent);
    } else {
      // Use a high-quality mobile UA instead of null to bypass Google's "Insecure Browser" blocking
      controller.setUserAgent(mobileUserAgent);
    }

    // Only reload/apply JS if it's not the home page and not during init
    if (initialUrl == null && !isHomePage && currentUrl != "about:blank") {
      controller.reload();
    }
  }

  Future<void> _checkNavigationHistory() async {
    canGoBack = await controller.canGoBack();
    canGoForward = await controller.canGoForward();
  }

  void resumeMedia() {
    if (shouldEnableBackgroundPlay != null && shouldEnableBackgroundPlay!()) {
      controller.runJavaScript(
        "if(typeof syncAllVideos === 'function') syncAllVideos();",
      );
    }
  }

  Future<String> getPageContent() async {
    try {
      final result = await controller.runJavaScriptReturningResult(
        "document.body.innerText",
      );
      String text = result.toString();
      // Clean up the result if it's a quoted string from JS
      if (text.startsWith('"') && text.endsWith('"')) {
        text = text
            .substring(1, text.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n');
      }
      return "Title: $title\nURL: $currentUrl\n\nContent:\n$text";
    } catch (e) {
      return "Title: $title\nURL: $currentUrl";
    }
  }
}

class Bookmark {
  final String title;
  final String url;

  Bookmark({required this.title, required this.url});
}

class Shortcut {
  final String name;
  final String url;
  final String icon;
  final String color;

  Shortcut({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'icon': icon,
    'color': color,
  };

  factory Shortcut.fromJson(Map<String, dynamic> json) => Shortcut(
    name: json['name'] as String,
    url: json['url'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
  );
}

class BrowserProvider extends ChangeNotifier with WidgetsBindingObserver {
  final List<BrowserTab> _tabs = [];
  final List<Bookmark> _bookmarks = [];
  final List<Shortcut> _shortcuts = [];
  int _currentIndex = 0;

  bool get isSafeBrowsingEnabled => _isSafeBrowsingEnabled;
  bool _isSafeBrowsingEnabled = true;
  bool _isAppStarting = true;
  bool get isAppStarting => _isAppStarting;

  List<BrowserTab> get tabs => _tabs;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Shortcut> get shortcuts => _shortcuts;
  int get currentIndex => _currentIndex;
  BrowserTab get currentTab => _tabs[_currentIndex];

  bool get isSecureSite =>
      tabs.isNotEmpty && currentTab.currentUrl.startsWith('https://');

  // Delegate getters to current tab
  WebViewController get controller =>
      _tabs.isEmpty ? WebViewController() : currentTab.controller;
  double get progress => _tabs.isEmpty ? 0 : currentTab.progress;
  String get currentUrl => _tabs.isEmpty ? "" : currentTab.currentUrl;
  bool get isLoading => _tabs.isEmpty ? false : currentTab.isLoading;
  bool get canGoBack => _tabs.isEmpty ? false : currentTab.canGoBack;
  bool get canGoForward => _tabs.isEmpty ? false : currentTab.canGoForward;
  String get currentTitle => _tabs.isEmpty ? "" : currentTab.title;

  void _handleTabStateChange() {
    if (_isAppStarting && !isLoading) {
      _isAppStarting = false;
    }
    _saveTabs();
    notifyListeners();
  }

  BrowserProvider() {
    WidgetsBinding.instance.addObserver(this);

    // 1. Initialize with one default tab immediately so getters dont crash
    _tabs.add(
      BrowserTab(
        onStateChanged: _handleTabStateChange,
        onPageLoaded: addToHistory,
        onPlaybackEvent: _handlePlaybackEvent,
        shouldBlockAds: () => _isAdBlockEnabled,
        shouldEnableBackgroundPlay: () => _isBackgroundPlayEnabled,
        shouldEnableDesktopMode: () => _isDesktopMode,
      ),
    );
    requestNotificationPermission();
    _loadSettings().then((_) {
      initBackgroundMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("App LifeCycle State: $state");

    // Re-verify background mode when app goes to background
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_isBackgroundPlayEnabled) {
        _enableBackgroundMode();
        // Force resume all tabs if engine tried to pause
        for (var tab in _tabs) {
          tab.resumeMedia();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // When coming back to foreground, we don't force play.
      // The user will decide or the script will sync if needed.
      // This prevents "un-pausing" when the user just returns to the app.
    }
  }

  void addTab({String? url}) {
    _tabs.add(
      BrowserTab(
        onStateChanged: _handleTabStateChange,
        onPageLoaded: addToHistory,
        onPlaybackEvent: _handlePlaybackEvent,
        shouldBlockAds: () => _isAdBlockEnabled,
        shouldEnableBackgroundPlay: () => _isBackgroundPlayEnabled,
        shouldEnableDesktopMode: () => _isDesktopMode,
      ),
    );

    // Use provided URL, then favorite URL, then dashboard
    final String targetUrl =
        url ?? (_favoriteUrl.isNotEmpty ? _favoriteUrl : "about:blank");

    if (targetUrl != "about:blank") {
      _tabs.last.loadUrl(targetUrl);
    }

    _currentIndex = _tabs.length - 1;
    _saveTabs();
    notifyListeners();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) return; // Don't close the last tab

    _tabs.removeAt(index);

    if (_currentIndex >= index) {
      _currentIndex = 0.clamp(0, _tabs.length - 1);
    }
    _saveTabs();
    notifyListeners();
  }

  void closeAllTabs() {
    _tabs.clear();
    // Always keep at least one tab
    _tabs.add(
      BrowserTab(
        onStateChanged: () {
          _saveTabs();
          notifyListeners();
        },
        onPageLoaded: addToHistory,
        onPlaybackEvent: _handlePlaybackEvent,
        shouldBlockAds: () => _isAdBlockEnabled,
        shouldEnableBackgroundPlay: () => _isBackgroundPlayEnabled,
        shouldEnableDesktopMode: () => _isDesktopMode,
      ),
    );
    _currentIndex = 0;
    _saveTabs();
    notifyListeners();
  }

  void changeTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentIndex = index;
      _saveTabs();
      notifyListeners();
    }
  }

  void loadUrl(String url) {
    if (_tabs.isNotEmpty) {
      currentTab.loadUrl(url);
    }
  }

  Future<String> getPageContent() async {
    if (_tabs.isEmpty) return "";
    return await currentTab.getPageContent();
  }

  void reload() {
    if (_tabs.isNotEmpty) {
      currentTab.controller.reload();
    }
  }

  void goBack() async {
    if (_tabs.isNotEmpty && await currentTab.controller.canGoBack()) {
      currentTab.controller.goBack();
    }
  }

  void goForward() async {
    if (_tabs.isNotEmpty && await currentTab.controller.canGoForward()) {
      currentTab.controller.goForward();
    }
  }

  void goHome() {
    if (_tabs.isNotEmpty) {
      if (_favoriteUrl.isNotEmpty) {
        currentTab.isHomePage = false;
        currentTab.loadUrl(_favoriteUrl);
      } else {
        currentTab.isHomePage = true;
        currentTab.currentUrl = "about:blank";
        currentTab.controller.loadRequest(Uri.parse("about:blank"));
      }
      notifyListeners();
    }
  }

  void addBookmark(String title, String url) {
    if (!isBookmarked(url)) {
      _bookmarks.add(Bookmark(title: title, url: url));
      notifyListeners();
    }
  }

  void removeBookmark(String url) {
    _bookmarks.removeWhere((b) => b.url == url);
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  // --- History ---
  final List<Bookmark> _history =
      []; // Reusing Bookmark class for history items for simplicity
  List<Bookmark> get history => _history;

  void addToHistory(String title, String url) {
    // Avoid duplicates at the top
    if (_history.isNotEmpty && _history.first.url == url) return;

    _history.insert(0, Bookmark(title: title, url: url));
    if (_history.length > 100) {
      _history.removeLast();
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    // Also clear web cache/cookies
    await clearAllData();
  }

  Future<void> clearAllData() async {
    await controller.clearCache();
    await controller.clearLocalStorage();
    await WebViewCookieManager().clearCookies();
    notifyListeners();
  }

  // --- Settings / Theme ---
  Color _themeColor = const Color(0xFFFFB7B2); // Default Pastel Pink
  String? _backgroundImagePath;
  bool _isAdBlockEnabled = true;
  bool _isBackgroundPlayEnabled = false; // Default to false for phone interface
  bool _isDesktopMode = false;
  String _favoriteUrl = "";

  Color get themeColor => _themeColor;
  String? get backgroundImagePath => _backgroundImagePath;
  bool get isAdBlockEnabled => _isAdBlockEnabled;
  bool get isBackgroundPlayEnabled => _isBackgroundPlayEnabled;
  bool get isDesktopMode => _isDesktopMode;
  String get favoriteUrl => _favoriteUrl;
  Color get adaptiveTextColor =>
      _themeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor');
    if (colorValue != null) {
      _themeColor = Color(colorValue);
    }
    _isAdBlockEnabled = prefs.getBool('isAdBlockEnabled') ?? true;
    _isBackgroundPlayEnabled =
        prefs.getBool('isBackgroundPlayEnabled') ?? false;
    _isDesktopMode = prefs.getBool('isDesktopMode') ?? false;
    _isSafeBrowsingEnabled = prefs.getBool('isSafeBrowsingEnabled') ?? true;
    _favoriteUrl = prefs.getString('favoriteUrl') ?? "";

    // Load Shortcuts
    final shortcutsJson = prefs.getStringList('shortcuts');
    if (shortcutsJson != null) {
      _shortcuts.clear();
      _shortcuts.addAll(
        shortcutsJson.map((s) => Shortcut.fromJson(jsonDecode(s))),
      );
    } else {
      // Default shortcuts
      _shortcuts.addAll([
        Shortcut(
          name: 'Google',
          url: 'https://www.google.com',
          icon: '🔍',
          color: '0xFFFFB7B2',
        ),
        Shortcut(
          name: 'YouTube',
          url: 'https://www.youtube.com',
          icon: '📺',
          color: '0xFFFFE1AF',
        ),
        Shortcut(
          name: 'Facebook',
          url: 'https://www.facebook.com',
          icon: '👥',
          color: '0xFFB2E2F2',
        ),
        Shortcut(
          name: 'Instagram',
          url: 'https://www.instagram.com',
          icon: '📸',
          color: '0xFFE2B2F2',
        ),
        Shortcut(
          name: 'Twitter',
          url: 'https://www.twitter.com',
          icon: '🐦',
          color: '0xFFB2F2CC',
        ),
        Shortcut(
          name: 'GitHub',
          url: 'https://www.github.com',
          icon: '💻',
          color: '0xFFD1D1D1',
        ),
        Shortcut(
          name: 'Join Office',
          url: 'https://t.me/kun_amra',
          icon: '📢',
          color: '0xFFB2E2F2',
        ),
      ]);
      _saveShortcuts();
    }

    // Restore Tabs
    final savedUrls = prefs.getStringList('tabUrls');
    final savedIndex = prefs.getInt('currentIndex') ?? 0;

    if (savedUrls != null && savedUrls.isNotEmpty) {
      final List<BrowserTab> newTabs = [];
      for (var url in savedUrls) {
        newTabs.add(
          BrowserTab(
            onStateChanged: _handleTabStateChange,
            onPageLoaded: addToHistory,
            onPlaybackEvent: _handlePlaybackEvent,
            shouldBlockAds: () => _isAdBlockEnabled,
            shouldEnableBackgroundPlay: () => _isBackgroundPlayEnabled,
            shouldEnableDesktopMode: () => _isDesktopMode,
          ),
        );
        if (url != "about:blank") {
          newTabs.last.loadUrl(url);
        }
      }

      // Swap list atomically to avoid empty state crashes
      _tabs.clear();
      _tabs.addAll(newTabs);
      _currentIndex = savedIndex.clamp(0, _tabs.length - 1);
    } else {
      // If no tabs were saved, and we have a favorite URL, load it into the initial tab
      if (_favoriteUrl.isNotEmpty) {
        _tabs.first.loadUrl(_favoriteUrl);
      }
    }

    notifyListeners();
    initBackgroundMode();
  }

  void _saveTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = _tabs.map((t) => t.currentUrl).toList();
    await prefs.setStringList('tabUrls', urls);
    await prefs.setInt('currentIndex', _currentIndex);
  }

  void updateThemeColor(Color color) async {
    _themeColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.toARGB32());
  }

  void updateBackgroundImage(String? path) {
    _backgroundImagePath = path;
    notifyListeners();
  }

  void toggleAdBlock(bool value) async {
    _isAdBlockEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdBlockEnabled', value);
    reload();
  }

  void toggleBackgroundPlay(bool value) async {
    if (value) {
      await requestNotificationPermission();
    }
    _isBackgroundPlayEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBackgroundPlayEnabled', value);

    if (value) {
      await _enableBackgroundMode();
    } else {
      await _disableBackgroundMode();
    }

    // Update all tabs for User-Agent change
    for (var tab in _tabs) {
      tab.updateWebViewSettings();
    }
  }

  void toggleDesktopMode(bool value) async {
    _isDesktopMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDesktopMode', value);

    // Update all tabs for User-Agent change
    for (var tab in _tabs) {
      tab.updateWebViewSettings();
    }
  }

  void toggleSafeBrowsing(bool value) async {
    _isSafeBrowsingEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSafeBrowsingEnabled', value);
  }

  void updateFavoriteUrl(String url) async {
    _favoriteUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoriteUrl', url);
  }

  Future<void> _enableBackgroundMode() async {
    try {
      // 1. Keep CPU Awake (Foreground Service handles this on Android)
      // Removing WakelockPlus.enable() because it prevents the screen from locking.

      // 2. Audio Focus Request (CRITICAL for background play)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      if (await session.setActive(true)) {
        debugPrint("Audio session activated successfully.");
      }

      // 3. Start Foreground Service (Android)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Battery Optimization check
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          await Permission.ignoreBatteryOptimizations.request();
        }

        bool hasPermissions = await FlutterBackground.hasPermissions;
        if (hasPermissions) {
          await FlutterBackground.enableBackgroundExecution();
        } else {
          debugPrint("Background permissions not granted yet.");
        }
      }
    } catch (e) {
      debugPrint("Error enabling background mode: $e");
    }
  }

  Future<void> _disableBackgroundMode() async {
    try {
      await WakelockPlus.disable();
      if (!kIsWeb && FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (e) {
      debugPrint("Error disabling background mode: $e");
    }
  }

  Future<void> initBackgroundMode() async {
    // Re-apply state on startup
    if (_isBackgroundPlayEnabled) {
      await _enableBackgroundMode();
    }
  }

  Future<void> requestNotificationPermission() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }

      if (status.isGranted && _isBackgroundPlayEnabled) {
        await _enableBackgroundMode();
      }
    }
  }

  String _lastMediaTitle = "";
  bool _isCurrentlyPlaying = false;

  void _handlePlaybackEvent(Map<String, dynamic> event) {
    if (!_isBackgroundPlayEnabled) return;

    if (event['type'] == 'status') {
      bool playing = event['playing'] as bool;
      String title = event['title'] as String? ?? "Video";

      if (playing != _isCurrentlyPlaying || title != _lastMediaTitle) {
        _isCurrentlyPlaying = playing;
        _lastMediaTitle = title;

        if (playing) {
          NotificationService.showMediaNotification(
            id: 200,
            title: "Cute Browser - Playing",
            body: title,
          );
        } else {
          NotificationService.cancel(200);
        }
      }
    } else if (event['type'] == 'metadata') {
      String title = event['title'] as String? ?? _lastMediaTitle;
      _lastMediaTitle = title;
      if (_isCurrentlyPlaying) {
        NotificationService.showMediaNotification(
          id: 200,
          title: "Cute Browser - Playing",
          body: title,
        );
      }
    }
  }

  void removeShortcut(int index) {
    if (index >= 0 && index < _shortcuts.length) {
      _shortcuts.removeAt(index);
      _saveShortcuts();
      notifyListeners();
    }
  }

  void _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _shortcuts.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('shortcuts', jsonList);
  }

  void addShortcut(String name, String url, {String? icon}) {
    final List<String> randomIcons = [
      '✨',
      '🍭',
      '🌸',
      '🎀',
      '🧁',
      '🦄',
      '🍓',
      '🌈',
      '🍦',
      '🍡',
      '🦋',
      '🎈',
      '🎨',
      '🎭',
      '🧶',
    ];
    final List<String> randomColors = [
      '0xFFFFB7B2', // Pastel Pink
      '0xFFFFE1AF', // Pastel Orange
      '0xFFB2E2F2', // Pastel Blue
      '0xFFE2B2F2', // Pastel Purple
      '0xFFB2F2CC', // Pastel Green
      '0xFFD1D1D1', // Pastel Grey
    ];

    final random = Random();
    final String chosenIcon = (icon == null || icon.trim().isEmpty)
        ? randomIcons[random.nextInt(randomIcons.length)]
        : icon.trim();

    _shortcuts.add(
      Shortcut(
        name: name,
        url: url,
        icon: chosenIcon,
        color: randomColors[random.nextInt(randomColors.length)],
      ),
    );
    _saveShortcuts();
    notifyListeners();
  }

  void restoreDefaultShortcuts() {
    _shortcuts.clear();
    _shortcuts.addAll([
      Shortcut(
        name: 'Google',
        url: 'https://www.google.com',
        icon: '🔍',
        color: '0xFFFFB7B2',
      ),
      Shortcut(
        name: 'YouTube',
        url: 'https://www.youtube.com',
        icon: '📺',
        color: '0xFFFFE1AF',
      ),
      Shortcut(
        name: 'Facebook',
        url: 'https://www.facebook.com',
        icon: '👥',
        color: '0xFFB2E2F2',
      ),
      Shortcut(
        name: 'Instagram',
        url: 'https://www.instagram.com',
        icon: '📸',
        color: '0xFFE2B2F2',
      ),
      Shortcut(
        name: 'Twitter',
        url: 'https://www.twitter.com',
        icon: '🐦',
        color: '0xFFB2F2CC',
      ),
      Shortcut(
        name: 'Join Office',
        url: 'https://t.me/kun_amra',
        icon: '📢',
        color: '0xFFB5EAD7',
      ),
    ]);
    _saveShortcuts();
    notifyListeners();
  }
}
