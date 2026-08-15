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
  - Extended SQLite schema with `banis` and `bani_verses` (junction table).
  - Added a **Re-ordering Feature**: Users can drag and drop Banis to customize their Nitnem sequence.
  - **Ordering Fix**: Implemented strict sorting by `id ASC` for shabads to overcome jumbled `verse_order` data from the API.

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
- **Ordering**: Strict `id ASC` sorting is used for Shabads, and `sequence_order` for Banis. Do NOT use `verse_order` for sorting.
- **Search**: Strictly maintain the "One Character = One Word Initial" rule.
- **Logging**: All critical paths are marked with `// [AI_GUARD:PERMANENT_LOG]`. Do not remove these logs as they are essential for debugging data discrepancies.
- **Highlighting**: The app passes `verseId` via URL query parameters to highlight the specific tukk clicked by the user.

---

## 5. Next Steps / Future Roadmap
- [ ] Implement audio streaming integration for Nitnem paths.
- [ ] Add bookmarking support for specific verses.
- [ ] Enhance "Lareevar" (continuous text) display mode in settings.
- [ ] Global search across all Banis simultaneously.
