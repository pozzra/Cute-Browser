import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DownloadItem {
  final String fileName;
  final String url;
  final String path;
  final DateTime date;
  final int? size;

  DownloadItem({
    required this.fileName,
    required this.url,
    required this.path,
    required this.date,
    this.size,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'url': url,
    'path': path,
    'date': date.toIso8601String(),
    'size': size,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    fileName: json['fileName'],
    url: json['url'],
    path: json['path'],
    date: DateTime.parse(json['date']),
    size: json['size'],
  );
}

class ActiveDownload {
  final int id;
  final String fileName;
  double progress;
  int received;
  int total;

  ActiveDownload({
    required this.id,
    required this.fileName,
    this.progress = 0,
    this.received = 0,
    this.total = 0,
  });
}

class DownloadService {
  static final Dio _dio = Dio();
  static final Map<int, CancelToken> _activeDownloads = {};
  static final ValueNotifier<Map<int, ActiveDownload>> activeDownloadsNotifier = ValueNotifier({});

  static void init() {
    NotificationService.onAction.listen((response) {
      if (response.actionId == 'cancel_download') {
        cancelDownload(response.id);
      }
    });
  }

  static void cancelDownload(int id) {
    if (_activeDownloads.containsKey(id)) {
      _activeDownloads[id]!.cancel("User cancelled");
      _activeDownloads.remove(id);
      
      // Update notifier
      final current = Map<int, ActiveDownload>.from(activeDownloadsNotifier.value);
      current.remove(id);
      activeDownloadsNotifier.value = current;

      NotificationService.cancel(id);
    }
  }

  static void registerActiveDownload(int id, CancelToken token, {String fileName = "Download"}) {
    _activeDownloads[id] = token;
    final current = Map<int, ActiveDownload>.from(activeDownloadsNotifier.value);
    current[id] = ActiveDownload(id: id, fileName: fileName);
    activeDownloadsNotifier.value = current;
  }

  static void unregisterActiveDownload(int id) {
    _activeDownloads.remove(id);
    final current = Map<int, ActiveDownload>.from(activeDownloadsNotifier.value);
    current.remove(id);
    activeDownloadsNotifier.value = current;
  }

  static Future<void> downloadFile({
    required String url,
    required String fileName,
    BuildContext? context,
  }) async {
    final int notificationId = url.hashCode % 100000;
    final cancelToken = CancelToken();
    registerActiveDownload(notificationId, cancelToken, fileName: fileName);

    try {
      // 1. Request Storage Permissions
      if (Platform.isAndroid) {
         if (await Permission.storage.isDenied) {
           await Permission.storage.request();
         }
      }

      // 2. Prepare Save Path
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final downloadsDir = Directory("${dir.path}/Downloads");
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final savePath = "${downloadsDir.path}/$fileName";

      // 3. Start Download
      final int notificationId = url.hashCode % 100000;
      
      NotificationService.showDownloadProgress(
        id: notificationId,
        title: "Starting download",
        progress: 0,
        maxProgress: 100,
      );

      int? fileSize;

      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            fileSize = total;
            int progress = ((received / total) * 100).toInt();
            
            // Update Notification
            NotificationService.showDownloadProgress(
              id: notificationId,
              title: "Downloading $fileName",
              progress: progress,
              maxProgress: 100,
            );

            // Update App Notifier
            final current = Map<int, ActiveDownload>.from(activeDownloadsNotifier.value);
            if (current.containsKey(notificationId)) {
               current[notificationId]!.progress = progress / 100;
               current[notificationId]!.received = received;
               current[notificationId]!.total = total;
               activeDownloadsNotifier.value = current;
            }
          }
        },
      );

      // 4. Finalize
      unregisterActiveDownload(notificationId);
      await NotificationService.cancel(notificationId);
      NotificationService.showMediaNotification( // Reusing for completion
        id: notificationId + 1,
        title: "Download Complete ✅",
        body: fileName,
      );

      if (context != null && context.mounted) {
        _showOpenDialog(context, savePath, fileName);
      }

      // 5. Save to History
      await saveToHistory(DownloadItem(
        fileName: fileName,
        url: url,
        path: savePath,
        date: DateTime.now(),
        size: fileSize,
      ));

    } catch (e) {
      unregisterActiveDownload(notificationId);
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint("Download cancelled by user.");
        return;
      }
      debugPrint("Download failed: $e");
      NotificationService.showMediaNotification(
        id: url.hashCode % 100000,
        title: "Download Failed ❌",
        body: "Could not download $fileName",
      );
    }
  }

  static void _showOpenDialog(BuildContext context, String path, String fileName) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Download Complete"),
        content: Text("Finished downloading $fileName. Would you like to open it?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await OpenFile.open(path);
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  static Future<void> saveToHistory(DownloadItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('download_history') ?? [];
    
    // Convert to JSON and prepend
    final itemJson = jsonEncode(item.toJson());
    
    // Avoid exact duplicates (same URL and path) within the same minute
    history.insert(0, itemJson);
    
    if (history.length > 50) history.removeLast();
    await prefs.setStringList('download_history', history);
  }

  static Future<List<DownloadItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('download_history') ?? [];
    return history.map((e) => DownloadItem.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> deleteFromHistory(DownloadItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('download_history') ?? [];
    history.removeWhere((e) {
      final decoded = DownloadItem.fromJson(jsonDecode(e));
      return decoded.url == item.url && decoded.date == item.date;
    });
    await prefs.setStringList('download_history', history);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('download_history');
  }
}
