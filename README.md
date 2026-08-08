# Gurbani Voice Search

A fast, offline-first Gurbani search application built with Flutter. This project aims to provide a near-instant search experience for Gurbani sources (SGGS, Dasam Granth, etc.) across mobile and web.

## Quick Start for Developers

### 1. Requirements
* Flutter SDK (Latest Stable)
* Dart SDK

### 2. Setting Up the Database
This app uses a pre-baked SQLite database for high performance on mobile. You need to generate this file before running the app for the first time or if you change the sync logic.

```bash
# Sync data from BaniDB API to local asset
dart bin/sync_production_data.dart
```

### 3. Running the App
```bash
# Mobile (Android/iOS)
flutter run

# Web
flutter run -d chrome
```

## Project Structure
The project follows clean architecture and SOLID principles:

* `lib/core`: Infrastructure like database connection and global providers.
* `lib/features/search`: Everything related to searching and viewing Shabads.
* `lib/features/settings`: User preferences and persistence.
* `lib/app`: App-wide configuration (routing, themes).

## Documentation
Check the `docs/` folder for deeper insights:
* `ARCHITECTURE_FLOW.md`: How data flows from a user's search to the screen.
* `HANDOFF.md`: Current state of the project and technical details.
* `Roadmap.md`: What's coming next.
