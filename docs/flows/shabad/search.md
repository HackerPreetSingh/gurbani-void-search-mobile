# Flow: Shabad Search

This document explains how a user finds a Gurbani line (Shabad) starting from the search box.

## 1. User Input
The process starts in `SearchScreen` (lib/features/search/presentation/search_screen.dart).
- The user types into the `SearchBar`.
- This triggers the `onQueryChanged` method in `SearchViewModel` (lib/features/search/presentation/search_view_model.dart).

## 2. Debouncing & Logic Trigger
- To avoid searching on every single keystroke, the `SearchViewModel` waits for 300 milliseconds of silence (debouncing).
- Once the user stops typing and the query is at least 3 characters long, `_performSearch` is called.

## 3. Search Engine Execution
The control moves to `SqlitePunjabiSearchRepository` (lib/features/search/data/sqlite_punjabi_search_repository.dart).
- **Step A: Normalization**: The `GurmukhiProcessor` strips spaces and prepares the query.
- **Step B: Numeric Strategy**: It first tries to find matches using a numeric "first letter" code stored in the database. This is very fast.
- **Step C: Phonetic Fallback**: If no numeric match is found, it searches using English phonetic initials (e.g., typing 'hkh' to find 'ਹਮਰੀ ਕਰੋ ਹਾਥ').
- **Step D: Deep Permutations**: If both fail, it generates variations of the letters (like swapping 'k' for 'K') and tries again.

## 4. Result Processing
The raw database rows are sent to `SearchResponseProcessor` (lib/features/search/domain/services/search_response_processor.dart).
- It removes duplicate lines that appear in both the main corpus and the Nitnem sections.
- It prioritizes original sources like Guru Granth Sahib Ji.

## 5. UI Update
- The filtered list is sent back to `SearchViewModel` which updates the `state`.
- `SearchScreen` sees the new data and refreshes the list on the screen for the user.
