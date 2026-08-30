# AI Developer Handover: Project Genesis & Current State

This document captures the history, architecture, and current status of the Gurbani Voice Search project. It is designed to help any future AI agent or developer understand the context of what has been built from scratch.

---

## 1. Project Mission
To create a high-performance, offline-first Gurbani search engine and liturgical viewer that perfectly replicates the business logic of the official BaniDB API, supporting English phonetic search (e.g., `mkmgh`) and strict liturgical sequencing.

---

## 2. Chronological History & Key Milestones

### Phase 1: The Core Search Engine (BaniDB Replica)
- **Goal**: Implement a local search that matches the accuracy of `api.banidb.com`.
- **Implementation**:
  - **Numeric Strategy**: Uses comma-padded ASCII codes in SQLite for millisecond prefix matching.
  - **Phonetic Strategy**: Implemented "Lazy English" initials indexing to allow QWERTY keyboards to find Gurmukhi letters (e.g., `k` matching both `ਕ` and `ਖ`).
  - **Permutations**: Added deep phonetic fallback logic to swap aspirated characters during search.
- **Key Logic Guard**: All search logic is encapsulated in `SqlitePunjabiSearchRepository` and `GurmukhiProcessor`.

### Phase 2: High-Speed Sync System
- **Goal**: Populate a 100MB+ database from the remote API in minutes, not hours.
- **Implementation**:
  - Built a parallelized ingestion engine (`bin/sync_shabads.dart`) capable of 40 concurrent HTTP requests.
  - Segregated logic into `ShabadSyncService` (standard sources) and `BaniSyncService` (liturgical paths).
  - Handles specialized sources like *Amrit Keertan* (header-indexed) and *Rehatname* (chapter-prose).

### Phase 3: Nitnem & Banis Feature
- **Goal**: Support structured liturgical paths (Japji Sahib, Jaap Sahib, etc.) which aren't random shabads.
- **Implementation**:
  - Segregated into a second database: `nitnem_offline.sqlite`.
  - Added a **Re-ordering Feature**: Users can drag and drop Banis to customize their Nitnem sequence.
  - **Ordering Fix**: Implemented strict sorting by `id ASC` for shabads to overcome jumbled `verse_order` data from the API.

### Phase 4: Nitnem Tracker & Multi-DB Architecture
- **Goal**: Add persistence for user spiritual progress without risking data loss during corpus updates.
- **Implementation**:
  - Introduced a **Triple-DB Architecture**:
    1. `shabads_offline.sqlite`: Primary corpus for search.
    2. `nitnem_offline.sqlite`: Sequential liturgical paths for reading.
    3. `user_tracker.sqlite`: Private user progress (never synced/overwritten).
  - **Nitnem Tracker Features**:
    - CRUD operations for spiritual goals (Mool Mantar, Simran, Bani, Sehaj Path).
    - Full editing support for both tracker definitions and individual progress logs.
    - Consistent input formats across all templates.
    - Visual RAG (Red/Amber/Green) feedback with intuitive trending icons.

### Phase 5: Reading Experience & Maintenance Polish
- **Goal**: Enhance traditional reading styles and accessibility.
- **Implementation**:
  - **Larivaar Mode**: Added a global setting to remove spaces within Gurbani lines.
  - **Vishram Engine**: Re-engineered to work simultaneously with Larivaar mode (colored pauses without spaces).
  - **Jaap Sahib Paragraphing**: Implemented liturgical collation for Jaap Sahib to render verses as paragraphs.
  - **Isolated Foundation**: Decoupled the database download prompt so only Search/Nitnem tabs are blocked if files are missing; Tracker and About remain accessible.
  - **Manual Updates**: Added a translucent modal in the About section for manual database maintenance and sequential downloading.

---

## 3. Technology Stack & Key Files

| Layer | Technology | Key File |
| :--- | :--- | :--- |
| **Logic** | Dart (Pure) | `lib/features/search/domain/services/gurmukhi_processor.dart` |
| **Data** | Drift (SQLite) | `lib/core/database/local_database.dart` |
| **State** | Riverpod | `lib/features/search/domain/providers/bani_providers.dart` |
| **UI** | Flutter M3 | `lib/features/search/presentation/shabad_page.dart` |
| **Sync** | Dio + SQLite | `bin/sync_shabads.dart` |

---

## 4. Current State & Critical Guards
- **Multi-DB Architecture**: 
  - `ShabadDB`: Individual search results from primary sources.
  - `NitnemDB`: Sequential liturgical path reading.
  - `TrackerDB`: Private user spiritual progress.
- **De-duplication**: The search engine prioritizes ShabadDB over NitnemDB to avoid the "Whole Bani" loading bug.
- **Logging**: All critical paths are marked with `// [AI_GUARD:PERMANENT_LOG]`.

---

## 5. Next Steps / Future Roadmap
- [x] Implement Nitnem Tracker with RAG analytics.
- [ ] Add cloud synchronization for `user_tracker.sqlite`.
- [ ] Implement audio streaming integration for Nitnem paths.
- [ ] Enhance "Lareevar" (continuous text) display mode in settings.
