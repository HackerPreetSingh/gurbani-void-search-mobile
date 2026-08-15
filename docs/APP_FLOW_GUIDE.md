# Comprehensive App Flow & Architecture Guide

This document provides an exhaustive, end-to-end explanation of the Gurbani Voice Search application's architecture, data flow, and platform-specific behaviors. It is designed for developers (from freshers to experts) and AI models building on top of this system.

---

## 1. Technology Stack Overview
- **Flutter**: Cross-platform UI framework.
- **Riverpod**: State management and dependency injection.
- **Drift (SQLite)**: Persistent local storage with reactive streams.
- **Dio**: HTTP client for API requests and database downloads.
- **GoRouter**: Declarative routing system.

---

## 2. Platform Architecture & Data Flow

### A. Android & iOS (Native Offline-First)
1. **Entry Point**: `lib/main.dart` initializes the Flutter engine and triggers `LocalDatabase.prefetchDocsPath()`.
2. **Foundation Check**: `lib/app/router/app_router.dart` uses `databaseStatusProvider` (`lib/core/di/core_providers.dart`) to check if the `gurbani_offline.sqlite` file exists on disk.
3. **Missing DB Action**: If the file is missing, the user is redirected to `lib/features/foundation/presentation/foundation_page.dart`.
4. **Download Flow**: 
   - User triggers download via `DatabaseDownloadNotifier` (`lib/core/database/database_download_notifier.dart`).
   - The file is streamed from `AppConstants.databaseDownloadUrl` directly to the app's document directory.
   - Upon success, `LocalDatabase.reload()` is called, and the router pushes the user to the Search screen.
5. **Search Flow**:
   - `SqlitePunjabiSearchRepository` (`lib/features/search/data/sqlite_punjabi_search_repository.dart`) queries the local SQLite file.
   - High-performance numeric prefix matching (Strategy 1) and English initials fallback (Strategy 2) are applied.

### B. Web (Fallback Architecture)
1. **No Disk Access**: On Web, `path_provider` is unavailable. The app detects `kIsWeb`.
2. **Empty DB Detection**: Since the 100MB+ database isn't bundled, the local DB is typically empty.
3. **Auto-Fallback**: When a search is performed, the `SqlitePunjabiSearchRepository` sees 0 local results and automatically routes the request to the remote BaniDB API via `RemoteSearchDataSource` (`lib/features/search/data/remote_search_data_source.dart`).

---

## 3. Search Logic Deep Dive (BaniDB Replica)
The app perfectly replicates the official BaniDB search sequence:

1. **Normalization**: `lib/features/search/domain/services/gurmukhi_processor.dart` strips spaces and maps Roman characters to Gurmukhi ASCII.
2. **Strategy 1 (Numeric)**: Uses `BETWEEN` on `first_letter_str` column. This uses comma-padded ASCII codes (e.g., `,115`) for millisecond-fast prefix lookups.
3. **Strategy 2 (English Initials)**: If Strategy 1 fails, the engine searches the `initials_en` column using `LIKE "%query%"`. This handles phonetic matches like `mkmgh`.
4. **Strategy 3 (Permutations)**: As a final safety net, deep phonetic permutations (swapping aspirated characters) are tried.

---

## 4. Nitnem & Bani Sequencing Logic
Unlike random shabads, Nitnem paths (Banis) require a strict liturgical order.
- **Mapping**: The `banis` table stores the path name (e.g., Japji Sahib).
- **Sequencing**: The `bani_verses` junction table links verses in a specific `sequence_order`.
- **UI Render**: `lib/features/search/presentation/bani_page.dart` fetches these ordered verses via `baniDetailsProvider` (`lib/features/search/domain/providers/bani_providers.dart`).

---

## 5. Debugging & Maintenance

### Comprehensive Logging
All critical steps are logged with `[GURBANI_LOG]` and a timestamp. 
- **Sync Issues**: Check `lib/features/search/domain/services/shabad_sync_service.dart`.
- **Search Issues**: Check `lib/features/search/data/sqlite_punjabi_search_repository.dart`.
- **UI Issues**: Check `shabad_page.dart` or `bani_page.dart` for build-time logs.

### AI Developer Extension Points
If you are an AI model building on this app:
1. **Schema Changes**: Add columns in `LocalDatabase._createProductionSchema`. Update `SearchResultMapper` to map new fields.
2. **Data Ingestion**: Add new sources in `bin/sync_shabads.dart` and define the extraction logic in `ShabadSyncService`.
3. **UI Enhancements**: Reuse `_buildUnifiedControl` in settings dialogs for consistency.

---

## 6. Important Files Reference
| Component | Primary File |
| :--- | :--- |
| **Constants** | `lib/core/constants/app_constants.dart` |
| **Search Logic** | `lib/features/search/data/sqlite_punjabi_search_repository.dart` |
| **Phonetic Processing**| `lib/features/search/domain/services/gurmukhi_processor.dart` |
| **Database Setup** | `lib/core/database/local_database.dart` |
| **Bani Ingestion** | `lib/features/search/domain/services/bani_sync_service.dart` |
| **UI Shell** | `lib/app/shell/app_shell.dart` |
