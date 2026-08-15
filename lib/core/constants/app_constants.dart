/// Centralized constants for the Gurbani Voice Search application.
/// Modify these values to update endpoints or file paths globally.
abstract final class AppConstants {
  // --- DATABASE CONSTANTS ---
  
  /// Filenames for the separate SQLite databases.
  static const String shabadDbFile = 'shabads_offline.sqlite';
  static const String nitnemDbFile = 'nitnem_offline.sqlite';
  static const String userTrackerDbFile = 'user_tracker.sqlite';

  @Deprecated('Use shabadDbFile or nitnemDbFile')
  static const String dbFileName = shabadDbFile;
  
  /// Select the hosting provider for the database file: 'vercel' or 'github'
  static const String downloadProvider = 'vercel';

  static const String _vercelShabadUrl = 'https://9adxmnfutozpuzyq.public.blob.vercel-storage.com/shabads_offline.sqlite';
  static const String _vercelNitnemUrl = 'https://9adxmnfutozpuzyq.public.blob.vercel-storage.com/nitnem_offline.sqlite';
  static const String _githubShabadUrl = 'https://github.com/HackerPreetSingh/gurbani-void-search-mobile/raw/main/assets/database/shabads_offline.sqlite';
  static const String _githubNitnemUrl = 'https://github.com/HackerPreetSingh/gurbani-void-search-mobile/raw/main/assets/database/nitnem_offline.sqlite';

  /// URLs for the production SQLite databases.
  static const String shabadDownloadUrl = downloadProvider == 'vercel' ? _vercelShabadUrl : _githubShabadUrl;
  static const String nitnemDownloadUrl = downloadProvider == 'vercel' ? _vercelNitnemUrl : _githubNitnemUrl;

  static const String databaseDownloadUrl = shabadDownloadUrl;

  // --- API CONSTANTS ---

  /// Base URL for the BaniDB API (v2).
  static const String banidbBaseUrl = 'https://api.banidb.com/v2';

  // --- LOGGING CONSTANTS ---
  
  /// Standard prefix for all debug logs related to Gurbani data or engine.
  static const String logTag = '[GURBANI_LOG]';

  // --- LITURGICAL CONSTANTS ---

  /// The default order of Banis by ID. 
  /// Banis not in this list will follow at the end in their original ID order.
  static const List<int> defaultBaniOrder = [
    2,   // Japji Sahib
    4,   // Jaap Sahib
    6,   // Tav Prasad Sawaiye
    9,   // Chaupai Sahib
    10,  // Anand Sahib
    3,   // Shabad Hazare
    31,  // Sukhmani Sahib
    21,  // Rehras Sahib
    24,  // Ardas
    23,  // Sohila
    22,  // Aarti
    90,  // Aasa Ki Var
    104, // Basant Ki Vaar
  ];
}
