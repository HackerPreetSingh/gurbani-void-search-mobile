# Architecture Flow: How the App Works (Zero-to-Hero Guide)

This guide is for developers who want to understand exactly how a request travels through the code. Whether you are on Web or a Phone, here is the full journey.

---

## 1. The Starting Point: Initializing the Data

Before we can search, the app needs to know where the data is.

### On Web:
Browsers don't let us easily copy large files (like our 50MB database) into a permanent folder.
- **File**: `lib/core/database/local_database.dart`
- **Action**: When the app starts, the `_initialize()` method runs. On Web, it skips the "copy asset" step and creates an empty "Web-only" database in the browser's storage (IndexedDB).
- **Result**: Since this database starts empty, the Web version will almost always use the **Remote API** to find results.

### On Mobile (Android/iOS):
- **File**: `lib/core/database/local_database.dart`
- **Action**: The `_initialize()` method calls `_copyAssetDatabaseIfNeeded()`.
- **Logic**: It looks for a file named `gurbani_offline.sqlite` in the phone's internal "Documents" folder. If it's not there (first time opening the app), it reads the file we bundled in `assets/database/` and copies it over.
- **Result**: The app now has a full, lightning-fast copy of Gurbani ready for offline use.

---

## 2. The Search Journey (Example: User searches for "sssg")

Imagine a user types "sssg" in the search bar. Here is the step-by-step path:

### Step 1: The UI Capture
- **File**: `lib/features/search/presentation/search_screen.dart`
- **What happens**: The `SearchBar` detects the typing. Every time a letter is added, it calls `vm.onQueryChanged(value)`.

### Step 2: The Wait (Debouncing)
- **File**: `lib/features/search/presentation/search_view_model.dart`
- **What happens**: Inside `onQueryChanged`, we don't search immediately (that would be too many requests). We use a `Timer` to wait for **300ms**. If the user stops typing, `_performSearch` is triggered.

### Step 3: The Translation
- **File**: `lib/features/search/domain/services/gurmukhi_search_text.dart`
- **What happens**: The raw "sssg" is passed to `parseQuery()`. This determines if it's Roman or Gurmukhi. It then uses `GurmukhiProcessor` to turn "sssg" into the numeric code used by our database: `,083,083,083,071`.

### Step 4: The Decision Maker (The Repository)
- **File**: `lib/features/search/data/sqlite_punjabi_search_repository.dart`
- **Method**: `search()`
- **What happens**: This is the "brain" of the search.
    1. It first calls `_localDataSource.search()`.
    2. **On Mobile**: The local search finds matches in the `verses` table instantly. It returns them to the Repository.
    3. **On Web**: The local search returns nothing (because the DB is empty).
    4. **The Fallback**: If the local search is empty, the Repository calls `_remoteDataSource.search()`, which hits the BaniDB internet API.

### Step 5: The Cleanup (Mapping)
- **File**: `lib/features/search/data/search_result_mapper.dart`
- **What happens**: Whether the data came from SQLite or the Internet, it's messy. The `SearchResultMapper` converts it into a clean `GurbaniSearchResult` object. It fills in the Gurmukhi, English Meaning, and Punjabi Meaning.

### Step 6: The Display
- **File**: `lib/features/search/presentation/search_view_model.dart`
- **What happens**: The mapper returns the list to the ViewModel, which sets `state = AsyncValue.data(results)`. The UI in `search_screen.dart` sees this update and builds the list of tiles you see on your screen.

---

## 3. Viewing a Shabad (The Reading Flow)

When a user taps a search result:

1. **Navigation**: `GoRouter` (in `app_router.dart`) picks up the `shabadId` and opens the `ShabadPage`.
2. **Loading**: The `shabadDetailsProvider` is triggered. It tells the Repository to "Give me every verse for this Shabad ID."
3. **Optimized Fetching**: Because our `verses` table is **denormalized** (it has the Raag name, Writer name, etc., pre-saved inside), we don't have to do any slow "JOIN" queries. We just pull the rows directly.
4. **Highlights (The Magic)**:
    - **File**: `lib/features/search/domain/services/vishram_service.dart`
    - **What happens**: For every line of Gurmukhi, the UI calls `buildGurmukhiText()`.
    - This service parses the "visraams" JSON (the pause data). It splits the Gurmukhi line into individual words and wraps specific words in Green or Blue colors.
5. **Final Render**: The `ShabadPage` displays the highlighted Gurmukhi, the Punjabi Meaning (Teeka), and any other enabled translations.

---

## Summary for Freshers
- **Want to change the search speed?** Look at `local_search_data_source.dart` (SQL) or `gurmukhi_processor.dart` (String conversion).
- **Want to add a new language?** Add a field to `GurbaniSearchResult`, update `SearchResultMapper`, and add a toggle in `ShabadPage`.
- **Want to fix a UI bug?** Look at `search_screen.dart` (the list) or `shabad_page.dart` (the reader).
