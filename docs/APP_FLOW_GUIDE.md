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
2. **Foundation Check**: `lib/app/router/app_router.dart` uses `databaseStatusProvider` (`lib/core/di/core_providers.dart`) to check for `shabads_offline.sqlite` and `nitnem_offline.sqlite`.
3. **In-Tab Access**: If files are missing, the **Search** and **Nitnem** tabs display a download prompt. The **Tracker** and **About** tabs remain fully functional immediately upon install.
4. **Manual Updates**: Users can manually refresh their database via the "Update Database" modal in the **About** tab.
5. **App Shell**: `lib/app/shell/app_shell.dart` provides 4-tab navigation with dynamic headers per section.

---

## 3. Core Feature Flows

### 3.1 Gurbani Search (The "Shabad" Flow)
- **Search Logic**: `SqlitePunjabiSearchRepository` queries both Shabad and Nitnem databases but prioritizes Shabad records to ensure clicking a tukk opens a specific Shabad, not a whole book.
- **Phonetic Mapping**: Users type English initials (e.g., `kejjb`). `GurmukhiProcessor` converts this into a numeric sequence for lookup.
- **Middle-of-Line**: Supports searching from anywhere in a line using substring matching (`LIKE '%query%'`).
- **Input Control**: The system keyboard is physically blocked on this screen; the custom keyboard is the mandatory input method and auto-reopens on field tap.
- **Reading Modes**: Supports **Larivaar** (continuous text) and **Vishram** (colored pauses) toggles.
- **Screen Stability**: Uses `wakelock_plus` to keep the screen on while reading.

### 3.2 Nitnem & Banis (The "Liturgy" Flow)
- **Logic**: Uses the `NitnemDB`. Verses are loaded using `sequence_order` to maintain the exact liturgical flow.
- **Special Layouts**: **Jaap Sahib** automatically collates verses into paragraphs for a pothi-style experience.
- **Customization**: Users can drag-and-drop Banis in the list to match their personal routine.

### 3.3 Nitnem Tracker (The "Progress" Flow)
- **Logic**: Uses `user_tracker.sqlite` (entirely isolated).
- **Templates**: Supports Mool Mantar/Simran (Maala units), Bani Count, and Sehaj Path (Ang tracking).
- **Analytics**: Calculates if a user is Ahead (Green), On Track (Orange), or Behind (Red) with intuitive trending icons.
- **Safety**: Synchronous state updates prevent `Dismissible` widget tree crashes during deletion.

3.4 Prakaran (The "Organization" Flow)
- **Persistence**: Items are stored with a `shabad_id` and an optional `verse_id`.
- **Deep-Linking**: If an item is saved with a `verse_id`, opening it from the folder will trigger an automatic scroll and highlight of that specific verse.
- **Real-time Sync**: The cache is invalidated on every add/delete to ensure the folder view is always current.

### B. Web (Fallback Architecture)
1. **No Disk Access**: On Web, `path_provider` is unavailable. The app detects `kIsWeb`.
2. **Empty DB Detection**: Since the 100MB+ database isn't bundled, the local DB is typically empty.
3. **Auto-Fallback**: When a search is performed, the `SqlitePunjabiSearchRepository` sees 0 local results and automatically routes the request to the remote BaniDB API via `RemoteSearchDataSource` (`lib/features/search/data/remote_search_data_source.dart`).

---

## 3. Search Logic Deep Dive (BaniDB Replica)
The app perfectly replicates the official BaniDB search sequence:

1. **Normalization**: `lib/features/search/domain/services/gurmukhi_processor.dart` strips spaces and maps Roman characters to Gurmukhi ASCII.
2. **Strategy 1 (Numeric/Substrings)**: Uses `LIKE '%query%'` on `first_letter_str` column. This uses comma-padded ASCII codes (e.g., `,115`) for millisecond-fast substring lookups. This allows matching initials from the beginning or middle of a line.
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
4. **Stable Baseline Note**: Ensure all new features are built on top of the Phase 7 stable architecture. Avoid experimental dependencies that break JVM alignment (Java 17/Kotlin 1.9+).

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
