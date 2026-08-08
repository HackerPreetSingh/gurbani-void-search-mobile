# Project Handoff: Current State

This document outlines the current state of the Gurbani Voice Search project and what you need to know to continue development.

## Tech Stack
* **Framework**: Flutter (Web & Mobile)
* **Database**: Drift (SQLite)
* **State Management**: Riverpod
* **Networking**: Dio
* **Navigation**: GoRouter

## What's Working
1. **High-Performance Search**: The database uses a denormalized schema and covering indexes. This means most searches happen in under 100ms on mobile.
2. **Offline Mode**: On first launch, the app copies a 50MB production database to the phone. No internet is needed for searching or reading.
3. **Multi-Platform Support**: Works on Web (via remote API) and Mobile (via local SQLite).
4. **Display Options**: Users can toggle English Meaning, Punjabi Meaning (Teeka), Hindi, and Pauses (Vishrams). Font sizes are independent and persist even after closing the app.
5. **Robust Sync**: The `bin/sync_production_data.dart` script is ready to refresh the local data from the BaniDB API whenever needed.

## Key Code Locations
* `lib/features/search/data`: Contains the data sources and the main repository that decides between local and remote search.
* `lib/features/search/domain/services/vishram_service.dart`: The logic for word-level highlighting (pauses).
* `lib/core/database/local_database.dart`: Handles the SQLite connection and initial asset copy.
* `lib/features/settings`: Manages user preferences using the `app_metadata` table in SQLite.

## Critical Notes for Developers
* **Database Changes**: If you add columns to the database, you must update the sync script in `bin/` and the in-app `ProductionIngestor.dart`.
* **SOLID Principles**: The code is decoupled. Data sources handle raw data, mappers handle conversion, and repositories coordinate. Try to keep this separation as you add features.
* **Testing Performance**: Always test search speed with common initials like "s" or "g" to ensure the covering index is being used.
