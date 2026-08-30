# Flow: Sukhmani Sahib Pagination

This document explains the specialized paginated reading system used only for Sukhmani Sahib.

## 1. The Challenge
Sukhmani Sahib is very long (over 2000 lines). Showing it all on one screen makes it slow and makes jumping to specific sections (Ashtapadis) difficult.

## 2. Partitioning Logic
When Sukhmani Sahib (Bani ID 31) is opened:
- The app runs `_prepareSections` in `BaniScreen`.
- It scans the 2000+ verses and breaks them into a list of 24 sections.
- Each section starts with a "Salok" header and contains the following "Ashtapadi" body.

## 3. Paginated Display
- Instead of showing everything, the app only renders the current section (e.g., Ashtapadi 5).
- This makes the screen load instantly and scroll very smoothly.

## 4. Navigation Arrows
- Two floating buttons (Previous and Next) stay fixed at the bottom of the screen.
- These buttons allow the user to flip through Ashtapadis one by one without needing to scroll through thousands of lines.
- Tapping an arrow updates the `_currentSectionIndex` state, and the `AnimatedSwitcher` performs a smooth fade transition to the new content.

## 5. Salok Styling
- Inside these pages, the app identifies the "Salok body".
- Everything from the "Salok" header until the start of the "Ashtapadi" header is colored **Dark Blue**, making the liturgical transitions visually clear.
