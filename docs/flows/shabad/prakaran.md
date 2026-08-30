# Flow: Prakaran (Shabad Folders)

This document explains how users organize Shabads into custom folders.

## 1. Adding a Shabad to a Folder
While viewing a Shabad in `ShabadScreen` (lib/features/search/shabad/presentation/shabad_screen.dart):
- The user taps the "Add Folder" icon in the top bar.
- This opens the `AddToPrakaranDialog` (lib/features/prakaran/presentation/widgets/add_to_prakaran_dialog.dart).

## 2. Creating or Selecting a Folder
Inside the dialog:
- The app lists all existing folders (Prakarans) from the `user_tracker.sqlite` database using `PrakaranRepository`.
- **Existing**: Tapping a folder name immediately adds the Shabad ID and its Gurmukhi title to that folder.
- **New**: The user can tap "Create New", type a name, and the app will create the folder first, then add the Shabad to it.

## 3. Managing Folders
From the main Search Tab, the user taps the folder icon on the top left.
- This opens `PrakaranListScreen` which lists all custom folders.
- Users can delete an entire folder here (a confirmation popup is shown first).

## 4. Viewing Folder Content
Tapping a folder opens `PrakaranDetailsScreen`.
- It lists all Shabads saved inside that specific folder.
- Tapping a Shabad name takes the user directly to the reading view for that Shabad.
- Users can also remove individual Shabads from the folder using the red minus icon.
