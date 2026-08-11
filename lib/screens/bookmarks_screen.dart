import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../widgets/animated_press.dart';
import '../widgets/entrance_animation.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Bookmarks"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: browserProvider.bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: CuteColors.lightText.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("No bookmarks yet", style: TextStyle(color: CuteColors.lightText)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: browserProvider.bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = browserProvider.bookmarks[index];
                return EntranceAnimation(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedPress(
                    onTap: () {
                      browserProvider.loadUrl(bookmark.url);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          bookmark.title,
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          bookmark.url,
                          style: const TextStyle(color: CuteColors.lightText, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                          onPressed: () {
                            browserProvider.removeBookmark(bookmark.url);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (browserProvider.currentUrl.isNotEmpty) {
             browserProvider.addBookmark(browserProvider.currentTitle, browserProvider.currentUrl);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Bookmark Added!"), duration: Duration(milliseconds: 800)),
             );
          }
        },
        backgroundColor: CuteColors.pastelPink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Current Page", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
