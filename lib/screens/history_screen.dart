import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
// ignore: unused_import
import '../widgets/animated_press.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);
    final history = browserProvider.history;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Dismissible(
                  key: Key('${item.url}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: theme.colorScheme.error,
                    child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (direction) {
                    browserProvider.removeFromHistory(index);
                  },
                  child: ListTile(
                    leading: const Icon(Icons.public, color: CuteColors.softPurple),
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      browserProvider.loadUrl(item.url);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
    );
  }
}
