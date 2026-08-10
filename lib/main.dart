import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme.dart';
import 'providers/browser_provider.dart';
import 'screens/browser_home.dart';

import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';
import 'services/download_service.dart';
import 'services/ai_service.dart';
import 'services/update_service.dart';
import 'screens/downloads_screen.dart';

// Same scroll feel on Android and iOS (no bouncing on iOS).
class _UniformScrollBehavior extends MaterialScrollBehavior {
  const _UniformScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service configurations if on Android/iOS
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Cute Browser",
      notificationText: "Background Play Service Active",
      notificationImportance: AndroidNotificationImportance.max,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);
    await NotificationService.init();
    DownloadService.init();
    await AiService.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
      ],
      child: const CuteBrowserApp(),
    ),
  );
}

class CuteBrowserApp extends StatefulWidget {
  const CuteBrowserApp({super.key});

  @override
  State<CuteBrowserApp> createState() => _CuteBrowserAppState();
}

class _CuteBrowserAppState extends State<CuteBrowserApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPromptUpdate(context, silent: true);
    });
  }

  void _setupNotificationListener() {
    NotificationService.onAction.listen((response) {
      if (response.payload == 'downloads_screen') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const DownloadsScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final isDark = browserProvider.themeMode == ThemeMode.dark ||
        (browserProvider.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Keep the status bar text readable and identical on Android & iOS.
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Cute Browser',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _UniformScrollBehavior(),
      theme: CuteTheme.themeData,
      darkTheme: CuteTheme.darkThemeData,
      themeMode: browserProvider.themeMode,
      home: const BrowserHome(),
    );
  }
}
