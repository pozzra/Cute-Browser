import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final history = browserProvider.history;

    return Scaffold(
      backgroundColor: CuteColors.cream,
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: CuteColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CuteColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
               browserProvider.clearHistory();
            }, 
            child: const Text("Clear", style: TextStyle(color: CuteColors.pastelPink, fontWeight: FontWeight.bold))
          )
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: CuteColors.lightText.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("No history yet", style: TextStyle(color: CuteColors.lightText)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                   leading: const Icon(Icons.public, color: CuteColors.softPurple),
                   title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                   subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                   onTap: () {
                     browserProvider.loadUrl(item.url);
                     Navigator.pop(context);
                   },
                );
              },
            ),
    );
  }
}
