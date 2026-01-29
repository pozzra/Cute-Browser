import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class NotificationResponse {
  final int id;
  final String? actionId;
  final String? payload;

  NotificationResponse({required this.id, this.actionId, this.payload});
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final StreamController<NotificationResponse> _onActionStream = StreamController<NotificationResponse>.broadcast();
  static Stream<NotificationResponse> get onAction => _onActionStream.stream;

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.id != null) {
          _onActionStream.add(NotificationResponse(
            id: details.id!,
            actionId: details.actionId,
            payload: details.payload,
          ));
        }
      },
    );

    // Create high importance channel for progress
    const AndroidNotificationChannel updateChannel = AndroidNotificationChannel(
      'cute_browser_updates',
      'Browser Updates',
      description: 'Notifications for app updates and downloads',
      importance: Importance.high,
      showBadge: true,
    );

    // Create media playback channel
    const AndroidNotificationChannel mediaChannel = AndroidNotificationChannel(
      'cute_browser_media',
      'Media Playback',
      description: 'Notifications for video and audio playback',
      importance: Importance.max,
      showBadge: false,
      enableVibration: false,
      playSound: false,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    await androidPlugin?.createNotificationChannel(updateChannel);
    await androidPlugin?.createNotificationChannel(mediaChannel);
  }

  static Future<void> showMediaNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cute_browser_media',
      'Media Playback',
      channelDescription: 'Notifications for video and audio playback',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.transport,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> showDownloadProgress({
    required int id,
    required String title,
    required int progress,
    required int maxProgress,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cute_browser_updates',
      'Browser Updates',
      channelDescription: 'Notifications for app updates and downloads',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      autoCancel: false,
      actions: progress == maxProgress ? null : [
        const AndroidNotificationAction(
          'cancel_download',
          'Cancel',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      progress == maxProgress ? 'Download Complete' : 'Downloading... $progress%',
      notificationDetails,
      payload: 'downloads_screen',
    );
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
