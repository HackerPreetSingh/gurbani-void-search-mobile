# Gurbani Search

An offline-first, cross-platform Gurbani discovery application. The long-term
goal is respectful, fast Punjabi and Roman Punjabi search, with excellent
offline voice search. The search engine is designed to be a separately tested
product core; the Flutter UI consumes it rather than owning its business logic.

## Current milestone

Milestone 1 is complete: a responsive Material 3 application shell, routing,
Riverpod dependency injection, and a versioned local SQLite lifecycle work on
the supported Flutter targets. No Gurbani corpus or search result is bundled
yet. This is intentional: corpus provenance and licence obligations must be
resolved before a distribution is introduced.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

For the browser, Drift uses the checked-in `web/sqlite3.wasm` and
`web/drift_worker.js` runtime assets. Rebuild these from the matching Drift
release when the Drift dependency changes.

Architecture, dependency rationale, content stewardship, and future search and
voice decisions are recorded in [docs/DECISIONS.md](docs/DECISIONS.md).
