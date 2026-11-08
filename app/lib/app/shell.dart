// Shell — docs/05 §3.1 and §9: bottom nav below 900 dp, NavigationRail on
// the left from 900 dp (same four destinations, same order).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'layout.dart';
import 'router.dart';
import 'theme/tokens.dart';

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
    final c = Theme.of(context).extension<LtaColors>()!;
    void select(int i) => context.go(Routes.tabs[i]);
    final items = [
      (
        Icons.play_circle_outline_rounded,
        Icons.play_circle_rounded,
        l.navContinue,
      ),
      (Icons.route_outlined, Icons.route_rounded, l.navPath),
      (Icons.replay_rounded, Icons.replay_rounded, l.navReview),
      (Icons.search_rounded, Icons.search_rounded, l.navSearch),
    ];

    if (LtaLayout.of(context).twoColumn) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            VerticalDivider(
              width: LtaSize.border,
              thickness: LtaSize.border,
              color: c.line,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          for (final (icon, selected, label) in items)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
