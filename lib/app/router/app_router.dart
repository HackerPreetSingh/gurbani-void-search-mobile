import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_page.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/shabad_page.dart';
import '../shell/app_shell.dart';

abstract final class AppRoute {
  static const search = '/';
  static const about = '/about';
  static const shabad = '/shabad'; // This will be used as '/shabad/:id'
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoute.search,
    routes: [
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoute.search,
            builder: (BuildContext context, GoRouterState state) {
              return const SearchScreen();
            },
          ),
          GoRoute(
            path: AppRoute.about,
            builder: (BuildContext context, GoRouterState state) {
              return const AboutPage();
            },
          ),
          // Using a more robust path definition
          GoRoute(
            path: '/shabad/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['id']!;
              return ShabadPage(shabadId: id);
            },
          ),
        ],
      ),
    ],
  );
}
