# Flow: Nitnem Tracker - Creating Goals

This document explains how a user sets up a new spiritual goal to track.

## 1. Starting the Wizard
In the Tracker Tab, the user taps the plus (+) button.
- This opens `TrackerCreationWizard` (lib/features/tracker/presentation/tracker_creation_wizard.dart).

## 2. Step 1: Template Selection
The user picks one of four types:
- **Mool Mantar / Simran**: For counting repetitions.
- **Bani Count**: For counting how many times a path is read (e.g., 5 Japji Sahibs).
- **Sehaj Path**: For tracking progress through the 1430 pages (Angs) of Sri Guru Granth Sahib Ji.

## 3. Step 2: Configuration
Based on the template, the user enters details:
- **Title**: A name for the goal.
- **Target**: The total count (e.g., 1.25 Lakh).
- **Duration**: The user can pick a "Deadline Date" using a calendar, or select "Infinite" if they don't have a specific end date in mind.
- **Start Date**: When they began this discipline.

## 4. Persistence
Once the user clicks "Create Tracker":
- The `trackerViewModelProvider` calls the `TrackerRepository`.
- A new row is inserted into the `trackers` table in the `user_tracker.sqlite` database.
- The user is taken back to the dashboard where their new goal appears as a card.
