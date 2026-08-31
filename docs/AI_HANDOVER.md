# AI Developer Handover: Project Genesis & Current State

This document captures the history, architecture, and current status of the Gurbani Voice Search project.

---

## 1. Project Mission
To create a high-performance, offline-first Gurbani search engine and liturgical viewer with integrated spiritual progress tracking.

---

## 2. Chronological History & Key Milestones

### Phase 1-4: Foundation & Core Features
- Established the **Triple-DB Architecture** (Shabad, Nitnem, Tracker).
- Implemented Phonetic Search with English initials.
- Built the Sync system for parallel database ingestion.
- Implemented Nitnem Tracker with RAG analytics.

### Phase 5: Modularization & SOLID Refactoring
- **Restructuring**: Moved from monolithic files to feature-based modules (`lib/features/shabad`, `lib/features/bani`, `lib/features/tracker`, `lib/features/prakaran`).
- **Shared Components**: Unified UI logic for Gurbani display into `lib/features/search/shared/`.
- **SOLID**: Isolated SQL building (`SearchQueryBuilder`) and result processing (`SearchResponseProcessor`) into dedicated services.

### Phase 6: Input & Organization Enhancements
- **Custom Keyboards**: Built in-app Punjabi and English keyboards to ensure input consistency and fix height-related UI bugs.
- **Prakaran**: Added "Folder" functionality allowing users to save and organize Shabads into personal collections.

### Phase 7: Liturgical Polish & Gestures (STABLE BASELINE)
- **Sukhmani Sahib Pagination**: Replaced unreliable long-scroll jumping with a robust paginated system (24 Ashtapadis).
- **Sticky Navigation**: Added fixed arrow-based navigation and Salok body styling (Dark Blue).
- **Gestures**: Implemented Pinch-to-Zoom for all reading screens and Swipe-to-Delete for Tracker goals.
- **UI Refinement**: Optimized keyboard layout and cleaned up Nitnem list titles.
- **Production Status**: This version is the verified stable baseline intended for initial release. All experimental voice-search and SDK-version recovery attempts have been reverted.

### Phase 8: Release Polish & Navigation Depth
- **Middle-of-Line Search**: Enhanced `SearchQueryBuilder` with substring matching (`LIKE '%query%'`), allowing users to find lines by entering initials of continuous words from anywhere in the line.
- **Deep-Link Folders**: Upgraded Prakaran (folders) to store specific `verse_id`. Opening a Shabad from a folder now automatically scrolls to and highlights the exact saved line.
- **Input Hardening**: Permanently disabled system keyboard on Shabad Search (`TextInputType.none`) and implemented auto-reopen for the custom keyboard on search box tap.
- **Reading Comfort**: Integrated `wakelock_plus` to keep the screen active during Gurbani reading.
- **Search Scale**: Increased search result limits from 40 to 500 across all data sources.
- **Stability**: Fixed `Dismissible` state synchronization crashes in the Nitnem Tracker.

---

## 3. Technology Stack & Key Files

| Component | Technology | Primary Directory |
| :--- | :--- | :--- |
| **Search Engine** | Dart + SQLite | `lib/features/search/shabad/` |
| **Liturgy Reading**| Flutter + SQLite | `lib/features/search/bani/` |
| **User Tracking** | Drift + SQLite | `lib/features/tracker/` |
| **Organization** | SQLite | `lib/features/prakaran/` |
| **State** | Riverpod | `lib/features/*/domain/providers/` |

---

## 4. Documentation Structure
For detailed feature flows, refer to the following:
- **Search & History**: `docs/flows/shabad/search.md`, `history.md`
- **Keyboards**: `docs/flows/shabad/keyboard.md`
- **Prakaran**: `docs/flows/shabad/prakaran.md`
- **Bani & Pagination**: `docs/flows/nitnem/reading.md`, `pagination.md`
- **Tracker**: `docs/flows/tracker/creation.md`, `logging.md`, `analytics.md`

---

## 5. Critical Guards
- **[AI_LOCKED]**: Do not modify `GurmukhiProcessor` or `LocalDatabase` without explicit architectural review.
- **Deduplication**: Search results must be filtered via `SearchResponseProcessor` to avoid duplicates between corpus and liturgy.
