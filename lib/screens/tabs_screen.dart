import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    return Scaffold(
      backgroundColor: CuteColors.cream,
      appBar: AppBar(
        title: const Text("Tabs"),
        backgroundColor: CuteColors.cream,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: CuteColors.darkText),
            tooltip: "Close All Tabs",
            onPressed: () {
              browserProvider.closeAllTabs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: CuteColors.darkText),
            onPressed: () {
              browserProvider.addTab();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: browserProvider.tabs.length,
            itemBuilder: (context, index) {
              final tab = browserProvider.tabs[index];
              final isSelected = index == browserProvider.currentIndex;

              return GestureDetector(
                onTap: () {
                  browserProvider.changeTab(index);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: CuteColors.pastelPink, width: 3)
                        : null,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CuteColors.pastelPink
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  tab.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : CuteColors.darkText,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.web_asset,
                                    size: 48,
                                    color: CuteColors.softPurple,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tab.currentUrl,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: CuteColors.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            browserProvider.closeTab(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white54,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: CuteColors.darkText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        label: const Text("Done", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.check, color: Colors.white),
        backgroundColor: CuteColors.pastelPink,
      ),
    );
  }
}
