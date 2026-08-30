# Flow: Search History

This document explains how the app remembers what the user has searched for previously.

## 1. Saving to History
When a user clicks on a search result in `SearchScreen`:
- The method `addToHistory` is called in `SearchViewModel`.
- This calls the `PuniabiSearchRepository` which uses `LocalSearchDataSource` (lib/features/search/data/local_search_data_source.dart).
- The Shabad ID and the query text are saved into the `search_history` table in the SQLite database.

## 2. Viewing History
In the `SearchScreen` top bar, there is a clock icon:
- Clicking this triggers `toggleHistoryMode` in the `SearchViewModel`.
- The view model asks the repository for all items in the `search_history` table.
- The results are displayed in the same list where search results usually appear, but marked as "History".

## 3. Clearing History
If the user is in History Mode, a trash can icon appears:
- Clicking it triggers `clearHistory` in the `SearchViewModel`.
- This tells the database to delete all rows from the `search_history` table.
- The UI is immediately refreshed to show an empty state.
