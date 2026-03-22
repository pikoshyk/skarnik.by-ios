# Skarnik for iOS: Testing Roadmap & Priorities

This document outlines the prioritized testing strategy for the Skarnik project, focusing on critical business logic, data integrity, and resilience against external changes.

## 1. Search Logic & Query Preprocessing (Critical)
The application's core value is its offline search capability. The complexity of SQL generation and Belarusian/Russian character mapping makes this a top priority.

- **Target:** `SKVocabularyIndex.swift`
- **Key Focus Areas:**
    - **Query Normalization:** Verify `preprocessQuery` correctly maps characters (e.g., `и` -> `і`, `е` -> `ё`, `щ` -> `ў`) based on query length and vocabulary type.
    - **Search Rules:** Ensure `requiredAdditionalSearchRules` correctly toggles advanced search modes.
    - **Result Consistency:** Validate that `wordsCount` and `word(index:...)` return consistent results for both exact matches and prefix searches.
    - **Pagination:** Test `offset` and `limit` logic for long result lists.
- **Status:** Initial tests implemented in `SKVocabularyIndexTests.swift`.

## 2. HTML Parsing & Translation Extraction (Critical)
The app relies on external HTML from `skarnik.by`, which is brittle and prone to breakage if the website's structure changes.

- **Target:** `SKSkarnikByController.swift` (and `SKSkarnikTranslation`)
- **Key Focus Areas:**
    - **Complex Word Extraction:** The `belWords` property uses `SwiftSoup` to extract reverse translations from HTML. This is complex and requires rigorous testing with various HTML samples.
    - **Dynamic Recoloring:** Validate that `recoloredHtml` correctly applies theme-aware colors (via regex) for Dark Mode compatibility.
    - **Error Handling:** Ensure `parseHtml` correctly identifies "Redirect" (`rdr`) blocks and triggers the `nextWordIndexRequired` error.
    - **Async Fetching:** Test the `attributedString` generation for UI responsiveness.
- **Status:** Basic tests exist; needs more robust `rus_bel` extraction scenarios.

## 3. Phonetic Normalization for Widgets (High)
The "Word of the Day" widget uses phonetic and spelling normalization to ensure quality and prevent repetitive or near-duplicate entries.

- **Target:** `SKWordFetchEntry.swift`, `SKLevenshtein.swift`
- **Key Focus Areas:**
    - **Phonetic Mapping:** Verify `replaceLetters` correctly handles complex Belarusian phonetic rules (e.g., `ся` -> `ца`, `ий` -> `і`).
    - **Similarity Logic:** Test `levenshteinDistance` and `isSimilar` against words that are phonetically identical but spelled differently.
    - **Widget Variety:** Ensure `fetchRandomWord` correctly retries when a similar word is encountered.
- **Status:** Untested; high priority for widget stability.

## 4. User Persistence & History (Medium)
Ensuring a reliable and performant search history is key to user experience.

- **Target:** `SKStorageController.swift`
- **Key Focus Areas:**
    - **Deduplication:** Adding an existing word should move it to the top of the list rather than creating a duplicate.
    - **Limit Enforcement:** Verify the `maxWords` limit (default 100) is strictly followed.
    - **Serialization:** Test robust encoding/decoding of `SKWord` objects to `UserDefaults`.
- **Status:** Untested.

## 5. Reactive UI State Management (Medium)
The application's transitions between loading, loaded, and error states are handled via Combine.

- **Target:** `SKWordDetailsViewModel.swift`
- **Key Focus Areas:**
    - **Deep Linking:** Parsing URLs from the translation view to navigate to related words.
    - **State Transitions:** Validating that `state` correctly reflects the lifecycle of a word fetch (idle -> loading -> loaded/error).
- **Status:** Basic tests exist but struggle with `SKVocabularyIndex` dependencies.

## 6. Utilities & Extensions (Low)
Lower priority but essential for codebase health.

- **Target:** `String+Skarnik.swift`, `UIColor+Skarnik.swift`, `NSAttributedString+Skarnik.swift`
- **Key Focus Areas:**
    - Hex color conversion stability.
    - Regex substitution helpers.
    - HTML-to-attributed string conversion reliability.
- **Status:** Some coverage in `SKSkarnikByControllerTests`.

---
*Last updated: March 2026*
