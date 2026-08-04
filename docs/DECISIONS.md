# Architecture decisions

## M1 — application foundation (2026-08-02)

### Project structure

The app uses a pragmatic Clean Architecture structure:

```text
lib/
  app/                 application composition, theme, router, responsive shell
  core/                cross-cutting infrastructure and dependency providers
  features/<feature>/  domain, data, and presentation code when that feature exists
```

Feature code will own its domain contracts and repository interfaces. Data
implementations will live beside the feature and depend inward on those
contracts; presentation depends on the domain, never on SQLite or a remote API.
M1 has no search domain or corpus yet, so it deliberately does not introduce
empty repository interfaces or unused layers. `LocalDatabase` is real shared
infrastructure: it opens, migrates, verifies, and closes the database that
future feature repositories will use.

### State management and dependency injection — Riverpod 3

Riverpod provides scoped dependency injection, explicit async state, and
straightforward test overrides without coupling business logic to widgets.
This suits database lifecycle, search sessions, downloadable corpus state, and
future audio sessions. Provider was not selected because its dependency and
async lifecycle story is less explicit at this scale. BLoC was not selected
because event/reducer boilerplate would add indirection before the product has
complex interaction workflows. Riverpod’s provider overrides make the app
testable with an in-memory database. See the [Riverpod documentation](https://riverpod.dev/)
for its provider and testing model.

### Navigation — go_router

`go_router` owns URLs, deep links, browser history, and a responsive shell in
one routing definition. This avoids a mobile-only navigator hierarchy that
would be difficult to retrofit for web, desktop, saved searches, and shared
links. M1 exposes the foundation and About destinations only; a search route
will be introduced with the actual search feature, not as an empty screen.

### Local persistence — Drift and SQLite

Drift is the SQLite access layer because its one Dart API supports native
SQLite on Android, iOS, macOS, Windows, and Linux plus SQLite WebAssembly on
the web. `LocalDatabase` uses Drift’s connection-opening lifecycle, versioned
migrations, foreign-key enforcement, and `PRAGMA integrity_check`. The schema
starts with only application metadata; it contains no pretend corpus tables.

The web build includes Drift 2.34.3-compatible `sqlite3.wasm` and
`drift_worker.js`. Both files must be updated together with Drift. Future PWA
deployment will enable the documented cross-origin isolation headers when the
chosen browser SQLite configuration benefits from them. See Drift’s
[platform](https://drift.simonbinder.eu/platforms/) and
[web](https://drift.simonbinder.eu/platforms/web/) guidance.

### Search-engine direction (not implemented in M1)

The BaniDB reference implementation establishes useful search semantics:
Gurmukhi initials, full Gurmukhi words, Roman Punjabi initials, Roman Punjabi
words, bindi-aware normalisation, and result metadata. The Next.js MVP
confirms that a build-time initial index is practical at corpus scale. The M2
engine will keep these transformations out of widgets and build immutable,
versioned search indexes during corpus import:

- canonical line and source records;
- normalised Gurmukhi and Roman tokens;
- Gurmukhi and Roman initial sequences;
- query-type detection and query normalisation;
- searchable projections separate from display text and translations.

Indexes will be benchmarked against the under-50 ms target with a representative
corpus before their schema becomes a stable release contract.

### Corpus provenance and licensing

BaniDB’s code repository is MIT-licensed, but that does not grant a right to
redistribute its corpus or imply that its service terms do not apply. BaniDB’s
[terms](https://www.banidb.com/tos/) and the
[NPOSL](https://www.banidb.com/nposl/) impose attribution, full-corpus/update and contribution or
support obligations for external use. No BaniDB data, the Next.js MVP database,
or derived index is included in this app until its provenance, exact licence,
update process, attribution, and contributor obligations have been approved.

This separation keeps M1 usable and legally honest: the app reports that no
corpus is installed instead of fabricating search results.

### Voice-engine research decision

The future offline speech-recognition candidate is
[**whisper.cpp**](https://github.com/ggml-org/whisper.cpp). It has
offline native integrations for Apple platforms, Android, Linux, Windows and
macOS, a WebAssembly path, and exposes Punjabi (`pa`) language support.
[Moonshine](https://github.com/moonshine-ai/moonshine)’s documented current
language list does not include Punjabi.
TensorFlow Lite and MediaPipe are runtimes rather than ready, cross-platform
Punjabi ASR engines; adopting them would require training, conversion, and
maintaining a model pipeline.

This is an engine selection, not yet a model selection. Before the speech
milestone, whisper.cpp models must be benchmarked on a responsibly licensed,
representative Punjabi/Gurbani audio set. The acceptance record must include
word and character error rates, cold-start latency, real-time factor, peak
memory, model size, and target-device coverage. Only then will the native and
web bridges be added.

### Dependencies introduced in M1

| Dependency | Reason |
| --- | --- |
| `flutter_riverpod` | Scoped dependency injection, async state, and test overrides. |
| `go_router` | Declarative, URL-aware navigation across mobile, desktop, and web. |
| `drift` | Cross-platform SQLite API and safe database lifecycle. |
| `drift_flutter` | Flutter platform opening support for native and web database executors. |

No speech, search, networking, or UI component dependency was added without
an implemented use case.

## M2 — Search Engine: Gurmukhi (2026-08-04)

### Gurmukhi Normalization and Folding

To achieve a forgiving and intuitive search experience, the Gurmukhi engine implements comprehensive character folding during both indexing and query parsing:
- **Vowel Folding:** All variations of dependent and independent vowels are folded to their base carriers (e.g., `ਆ`, `ਐ`, `ਔ` -> `ਅ`; `ਇ`, `ਈ` -> `ੲ`; `ਉ`, `ਊ` -> `ੳ`). This ensures "Initials" search works even if the user provides the "wrong" carrier or vowel.
- **Ik Onkar:** The `ੴ` symbol is explicitly folded to its phonetic base `ੳ` (Ura) to match user input habits.
- **Special Marks:** Bindi, Tippi, and Adhak are folded to canonical forms for word search while being ignored for initials search.

### Search Orchestration (Riverpod 3 Notifier)

The `SearchViewModel` follows the modern Riverpod 3 `Notifier` pattern. It implements a **150ms debounce** to maintain the <50ms latency target on the database layer while preventing unnecessary churn on the UI thread during rapid typing. The state is managed as an `AsyncValue<PunjabiSearchResponse?>`, providing a clear path for loading, error, and empty states.

### Offline Data Ingestion

The `CorpusImportService` provides a production-ready path for importing immutable Gurbani corpora from JSON assets. **In Milestone 2, this was verified using a 3-line sample corpus (`sample_corpus.json`) to validate engine accuracy and performance without legal or storage overhead. The distribution and indexing of the full production corpus remains a separate data-integrity task.**

### UI Integration

The `SearchScreen` uses the Material 3 `SearchBar` and `ListView` to provide a responsive, cross-platform interface. It uses semantic labels to distinguish between "Initial" and "Word" matches, allowing the user to understand why a result was returned.
