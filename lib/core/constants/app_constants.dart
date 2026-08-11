/// Centralized constants for the Gurbani Voice Search application.
/// Modify these values to update endpoints or file paths globally.
abstract final class AppConstants {
  // --- DATABASE CONSTANTS ---
  
  /// The filename of the local SQLite database used across all platforms.
  static const String dbFileName = 'gurbani_offline.sqlite';
  
  /// The direct download URL for the production SQLite database.
  /// The direct download URL for the production SQLite database.
  static const String databaseDownloadUrl = 
      'https://github.com/HackerPreetSingh/gurbani-void-search-mobile/raw/main/assets/database/gurbani_offline.sqlite';

  // --- API CONSTANTS ---

  /// Base URL for the BaniDB API (v2).
  static const String banidbBaseUrl = 'https://api.banidb.com/v2';

  // --- LOGGING CONSTANTS ---
  
  /// Standard prefix for all debug logs related to Gurbani data or engine.
  static const String logTag = '[GURBANI_LOG]';
}
