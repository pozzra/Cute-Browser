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
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surface;
    final iconColor = theme.colorScheme.onSurface;
    final secondaryIconColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light 
                  ? Colors.black12 
                  : Colors.white.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
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
                  color: browserProvider.canGoBack ? iconColor : secondaryIconColor),
              ),
              IconButton(
                onPressed: browserProvider.canGoForward ? browserProvider.goForward : null,
                icon: Icon(Icons.arrow_forward_ios_rounded, 
                  color: browserProvider.canGoForward ? iconColor : secondaryIconColor),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () {
                  browserProvider.addTab();
                },
                backgroundColor: browserProvider.themeColor,
                elevation: 4,
                mini: true,
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TabsScreen()));
                },
                icon: Icon(Icons.grid_view_rounded, color: iconColor),
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
                icon: Icon(Icons.more_vert_rounded, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
