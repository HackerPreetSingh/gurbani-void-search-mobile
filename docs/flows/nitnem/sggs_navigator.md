# Flow: Whole SGGS Ang Navigator

This document explains the specialized page-based reading system for the full Sri Guru Granth Sahib Ji.

## 1. Concept
Unlike individual Shabads or Nitnem paths, the full scripture is often read page-by-page (Ang-wise). The `SggsAngScreen` provides a "Pothi-style" experience for this.

## 2. Data Fetching
When an Ang is selected:
- The app calls `getVersesForAng(ang, 'G')`.
- This performs a high-speed SQL query against the `verses` table in `shabads_offline.sqlite`, filtering specifically for `source_id = 'G'` (Guru Granth Sahib) and the requested `ang`.
- It returns all verses that appear on that physical page.

## 3. The Bottom Navigator
A fixed control bar at the bottom of the screen provides three main functions:
- **Previous Ang**: Decrements the current Ang (disabled on Ang 1).
- **Next Ang**: Increments the current Ang (disabled on Ang 1430).
- **Ang Display & Jump**: Displays the current page number. Tapping it opens the "Go to Ang" dialog.

## 4. Direct Page Jump
Inside the "Go to Ang" dialog:
- The user can type a specific number (1 to 1430).
- Upon confirmation, the app updates the state, triggering an immediate re-fetch of that page's content.
- This allows for lightning-fast navigation across the entire 1430-page scripture.

## 5. Integration
- **Display Settings**: The navigator respects all global display settings, including Font Size (Pinch-to-Zoom), Larivaar, and Vishram (colored pauses).
- **Wakelock**: The screen is kept active automatically while reading to prevent the phone from timing out.
