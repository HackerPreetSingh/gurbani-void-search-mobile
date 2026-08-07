# Roadmap: Gurbani Voice Search

## Milestone 1: Core Foundation [COMPLETED]
- Setup Flutter, Riverpod, and GoRouter.
- Implement basic BaniDB API integration.

## Milestone 2: Production Search Engine [COMPLETED]
- High-fidelity SQLite schema (v17).
- Master Sync script to fetch all 7 sources from BaniDB.
- Offline-first search with instant initials lookup.
- Remote Fallback for Web version.

## Milestone 3: Search Polish & History [IN PROGRESS]
- Smart Roman phonetic mapping (kh, gh, etc.).
- Persistent Search History with self-contained metadata.
- Immersive Shabad reading view.
- Advanced display settings (Font +/- and Visibility toggles).
- **TODO:** Stabilize Vishram (Pause) UI highlighting.

## Milestone 4: Voice Search Integration
- Integration of `speech_to_text`.
- Mapping voice input to `GurmukhiProcessor`.

## Milestone 5: Full Word Search
- Full text search (FTS) within verses.
