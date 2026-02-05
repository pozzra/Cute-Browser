import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../services/download_service.dart';
import '../theme/colors.dart';

class VideoDownloaderScreen extends StatefulWidget {
  const VideoDownloaderScreen({super.key});

  @override
  State<VideoDownloaderScreen> createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;

  void _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please paste a video link first! ✨")),
      );
      return;
    }

    if (!url.startsWith("http")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid link format! ❌")));
      return;
    }

    setState(() => _isDownloading = true);

    String fileName = url.split('/').last.split('?').first;
    if (fileName.isEmpty || !fileName.contains('.')) {
      fileName = "video_${DateTime.now().millisecondsSinceEpoch}.mp4";
    }

    await DownloadService.downloadFile(
      url: url,
      fileName: fileName,
      context: context,
    );

    setState(() => _isDownloading = false);
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    return Scaffold(
      backgroundColor: CuteColors.cream,
      appBar: AppBar(
        title: Text(
          "Video Downloader",
          style: TextStyle(color: browserProvider.adaptiveTextColor),
        ),
        backgroundColor: browserProvider.themeColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: browserProvider.adaptiveTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: browserProvider.themeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_rounded,
                    size: 64,
                    color: browserProvider.themeColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Paste Video Link Below",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CuteColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Supports direct video links (MP4, MKV, etc.)",
                    style: TextStyle(fontSize: 14, color: CuteColors.lightText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "https://example.com/video.mp4",
                      filled: true,
                      fillColor: CuteColors.cream.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _startDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isDownloading ? "Starting..." : "Download Video",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: browserProvider.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Tips 💡",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CuteColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem("Open any page with a video file."),
            _buildTipItem("Copy the direct link to the video."),
            _buildTipItem("Paste it here and tap Download!"),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Enjoy your offline videos! 💖",
                style: TextStyle(
                  color: browserProvider.themeColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: CuteColors.darkText),
            ),
          ),
        ],
      ),
    );
  }
}
