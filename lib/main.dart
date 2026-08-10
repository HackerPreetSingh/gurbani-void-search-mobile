import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/gurbani_search_app.dart';
import 'core/database/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print('[GURBANI_LOG] App main entry point triggered');
  LocalDatabase.prefetchDocsPath();
  runApp(const ProviderScope(child: GurbaniSearchApp()));
}
