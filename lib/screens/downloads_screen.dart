import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/download_service.dart';
import '../providers/browser_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    
    // Refresh history when an active download finishes
    DownloadService.activeDownloadsNotifier.addListener(_onActiveDownloadsChanged);
  }

  void _onActiveDownloadsChanged() {
    // If an item was moved to history, refresh the local list
    _loadDownloads();
  }

  @override
  void dispose() {
    DownloadService.activeDownloadsNotifier.removeListener(_onActiveDownloadsChanged);
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final downloads = await DownloadService.getHistory();
    if (mounted) {
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(DownloadItem item) async {
    await DownloadService.deleteFromHistory(item);
    _loadDownloads();
  }

  Future<void> _clearAll() async {
    await DownloadService.clearHistory();
    _loadDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BrowserProvider>(context);
    final themeColor = provider.themeColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Downloads", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_downloads.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text("Clear All", style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: ValueListenableBuilder<Map<int, ActiveDownload>>(
        valueListenable: DownloadService.activeDownloadsNotifier,
        builder: (context, activeDownloads, child) {
          if (_isLoading && activeDownloads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_downloads.isEmpty && activeDownloads.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeDownloads.isNotEmpty) ...[
                const Text(
                  "In Progress",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ...activeDownloads.values.map((active) => _buildActiveDownloadItem(active, themeColor)),
                const Divider(height: 32),
              ],
              if (_downloads.isNotEmpty) ...[
                const Text(
                  "History",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ..._downloads.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildDownloadItem(item, themeColor),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_for_offline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No downloads yet", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          const SizedBox(height: 8),
          Text("Files you download will appear here", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildActiveDownloadItem(ActiveDownload active, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getFileIcon(active.fileName), color: themeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active.total > 0 
                        ? "${_formatSize(active.received)} / ${_formatSize(active.total)}"
                        : "Downloading...",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => DownloadService.cancelDownload(active.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: active.progress > 0 ? active.progress : null,
              backgroundColor: themeColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(DownloadItem item, Color themeColor) {
    final dateStr = DateFormat('MMM d, yyyy • HH:mm').format(item.date);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getFileIcon(item.fileName), color: themeColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      if (item.size != null) ...[
                        Text(" • ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        Text(_formatSize(item.size!), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showItemMenu(item),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => OpenFile.open(item.path),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.withOpacity(0.1),
                  foregroundColor: themeColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Open"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.movie;
    if (['mp3', 'wav', 'm4a'].contains(ext)) return Icons.audiotrack;
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip;
    if (['apk'].contains(ext)) return Icons.android;
    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  void _showItemMenu(DownloadItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text("Share"),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(item.path)], text: item.fileName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete from history"),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.black),
              title: const Text("Delete from storage"),
              onTap: () {
                Navigator.pop(context);
                _deleteFromStorage(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFromStorage(DownloadItem item) async {
    final file = File(item.path);
    if (await file.exists()) {
      await file.delete();
    }
    await _deleteItem(item);
  }
}
