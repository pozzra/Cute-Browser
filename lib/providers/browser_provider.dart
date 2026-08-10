import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/ad_blocker_script.dart';
import '../utils/background_play_script.dart';
import '../services/notification_service.dart';
import '../services/download_service.dart';
import '../utils/google_login_fix_script.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

class BrowserTab {
  late WebViewController controller;
  String currentUrl = "about:blank";
  double progress = 0;
  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;
  bool isHomePage = true;
  String title = "Home";
  bool isPlaying = false;

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
    // Allow inline media playback on iOS via creation params (the old
    // setAllowsInlineMediaPlayback() method no longer exists in this version).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      controller = WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true),
      );
    } else {
      controller = WebViewController();
    }
    if (!kIsWeb) {
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          final double p = progress / 100;
          this.progress = p;
          isLoading = progress != 100;
          
          // Use ValueNotifier for progress to avoid full provider rebuilds
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
        onWebResourceError: (WebResourceError error) {
          debugPrint("WebResourceError: ${error.description}, type: ${error.errorType}, isForMainFrame: ${error.isForMainFrame}");
          // If it's a main frame error, we might want to show a custom error page or log it
          if (error.isForMainFrame ?? false) {
             isLoading = false;
             onStateChanged();
          }
        },
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
      // Note: inline media playback on iOS is configured via
      // WebKitWebViewCreationParams when the controller is created.

      controller.addJavaScriptChannel(
        'PlaybackChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'status') {
              isPlaying = data['playing'] ?? false;
            }
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
      // Chrome Android package name - Google trusts this for login
      headers["X-Requested-With"] = "com.android.chrome";
      controller.setUserAgent(desktopUserAgent);
    }

    controller.loadRequest(Uri.parse(url), headers: headers);
  }

  void updateWebViewSettings({String? initialUrl}) {
    final String url = initialUrl ?? currentUrl;
    final bool isGoogleLogin = url.contains("accounts.google.com");

    final useDesktopUA =
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
    if (!isPlaying) return;
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

  void togglePlay() {
    controller.runJavaScript("if(window.cutePlayAction) window.cutePlayAction('play');");
  }

  void nextVideo() {
    controller.runJavaScript("if(window.cutePlayAction) window.cutePlayAction('next');");
  }

  void previousVideo() {
    controller.runJavaScript("if(window.cutePlayAction) window.cutePlayAction('prev');");
  }

  void dispose() {
    try {
      // Clear the underlying native webview to stop background play and free memory
      controller.loadRequest(Uri.parse("about:blank"));
      controller.clearCache();
    } catch (e) {
      debugPrint("Error disposing tab: $e");
    }
  }
}

class Bookmark {
  final String title;
  final String url;

  Bookmark({required this.title, required this.url});

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    title: json['title'] as String,
    url: json['url'] as String,
  );
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
  
  final ValueNotifier<double> currentProgress = ValueNotifier(0);
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;

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

  Timer? _saveTimer;
  void _debounceSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveTabs();
    });
  }

  void _handleTabStateChange() {
    if (_isAppStarting && !isLoading) {
      _isAppStarting = false;
    }
    currentProgress.value = _tabs.isEmpty ? 0 : currentTab.progress;
    _debounceSave();
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
    _interruptionSubscription?.cancel();
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
      // When coming back to foreground, disable background service (hides notification)
      // The WebView is now active in foreground, so we don't need the service.
      if (_isBackgroundPlayEnabled) {
        _disableBackgroundMode();
      }
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

    _tabs[index].dispose();
    _tabs.removeAt(index);

    if (_currentIndex >= index) {
      _currentIndex = 0.clamp(0, _tabs.length - 1);
    }
    _saveTabs();
    notifyListeners();
  }

  void closeAllTabs() {
    for (var tab in _tabs) {
      tab.dispose();
    }
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
      _saveBookmarks();
      notifyListeners();
    }
  }

  void removeBookmark(String url) {
    _bookmarks.removeWhere((b) => b.url == url);
    _saveBookmarks();
    notifyListeners();
  }

  void _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _bookmarks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('bookmarks', jsonList);
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
    if (_history.length > 500) { // Increased limit for better user research
      _history.removeLast();
    }
    _saveHistory();
    notifyListeners();
  }

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      _saveHistory();
      notifyListeners();
    }
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _history.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('history', jsonList);
  }

  Future<void> clearHistory() async {
    _history.clear();
    _saveHistory();
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
  ThemeMode _themeMode = ThemeMode.system;
  String _favoriteUrl = "";

  Color get themeColor => _themeColor;
  String? get backgroundImagePath => _backgroundImagePath;
  bool get isAdBlockEnabled => _isAdBlockEnabled;
  bool get isBackgroundPlayEnabled => _isBackgroundPlayEnabled;
  bool get isDesktopMode => _isDesktopMode;
  ThemeMode get themeMode => _themeMode;
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
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
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

    // Load History
    final historyJson = prefs.getStringList('history');
    if (historyJson != null) {
      _history.clear();
      _history.addAll(historyJson.map((h) => Bookmark.fromJson(jsonDecode(h))));
    }

    // Load Bookmarks
    final bookmarksJson = prefs.getStringList('bookmarks');
    if (bookmarksJson != null) {
      _bookmarks.clear();
      _bookmarks.addAll(bookmarksJson.map((b) => Bookmark.fromJson(jsonDecode(b))));
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
      for (var tab in _tabs) {
        tab.dispose();
      }
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

  void updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
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
    reload();
  }

  void updateFavoriteUrl(String url) async {
    _favoriteUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoriteUrl', url);
  }

  Future<void> _enableBackgroundMode() async {
    try {
      // 1. Audio Session Request & Interruption Handling
      final session = await AudioSession.instance;
      // Use 'speech' or 'music' configuration. 'music' is better for YouTube/Streaming.
      await session.configure(const AudioSessionConfiguration.music());
      
      await _interruptionSubscription?.cancel();
      _interruptionSubscription = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Mobile OS requested pause, WebView manages this via MediaSession
              break;
            case AudioInterruptionType.duck:
              // Lower volume (handled by OS)
              break;
          }
        } else {
          if (event.type == AudioInterruptionType.pause) {
            // Re-activate session and resume all videos after interruption ends
            session.setActive(true).then((_) {
               for (var tab in _tabs) {
                  tab.resumeMedia();
               }
            });
          }
        }
      });

      if (await session.setActive(true)) {
        debugPrint("CuteBrowser: Audio session activated.");
      }

      // 2. Start Foreground Service & Keep Alive (Mobile Only)
      if (!kIsWeb) {
        // Prevent CPU Sleep
        await WakelockPlus.enable();

        if (defaultTargetPlatform == TargetPlatform.android) {
          // Request battery optimization ignore to prevent 5-min killing
          if (await Permission.ignoreBatteryOptimizations.isDenied) {
            await Permission.ignoreBatteryOptimizations.request();
          }

          if (await FlutterBackground.hasPermissions) {
            await FlutterBackground.enableBackgroundExecution();
            debugPrint("CuteBrowser: Android Background Mode Enabled (Foreground Service)");
          }
        }
      }
    } catch (e) {
      debugPrint("Error enabling background mode: $e");
    }
  }

  Future<void> _disableBackgroundMode() async {
    try {
      // Do NOT cancel interruption subscription, we still want to handle phone calls in foreground!
      
      await WakelockPlus.disable();
      if (!kIsWeb && FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
      
      // Do NOT deactivate audio session, as we are likely still playing media in foreground!
      // final session = await AudioSession.instance;
      // await session.setActive(false);
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

  bool get isCurrentlyPlaying => _isCurrentlyPlaying;
  String get lastMediaTitle => _lastMediaTitle;

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
    notifyListeners();
  }

  void togglePlay() {
    currentTab.togglePlay();
  }

  void nextVideo() {
    currentTab.nextVideo();
  }

  void previousVideo() {
    currentTab.previousVideo();
  }
}
