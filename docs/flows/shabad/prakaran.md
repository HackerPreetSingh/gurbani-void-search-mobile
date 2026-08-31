# Flow: Prakaran (Shabad Folders)

This document explains how users organize Shabads into custom folders.

## 1. Adding a Shabad to a Folder
While viewing a Shabad in `ShabadScreen` (lib/features/search/shabad/presentation/shabad_screen.dart):
- The user taps the "Add Folder" icon in the top bar.
- **Line Persistence**: If the user reached this Shabad via a specific search result (highlighted line), the app captures that line's `verse_id` and text.
- This opens the `AddToPrakaranDialog` (lib/features/prakaran/presentation/widgets/add_to_prakaran_dialog.dart).

## 2. Creating or Selecting a Folder
Inside the dialog:
- The app lists all existing folders (Prakarans) from the `user_tracker.sqlite` database using `PrakaranRepository`.
- **Existing**: Tapping a folder name adds the Shabad ID, the specific `verse_id` (if any), and the Gurmukhi title to that folder.
- **New**: The user can tap "Create New", type a name, and the app will create the folder first, then add the item to it.
- **Refresh**: The app automatically clears the cached list for that folder so the new item appears immediately.

## 3. Managing Folders
From the main Search Tab, the user taps the folder icon on the top left.
- This opens `PrakaranListScreen` which lists all custom folders.
- Users can delete an entire folder here (a confirmation popup is shown first).

## 4. Viewing Folder Content
Tapping a folder opens `PrakaranDetailsScreen`.
- It lists all items saved inside that specific folder.
- **Smart Opening**: Tapping an item takes the user to the reading view. If a specific `verse_id` was saved, the app automatically scrolls to and highlights that exact line.
- Users can also remove individual items from the folder using the red minus icon.
