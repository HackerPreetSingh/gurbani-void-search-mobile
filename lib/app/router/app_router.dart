import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/di/core_providers.dart';
import '../../features/about/presentation/about_page.dart';
import '../../features/foundation/presentation/foundation_page.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/shabad_page.dart';
import '../shell/app_shell.dart';

import '../../features/search/presentation/nitnem_screen.dart';
import '../../features/search/presentation/bani_page.dart';

abstract final class AppRoute {
  static const search = '/';
  static const nitnem = '/nitnem';
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
    initialLocation: AppRoute.foundation,
    refreshListenable: dbListenable,
    redirect: (context, state) {
      final dbState = dbListenable.value;
      final bool isAtFoundation = state.uri.path == AppRoute.foundation;
      print('[GURBANI_LOG] Router Redirect: path=${state.uri.path}, dbState=${dbState.runtimeType}');

      return dbState.when(
        data: (status) {
          print('[GURBANI_LOG] Router: DB is Ready, available=${status.isAvailable}');
          if (!status.isAvailable) {
            if (!isAtFoundation) return AppRoute.foundation;
            return null;
          }
          if (isAtFoundation) return AppRoute.search;
          return null; 
        },
        error: (error, _) {
          print('[GURBANI_LOG] Router: Generic DB Error: $error');
          return null; 
        },
        loading: () {
          print('[GURBANI_LOG] Router: DB is Checking...');
          if (!isAtFoundation) return AppRoute.foundation;
          return null;
        },
      );
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
              return ShabadPage(shabadId: id, highlightVerseId: highlightId);
            },
          ),
          GoRoute(
            path: '/nitnem/:id',
            builder: (BuildContext context, GoRouterState state) {
              final id = int.parse(state.pathParameters['id']!);
              final highlightId = state.uri.queryParameters['verseId'];
              return BaniPage(baniId: id, highlightVerseId: highlightId);
            },
          ),
        ],
      ),
    ],
  );
}
