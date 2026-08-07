# Technical Decisions: Gurbani Voice Search

## Database Strategy (Offline-First)
- **Engine:** Drift (SQLite).
- **Seeding:** A laptop script (`bin/sync_production_data.dart`) pre-builds the database.
- **Copy Logic:** On launch, the app checks the `schemaVersion`. If the version has increased, it overwrites the local SQLite file with the one from assets. 
- **Pathing:** Uses `ApplicationSupportDirectory` for native platforms and Drift's default for Web.

## Search Optimization
- **First Letter Index:** Verses are indexed by a custom `first_letter_str` column (comma-separated ASCII codes).
- **Phonetic Mapping:** Roman characters are mapped to Gurmukhi akhar codes. Multi-character phonetics like `kh`, `gh`, `th` are handled using a look-ahead parser in `GurmukhiProcessor`.

## UI & UX
- **App Shell:** Implements a dynamic navigation rail (desktop) or bar (mobile).
- **Reading Mode:** When a Shabad is opened, global navigation elements are hidden to maximize space.
- **Header:** Metadata (Raag, Author) and the App Bar are scrollable with the text.
- **Settings:** A dedicated dialog manages font sizes and visibility toggles to keep the main screen clean.

## Vishram (Pause) Data
- **Sources:** Aggregates from `sttm2`, `igurbani`, and `sttm`.
- **Format:** Word indexes (`p`) and pause strengths (`t`).
- **Highlighting:** UI splits the sentence and applies specific colors (Green for short, Blue for long) to the words at the given indexes.

## History Feature
- **Implementation:** Persistent SQLite table `search_history`.
- **Efficiency:** Stores the full `GurbaniSearchResult` metadata on click to avoid expensive JOINs with the massive verses table during history retrieval.
