# AI Handoff Prompt: Gurbani Voice Search

**Project Context:**
You are taking over a Flutter project called "Gurbani Voice Search." It is a high-performance, offline-first search engine for Gurbani sources (SGGS, Dasam Granth, etc.). The goal is to provide a near-instant search experience like "SikhiToTheMax" or "iGurbani" but with superior local performance.

**Tech Stack:**
- **Framework:** Flutter (Web and Mobile).
- **State Management:** Riverpod.
- **Database:** Drift (SQLite) with `drift_flutter`.
- **Networking:** Dio.
- **Routing:** GoRouter.

**Core Architecture:**
1.  **The Sync Pipeline:** Data is pre-fetched on a developer laptop using `bin/sync_production_data.dart`. This script discovers sources from BaniDB API, iterates through all pages/shabads, and saves them to `assets/database/gurbani_offline.sqlite`.
2.  **The Asset Wiring:** On the first launch (or when `schemaVersion` is bumped in `local_database.dart`), the app copies this pre-baked SQLite file into the device's internal storage (`ApplicationSupportDirectory`).
3.  **The Search Engine:** Located in `lib/features/search/data/sqlite_punjabi_search_repository.dart`. It uses a custom `first_letter_str` index for lightning-fast initials-based lookups. It includes a "Remote Fallback" for Web or if local data is missing.

**Features Implemented:**
- **Search Logic:** Supports initials (e.g., `sssg`). Includes advanced Roman mapping (e.g., `kh` -> `ਖ`, `gh` -> `ਘ`). Sri Guru Granth Sahib (Source G) results are prioritized at the top.
- **Search History:** A self-contained `search_history` table in SQLite. Tapping any result saves the metadata (Gurmukhi, Raag, Source) permanently. History is sorted by most recent.
- **Shabad Page:** Immersive reading view (hides global app bars).
- **Display Options:** A settings dialog with:
    - **Visibility Toggles:** Hindi, English (OFF by default), Meaning, and Pauses (Vishram).
    - **Font Scaling:** Independent `+` and `-` buttons for Gurmukhi, Hindi, English, and Meaning text.
- **Vishrams (Pauses):** Data is imported from BaniDB (`sttm2`, `igurbani`, or `sttm`). The UI highlights words in Green (Short Pause) or Blue (Long Pause).

**Current Task & Critical Blockers:**
1.  **Drift Transactions:** When writing transactions, always use the passed `executor` (variable name `trans` or `executor`) to avoid "ensureOpen not defined" errors.
2.  **Vishram data:** Vishrams being applied to shabad tukks seem inconsistent, so it needs to be verified if correct vishrams are pulled and they are correct even at our producer point(Bani DB) or not

**Next Milestones:**
- **Milestone 3 (Complete):** Finalize Vishram highlighting visibility and reliability.
- **Milestone 4:** Implement Voice Search using `speech_to_text` (mapping voice input to the existing `GurmukhiProcessor`).
- **Milestone 5:** Full Word search support (searching for strings like "satnam" within verses).

**Instructions for the Next Agent:**
- Start by analyzing `lib/features/search/presentation/shabad_page.dart`'s `_buildGurmukhiText` method.
- Ensure the word-splitting logic used for display matches the indexing logic in `bin/sync_production_data.dart`.
- Verify the current `schemaVersion` (v17) and filename to ensure you aren't working with "ghost data."
- **STRICT RULE:** Do not change business logic, add fancy logs, or rename variables unless absolutely necessary for a fix. Keep it surgical.
