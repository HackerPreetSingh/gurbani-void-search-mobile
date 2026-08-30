# Gurbani Voice Search: Project Map

This document maps application features to their respective files and folders. Use this to target changes precisely.

## 1. Core Engine (Read-Only/Protected)
- **Database Architecture**: `lib/core/database/`
- **Phonetic Processing**: `lib/features/search/domain/services/gurmukhi_processor.dart`
- **Search Repository**: `lib/features/search/data/sqlite_punjabi_search_repository.dart`

## 2. Feature: Shabad Search
- **Main Page**: `lib/features/search/presentation/shabad_page.dart` (Soon to be modularized)
- **Providers**: `lib/features/search/domain/providers/shabad_providers.dart`
- **Components**: `lib/features/search/shabad/`

## 3. Feature: Nitnem & Banis
- **Main Page**: `lib/features/search/presentation/bani_page.dart` (Soon to be modularized)
- **Providers**: `lib/features/search/domain/providers/bani_providers.dart`
- **Components**: `lib/features/search/bani/`

## 4. Feature: Nitnem Tracker
- **Database**: `lib/features/tracker/data/user_tracker_database.dart`
- **Dashboard**: `lib/features/tracker/presentation/tracker_list_screen.dart`
- **Details**: `lib/features/tracker/presentation/tracker_details_page.dart`
- **Creation Wizard**: `lib/features/tracker/presentation/tracker_creation_wizard.dart`
- **Analytics**: `lib/features/tracker/domain/services/tracker_analytics_service.dart`

## 5. Feature: Prakaran (Shabad Folders)
- **Database**: Extensions in `lib/core/database/schema/tracker_schema.dart`
- **Models**: `lib/features/prakaran/domain/models/prakaran_models.dart`
- **Repository**: `lib/features/prakaran/data/prakaran_repository.dart`
- **UI**: `lib/features/prakaran/presentation/`

## 6. App Infrastructure
- **Routing**: `lib/app/router/app_router.dart`
- **Theming**: `lib/app/theme/app_theme.dart`
- **Sync/Ingestion**: `bin/sync_shabads.dart` & `lib/features/search/domain/services/shabad_sync_service.dart`
