# Flow: Nitnem Tracker - Progress Logging

This document explains how a user records their daily spiritual progress.

## 1. Entry Point
From the Tracker Dashboard or the Goal Details page:
- The user taps "Update Progress".
- This opens the `ProgressUpdateModal` (lib/features/tracker/presentation/progress_update_modal.dart).

## 2. Input Modes
Users can log progress in two ways:
- **Raw Units**: Entering a plain number (e.g., 500).
- **Maala Mode**: For Simran, users can enter "Maalas" (sets of 108). The app automatically calculates the raw count (e.g., 2 Maalas = 216).

## 3. Date Selection
- Users can log progress for "Today" (default) or pick a past date using the calendar icon. This is useful if they forgot to log yesterday's progress.

## 4. Saving the Log
When "Save" is clicked:
- A new entry is added to the `tracker_logs` table in `user_tracker.sqlite`.
- Each log is tied to a specific `tracker_id`.
- Multiple "chunks" can be added for the same day (e.g., 100 in the morning and 100 in the evening). The app will sum them up automatically.

## 5. Deletion Flow & Stability
When a user deletes a tracker goal or a log entry:
- **Immediate State Update**: The `TrackerViewModel` removes the item from the in-memory list **synchronously** before awaiting the database deletion. 
- **Purpose**: This prevents "Dismissible widget still part of tree" errors in Flutter by ensuring the widget tree and the data state are perfectly synchronized during the swipe animation.
