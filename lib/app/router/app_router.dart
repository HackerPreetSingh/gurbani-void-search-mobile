import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/di/core_providers.dart';
import '../../features/about/presentation/about_page.dart';
import '../../features/foundation/presentation/foundation_page.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/search/shabad/presentation/shabad_screen.dart';
import '../shell/app_shell.dart';

import '../../features/search/presentation/nitnem_screen.dart';
import '../../features/search/bani/presentation/bani_screen.dart';
import '../../features/tracker/presentation/tracker_list_screen.dart';
import '../../features/tracker/presentation/tracker_creation_wizard.dart';
import '../../features/tracker/presentation/tracker_details_page.dart';

abstract final class AppRoute {
  static const search = '/';
  static const nitnem = '/nitnem';
  static const tracker = '/tracker';
  static const about = '/about';
  static const shabad = '/shabad';
  static const foundation = '/foundation';
}

GoRouter createAppRouter(Ref ref) {
  final dbListenable = ValueNotifier<AsyncValue<DatabaseStatus>>(const AsyncLoading());
  
  ref.listen(databaseStatusProvider, (_, next) {
    dbListenable.value = next;
  }, fireImmediately: true);

  return GoRouter(
    initialLocation: AppRoute.search,
    refreshListenable: dbListenable,
    redirect: (context, state) {
      // Logic for redirection removed to allow all tabs to be accessible.
      // Database missing screens will be handled inside specific tabs.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.foundation,
        builder: (context, state) => const FoundationPage(),
      ),
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
            path: AppRoute.nitnem,
            builder: (BuildContext context, GoRouterState state) {
              return const NitnemScreen();
            },
          ),
          GoRoute(
            path: AppRoute.tracker,
            builder: (BuildContext context, GoRouterState state) {
              return const TrackerListScreen();
            },
          ),
          GoRoute(
            path: '/tracker/create',
            builder: (BuildContext context, GoRouterState state) {
              return const TrackerCreationWizard();
            },
          ),
          GoRoute(
            path: '/tracker/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['id']!;
              return TrackerDetailsPage(trackerId: id);
            },
          ),
          GoRoute(
            path: AppRoute.about,
            builder: (BuildContext context, GoRouterState state) {
              return const AboutPage();
            },
          ),
          GoRoute(
            path: '/shabad/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['id']!;
              final highlightId = state.uri.queryParameters['verseId'];
              return ShabadScreen(shabadId: id, highlightVerseId: highlightId);
            },
          ),
          GoRoute(
            path: '/nitnem/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = int.parse(state.pathParameters['id']!);
              final highlightId = state.uri.queryParameters['verseId'];
              return BaniScreen(baniId: id, highlightVerseId: highlightId);
            },
          ),
        ],
      ),
    ],
  );
}
