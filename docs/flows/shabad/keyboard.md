# Flow: Custom In-App Keyboard

This document explains how the custom Punjabi and English keyboards work within the search tab.

## 1. Visibility & Lifecycle
The state of the keyboard is managed in `keyboard_providers.dart` (lib/features/search/presentation/providers/keyboard_providers.dart).
- **Permanent Use**: The system keyboard is permanently disabled on the Shabad Search screen (`keyboardType: TextInputType.none`). The custom keyboard is the mandatory input method.
- **Auto Re-open**: If the keyboard is minimized/hidden, tapping the search text box will automatically re-open it.
- **Settings**: In the Search AppBar, the keyboard icon opens a side menu (Drawer) to switch between Punjabi and English layouts.

## 2. Typing Flow
The `CustomKeyboard` widget (lib/features/search/presentation/widgets/custom_keyboard.dart) contains the buttons for Punjabi or English letters.
- When a user taps a key (e.g., 'ੳ' or 'Q'), it calls `append` on the `searchQueryProvider`.
- This updates the global search string.

## 3. Synchronizing with Search Bar
- `SearchScreen` uses a `ref.listen` on the `searchQueryProvider`.
- Whenever the provider changes (because the user typed on the custom keyboard), it manually updates the text in the search box controller.
- **Cursor Management**: The app ensures the cursor remains visible and positioned at the end of the text even though the field is not using a system keyboard.

## 4. Switching Languages & Layouts
In the side menu, the user can pick "Punjabi" or "English".
- Selecting a new language triggers `setType` in the `KeyboardTypeNotifier`.
- **English Default**: The English keyboard now uses **lowercase letters** by default for a more natural phonetic typing experience.
- **Iconic Controls**: Replaced text labels with intuitive icons for Backspace, Space, and Done.
- **Quick Clear**: Added a dedicated "Clear All" icon (trash icon) to the bottom-left of the keyboard to wipe the search box instantly.
- **Reset Logic**: Switching keyboards automatically clears the current search text.
