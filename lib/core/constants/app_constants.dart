/// Centralized constants for the Gurbani Voice Search application.
/// Modify these values to update endpoints or file paths globally.
abstract final class AppConstants {
  // --- DATABASE CONSTANTS ---
  
  /// The filename of the local SQLite database used across all platforms.
  static const String dbFileName = 'gurbani_offline.sqlite';
  
  /// Select the hosting provider for the database file: 'vercel' or 'github'
  static const String downloadProvider = 'vercel';

  static const String _vercelUrl = 'https://9adxmnfutozpuzyq.public.blob.vercel-storage.com/gurbani_offline.sqlite';
  static const String _githubUrl = 'https://github.com/HackerPreetSingh/gurbani-void-search-mobile/raw/main/assets/database/gurbani_offline.sqlite';

  /// The direct download URL for the production SQLite database based on the selected provider.
  static const String databaseDownloadUrl = downloadProvider == 'vercel' ? _vercelUrl : _githubUrl;

  // --- API CONSTANTS ---

  /// Base URL for the BaniDB API (v2).
  static const String banidbBaseUrl = 'https://api.banidb.com/v2';

  // --- LOGGING CONSTANTS ---
  
  /// Standard prefix for all debug logs related to Gurbani data or engine.
  static const String logTag = '[GURBANI_LOG]';
}
