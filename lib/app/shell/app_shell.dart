import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.currentPath, required this.child, super.key});

  final String currentPath;
  final Widget child;

  static const _destinations = <_AppDestination>[
    _AppDestination(
      label: 'Gurbani Search',
      location: AppRoute.search,
      icon: Icons.manage_search_outlined,
      selectedIcon: Icons.manage_search,
    ),
    _AppDestination(
      label: 'Nitnem & Banis',
      location: AppRoute.nitnem,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _AppDestination(
      label: 'Nitnem Tracker',
      location: AppRoute.tracker,
      icon: Icons.track_changes_outlined,
      selectedIcon: Icons.track_changes,
    ),
    _AppDestination(
      label: 'About',
      location: AppRoute.about,
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexWhere(
      (_AppDestination destination) => destination.location == currentPath,
    );
    final resolvedIndex = selectedIndex == -1 ? 0 : selectedIndex;
    final useNavigationRail = MediaQuery.sizeOf(context).width >= 840;
    
    // Hide global elements when viewing a Shabad/Bani, tracker details, or in a creation flow
    final isDetailView = currentPath.startsWith('/shabad') || 
                         currentPath.startsWith('/nitnem/') || 
                         currentPath.startsWith('/tracker/') ||
                         currentPath.contains('/create');

    if (!useNavigationRail) {
      return Scaffold(
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: isDetailView 
            ? null 
            : NavigationBar(
                selectedIndex: resolvedIndex,
                onDestinationSelected: (int index) => _navigate(context, index),
                destinations: _destinations
                    .map(
                      (_AppDestination destination) => NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                    )
                    .toList(growable: false),
              ),
      );
    }

    final isExtended = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (!isDetailView) ...[
              NavigationRail(
                extended: isExtended,
                selectedIndex: resolvedIndex,
                onDestinationSelected: (int index) => _navigate(context, index),
                leading: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 12, 8, 20),
                  child: _BrandMark(),
                ),
                labelType: isExtended ? null : NavigationRailLabelType.all,
                destinations: _destinations
                    .map(
                      (_AppDestination destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final destination = _destinations[index];
    if (destination.location != currentPath) {
      context.go(destination.location);
    }
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Gurbani Search',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined),
          if (MediaQuery.sizeOf(context).width >= 1100) ...[
            const SizedBox(width: 10),
            Text(
              'Gurbani Search',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.location,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String location;
  final IconData icon;
  final IconData selectedIcon;
}
