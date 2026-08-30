# Flow: Nitnem & Bani Reading

This document explains how liturgical paths (Banis) are displayed and read.

## 1. Selection
In the Nitnem Tab, the user sees a list of Banis (Japji Sahib, Jaap Sahib, etc.).
- The list is fetched from the Nitnem Database via `banisListProvider`.
- Users can drag and drop these to change their daily routine order.

## 2. Loading Content
When a Bani is selected, `BaniScreen` (lib/features/search/bani/presentation/bani_screen.dart) is opened.
- It uses `baniDetailsProvider` to fetch all verses from the `nitnem_offline.sqlite` database.
- **Strict Ordering**: Verses are sorted by a `sequence_order` column to ensure they appear in the correct liturgical order, which is different from search results.

## 3. Special Reading Modes
- **Vishram (Pauses)**: The `VishramService` checks the database for pause markers. If the "Pauses" setting is ON, it colors specific words (Green for main pause, Blue for secondary) to help with correct pronunciation.
- **Larivaar (Continuous)**: If the "Larivaar" setting is ON, the app removes all spaces between Gurmukhi words, presenting the text in the traditional continuous script style.
- **Jaap Sahib Layout**: For Jaap Sahib specifically, verses are not shown line-by-line. Instead, they are grouped into paragraphs using the `BaniParagraphView` for a more authentic pothi experience.

## 4. Gestures & Navigation
- **Pinch-to-Zoom**: Users can pinch in or out anywhere on the reading screen to dynamically adjust the font size. This updates the global Gurmukhi font size setting.
- **Clean Interface**: The main Bani list now only displays the traditional Punjabi names, removing English subtitles for a focused liturgical experience.
