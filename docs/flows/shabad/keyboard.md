# Flow: Custom In-App Keyboard

This document explains how the custom Punjabi and English keyboards work within the search tab.

## 1. Visibility & Toggle
The state of the keyboard is managed in `keyboard_providers.dart` (lib/features/search/presentation/providers/keyboard_providers.dart).
- In the Search AppBar, the keyboard icon opens a side menu (Drawer).
- Switching "Show Custom Keyboard" updates the `customKeyboardVisibleProvider`.
- `SearchScreen` listens to this and shows/hides the `CustomKeyboard` widget at the bottom.

## 2. Typing Flow
The `CustomKeyboard` widget (lib/features/search/presentation/widgets/custom_keyboard.dart) contains the buttons for Punjabi or English letters.
- When a user taps a key (e.g., 'ੳ' or 'Q'), it calls `append` on the `searchQueryProvider`.
- This updates the global search string.

## 3. Synchronizing with Search Bar
- `SearchScreen` uses a `ref.listen` on the `searchQueryProvider`.
- Whenever the provider changes (because the user typed on the custom keyboard), it manually updates the text in the `SearchBar` controller.
- This ensures that what you type on the custom keys shows up in the search box at the top.

## 4. Switching Languages
In the side menu, the user can pick "Punjabi" or "English".
- Selecting a new language triggers `setType` in the `KeyboardTypeNotifier`.
- **Reset Logic**: To ensure a clean start, switching keyboards automatically clears the current search text so the user can begin a new query in the chosen language.
