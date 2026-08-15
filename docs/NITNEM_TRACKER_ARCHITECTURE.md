# Detailed Architecture: Nitnem Tracker (Refined)

This document provides the technical specification for the Nitnem Tracker. It defines the database schema, mathematical logic for specific templates, and the UI interaction model.

---

## 1. Data Layer: `user_tracker.sqlite`
A dedicated private database for user progress.

### 1.1 Table: `trackers` (The "Goals")
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | TEXT (UUID) | Unique identifier for the goal. |
| `template_type` | TEXT | `mool_mantar`, `simran`, `bani_count`, `sehaj_path`. |
| `title` | TEXT | Custom name or Bani name (e.g., "Japji Sahib Daily"). |
| `total_goal` | INTEGER (NULL) | Total units to finish. Null if "Infinite/Lifetime". |
| `daily_target` | INTEGER (NULL) | Units expected per day. Null if "Free Hand". |
| `start_date` | TEXT | ISO8601 (Selected via Calendar). |
| `deadline_date`| TEXT (NULL) | ISO8601 (Selected via Calendar). Null if Infinite. |
| `unit_name` | TEXT | "Units", "Maala", "Path", "Ang". |

### 1.2 Table: `tracker_logs` (The "Chunks")
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INTEGER PK | Primary Key. |
| `tracker_id` | TEXT FK | Link to the `trackers` table. |
| `log_date` | TEXT | The date entry counts for (YYYY-MM-DD, selected via Calendar). |
| `count` | INTEGER | The raw units done in this chunk. |
| `input_mode` | TEXT | `raw` or `maala` (for Simran). |
| `created_at` | TEXT | System timestamp. |

---

## 2. Template Logic & Workflows

### 2.1 Mool Mantar & Waheguru Simran (3 Modes)
Users can configure their spiritual discipline in three ways:
1. **Fixed Goal**: Input `Total Target` + `Days`.
   - `daily_target = Total / Days`.
2. **Infinite Commitment**: Select "Infinite Days" + Input `Daily Count`.
   - `total_goal = null`.
   - `daily_target = User Input`.
3. **Free Hand**: Select "Infinite Days" + No Daily Count.
   - `total_goal = null`.
   - `daily_target = null`. 
   - Tracking focuses on *Daily Averages* and *Streaks* rather than a completion bar.

**Conversion Logic**: 1 Maala = 108 Units. Entry UI allows mixed input (e.g., 2 Maala + 50 Units), stored as `(2 * 108) + 50 = 266`.

### 2.2 Bani Count (e.g., Japji Sahib)
- **Bani Selection**:
   - Provide a list of common Banis (Japji Sahib, Jaap Sahib, Tav Prasad Savaiye, Chaupai Sahib, Anand Sahib, Sukhmani Sahib, Rehras Sahib, Sohila).
   - Freedom to type any **Custom Name** for other compositions.
- **Goal**: Daily target (e.g., 10 Japji Sahib paths per day).
- **Unit**: 1 Path = 1 Unit. No partial "Maala" concept here.

### 2.3 Sehaj Path
- **Fixed Boundary**: 1430 Angs.
- **Workflow**:
   - Option A: Deadline Calendar -> Calculate `1430 / remaining days`.
   - Option B: Daily Count -> User commits to `X` Angs per day.
- **Progress**: Tracking is cumulative based on the "Current Ang Reached" input.

---

## 3. UI Component Specification

### 3.1 Date Selection (Global)
- **NO TEXT INPUT**: All dates (Start Date, Deadline, Log Date) MUST use a **Calendar Picker** (standard Material 3 `showDatePicker`).

### 3.2 Bani Selection UI
- A searchable **Dropdown/Type-ahead** component.
- If the user types a name not in the predefined list, it is accepted as a custom title.

### 3.3 Status Analytics (The "RAG" Engine)
For daily history rows ($D$):
- **🟠 Orange**: Total for day $D == daily\_target$.
- **🔴 Red**: Total for day $D < daily\_target$.
- **🟢 Green**: Total for day $D > daily\_target$.
- *Note*: If `daily_target` is null (Free Hand), rows are default ⚪ Gray/Neutral or use a weekly average for comparison.

---

## 4. Roadmap (Execution Steps)

### Phase 1: Database & Core Models
- Implementation of `user_tracker.sqlite`.
- Logic for the `initials_en` repairs (already complete in engine).

### Phase 2: Creation Wizard (The "Picker")
- Build the 4 template flows.
- Integrate the **Calendar Picker** for all date-related settings.
- Implement the "Bani Search/Custom Name" input.

### Phase 3: Update & Analytics Engine
- Build the "Chunked Entry" modal (Maala vs Raw toggle).
- Implement mathematical logic for Infinite vs Fixed goals.

### Phase 4: History & Polish
- Tabular descending history with color-coding.
- Edit/Delete with confirmation popups.
- Documentation for the final "Custom" extension.
