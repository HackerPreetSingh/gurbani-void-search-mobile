import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_page.dart';
import '../../features/search/presentation/search_screen.dart';
import '../shell/app_shell.dart';

abstract final class AppRoute {
  static const search = '/';
  static const about = '/about';
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
        ],
      ),
    ],
  );
}
