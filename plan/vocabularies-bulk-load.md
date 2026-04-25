# Vocabularies Bulk Load Refactor

## Problem
`SKVocabulariesViewModel` loaded words letter-by-letter sequentially. User scrubbing to "С" → section empty because task still loading "А"–"Р". Two bugs compounded:
1. Sequential per-letter loading = scrub-ahead = empty sections
2. SwiftUI `List` + `ScrollViewProxy.scrollTo` is O(n) — must compute layout for all rows above target → ~5s to jump to "Ш" even after full load

## Solution
Replaced SwiftUI `UIHostingController` wrapper with a native `UIViewController` + `UITableView`.

- **Bulk load** via raw C SQLite API: one query loads all ~107k words atomically, then scrubbing is instant
- **Native section index** (`sectionIndexTitles`): UIKit's built-in scrubber jumps to any letter in O(1) — no layout computation

## Why raw C SQLite API
SQLite.swift `Statement` iterator: ~2μs/row overhead.
`sqlite3_step` + `sqlite3_column_*` direct: ~0.3μs/row — 5–7× faster.
107k rows × 0.3μs ≈ **~200–400ms** total. Brief spinner, then instant scrubbing.

## SQL query
```sql
SELECT word_id, word, first_char FROM vocabulary WHERE lang_id = ? ORDER BY lword
```
Query plan: `SCAN vocabulary USING INDEX lword_lang_index` — no temp B-TREE sort.

## Implementation

### `SKVocabularyIndex.allWords(vocabularyType:)`
- `import SQLite3` alongside existing `import SQLite`
- Raw C API via `db.handle` (`public` in SQLite.swift 0.13.3)
- SQL rows collected into `[String: [SKWord]]` dictionary keyed by `first_char`
- **Do not rely on SQL row order for section order** — SQLite binary collation sorts Cyrillic by Unicode code point: `ё` (U+0451), `і` (U+0456), `ў` (U+045E) all fall above `я` (U+044F), placing them after Я in byte order
- Final output reconstructed by iterating `abcBe`/`abcRu` alphabet arrays — correct linguistic order guaranteed
- Filters via `Set(alphabet)` — skips unexpected `first_char` values
- Returns `[(title: String, words: [SKWord])]` in correct alphabet order; words within each section remain sorted by `lword` from SQL

### `SKVocabulariesTableViewController`
- `UIViewController` with embedded `UITableView` + fixed `UISegmentedControl` header
- `UIActivityIndicatorView` shown during load; `tableView.isHidden` until data ready
- `Task { await Task.detached { allWords() }.value }` — bulk fetch off main thread, result set atomically
- `sectionIndexTitles` → `sections.map(\.title)` — native UIKit scrubber
- `sectionForSectionIndexTitle(_:at:)` → direct index passthrough
- `defaultContentConfiguration()` for cells (iOS 14+)
- Tab switch: cancels in-flight task, resets state, starts new load

### Removed
- `SKVocabulariesView.swift` — SwiftUI view + ViewModel deleted entirely
- Project file references cleaned up

## Memory
~107k words × ~80 bytes ≈ ~8.5 MB per dictionary type. One type at a time. Acceptable.

## Risks
- `db.handle` is `public` in SQLite.swift 0.13.3 — verify when upgrading SQLite.swift
