// Shell with bottom nav — docs/05 §3.1. Nav rail for ≥ 900 dp is M7 (§9).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    final i = Routes.tabs.lastIndexWhere(
      (t) => t == Routes.home ? location == t : location.startsWith(t),
    );
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(Routes.tabs[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.play_circle_outline_rounded),
            selectedIcon: const Icon(Icons.play_circle_rounded),
            label: l.navContinue,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route_rounded),
            label: l.navPath,
          ),
          NavigationDestination(
            icon: const Icon(Icons.replay_rounded),
            label: l.navReview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: l.navSearch,
          ),
        ],
      ),
    );
  }
}
