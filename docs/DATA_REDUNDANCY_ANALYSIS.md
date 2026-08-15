# Data Redundancy & Redundancy Analysis

This document analyzes the current database structure for overlaps and unneeded data, providing a roadmap for future optimizations.

---

## 1. Amrit Keertan [A] vs. Primary Sources [G, D, B]
The **Amrit Keertan** source is a liturgical compilation, not an original book.

- **Redundancy**: ~95% of verses in Amrit Keertan are direct duplicates of text already present in SGGS [G], Dasam Bani [D], and Vaaran Bhai Gurdas [B].
- **Current Impact**: The app stores these as entirely separate rows in the `verses` table. A search for a common shabad results in multiple hits (one for each source).
- **Recommendation**: Keep for now to support the "Amrit Keertan Index" navigation, but in a future refactor, these should be "virtual references" to the original source verses.

---

## 2. Bhai Gurdas Ji [B] vs. [S]
There are two distinct sources often confused as duplicates:
- **Source [B]**: *Vaaran Bhai Gurdas* (The standard 40 Vaars).
- **Source [S]**: *Vaaran Bhai Gurdas Singh* (The 41st Vaar).
- **Analysis**: There is **zero overlap** here. These are different texts by different authors and must both be preserved.

---

## 3. Nitnem / Bani Sync Overlap (High Redundancy)
This is the largest area of duplication in the current architecture.

- **The Issue**: When `sync_banis.dart` runs, it downloads verses for paths like *Japji Sahib* and saves them with `source_id = 'Bani'`. However, these verses already exist in the database under `source_id = 'G'`.
- **Storage Impact**: Large Banis like *Sukhmani Sahib* (~2,000 lines) are stored **twice**—once for shabad search and once for the Nitnem tab.
- **Search Impact**: Searching for common Nitnem tukks shows duplicate results.
- **Why it exists**: To maintain strict liturgical sequencing in the `bani_verses` table without depending on the complex shabad groupings of the main corpus.

---

## 4. Refactoring Roadmap for AI Models
To reduce DB size by 30-40% and improve search clarity:
1. **Normalization**: Move Gurmukhi and Translation text to a master `verse_content` table (uniquely identified by a hash of the Gurmukhi text).
2. **Referencing**: Update the `verses` table to be a "link" table containing only metadata (source, ang, writer) and a `content_id` pointing to the master table.
3. **Filtering**: Ensure the Shabad Search tab explicitly excludes the virtual `Bani` source to avoid duplicate results in the UI.
