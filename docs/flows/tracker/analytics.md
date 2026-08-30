# Flow: Nitnem Tracker - Analytics & RAG

This document explains how the app calculates if a user is ahead or behind on their goals.

## 1. The RAG Engine
RAG stands for Red, Amber (Orange), and Green. It provides visual feedback on progress.
- This logic lives in `TrackerAnalyticsService` (lib/features/tracker/domain/services/tracker_analytics_service.dart).

## 2. Status Calculation
Every time the user views a goal, the app calculates:
- **Total Done**: The sum of all logs for that goal.
- **Expected Done**: How many units should have been finished by today to meet the deadline.
- **Difference**: The "Ahead/Behind" number shown on the screen.

## 3. Visual Indicators
The colors are determined as follows:
- **🟢 Green**: The user has done MORE than the daily target today (or is overall ahead of the pace).
- **🟠 Orange**: The user has exactly met the target today.
- **🔴 Red**: The user has not yet reached the daily target for today.
- **Neutral (Grey)**: Used for "Free Hand" trackers where the user hasn't set a specific daily goal.

## 4. Formatting
The service also handles "Maala" formatting. Instead of just showing "216", it will show "2 Maala" for Simran goals to make it easier for the user to understand.
