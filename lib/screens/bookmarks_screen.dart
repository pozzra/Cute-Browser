import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    return Scaffold(
      backgroundColor: CuteColors.cream,
      appBar: AppBar(
        title: const Text("Bookmarks"),
        backgroundColor: CuteColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: CuteColors.darkText),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, color: CuteColors.darkText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        bookmark.url,
                        style: const TextStyle(color: CuteColors.lightText, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        browserProvider.loadUrl(bookmark.url);
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: CuteColors.pastelPink),
                        onPressed: () {
                          browserProvider.removeBookmark(bookmark.url);
                        },
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
