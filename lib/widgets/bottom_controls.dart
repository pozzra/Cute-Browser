import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../theme/colors.dart';
import '../screens/tabs_screen.dart';
import 'cute_menu_overlay.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = Provider.of<BrowserProvider>(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: browserProvider.canGoBack ? browserProvider.goBack : null,
                icon: Icon(Icons.arrow_back_ios_rounded, 
                  color: browserProvider.canGoBack ? CuteColors.darkText : CuteColors.lightText),
              ),
              IconButton(
                onPressed: browserProvider.canGoForward ? browserProvider.goForward : null,
                icon: Icon(Icons.arrow_forward_ios_rounded, 
                  color: browserProvider.canGoForward ? CuteColors.darkText : CuteColors.lightText),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () {
                  browserProvider.addTab();
                },
                backgroundColor: CuteColors.mintGreen,
                elevation: 4,
                mini: true,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TabsScreen()));
                },
                icon: const Icon(Icons.grid_view_rounded, color: CuteColors.darkText),
              ),
              IconButton(
                onPressed: () {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => const CuteMenuOverlay(),
                   );
                },
                icon: const Icon(Icons.more_vert_rounded, color: CuteColors.darkText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
