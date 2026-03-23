# Skarnik for iOS: Project Overview

## Project Idea
**Skarnik** is a comprehensive Russian-Belarusian, Belarusian-Russian, and Belarusian explanatory (TSBM) dictionary application for iOS. It is based on the popular [skarnik.by](https://skarnik.by) service. The app provides quick search and detailed word entries, including word stress and spelling information.

## Architecture
The project uses a hybrid architecture combining established UIKit patterns with modern SwiftUI and Combine.

- **Presentation Layer:**
    - **UIKit:** Used for the main application structure, including `SKSplitViewController`, `SKSearchWordsTableViewController`, and `SKVocabulariesTableViewController`.
    - **SwiftUI:** Employed for specific features like the `SKWordStressView` and the `WordWidget`.
    - **MVVM + Combine:** The `SKWordDetailsViewController` and `SKWordStressView` follow the Model-View-ViewModel pattern, using Combine for reactive state management.
- **Data Layer:**
    - **Local Indexing:** A local SQLite database (`vocabulary.db`) stores the word list, allowing for fast, offline-capable searching and indexing.
    - **Remote Fetching:** Detailed word translations are fetched on-demand from `skarnik.by` and parsed using `SwiftSoup`.
    - **Supplementary Data:** Pronunciation (word stress) and spelling suggestions are retrieved from `starnik.by`.
- **Services & Managers:**
    - **SKVocabularyIndex:** The primary interface for querying the local SQLite database.
    - **SKTranslationSource (protocol):** Defines the interface for all translation data sources. Concrete implementations: `SKHtmlTranslationSource` (HTML scraping via SwiftSoup), `SKApiTranslationSource` (JSON API, stub), `SKSupabaseTranslationSource` (Supabase, stub). `SKFallbackTranslationSource` composes them into a priority chain (API → Supabase → HTML). All defined in `SKTranslationSource.swift`. `SKSkarnikByController` is kept as a `typealias` for `SKHtmlTranslationSource` for backward compatibility.
    - **SKStarnikByController:** Handles word stress/spelling data fetching and parsing.
    - **SKStorageController:** Manages user search history using `UserDefaults`.
    - **SKAnalyticsManager:** A wrapper for Firebase and debug analytics.
    - **SKWordFetchService:** Orchestrates word retrieval for features like the "Word of the Day" widget. Accepts `SKTranslationSource` via init (defaults to `SKFallbackTranslationSource.shared`).

## Tech Stack
- **Language:** Swift
- **UI Frameworks:** UIKit (Storyboards & Programmatic), SwiftUI, WidgetKit.
- **Reactive Framework:** Combine.
- **Database:** SQLite (via [SQLite.swift](https://github.com/stephencelis/SQLite.swift)).
- **Networking:** `URLSession` with custom extensions.
- **HTML Parsing:** [SwiftSoup](https://github.com/scinfu/SwiftSoup).
- **Analytics:** Firebase (Google Analytics).
- **Dependency Management:** Swift Package Manager (SPM).
- **Localization:** Supports Belarusian (`be`) and Base (likely Russian/English defaults).

## Key Files & Directories
- `Skarnik/Shared/SKVocabularyIndex.swift`: Local database queries.
- `Skarnik/Shared/SKTranslationSource.swift`: Main translation fetching logic.
- `Skarnik/SKSearchWordsTableViewController.swift`: Search UI.
- `Skarnik/SKWordDetailsViewController.swift`: Word entry display (MVVM).
- `WordWidget/`: iOS Widget implementation.
- `Skarnik/vocabulary.db`: The core search index.
- `SkarnikTests/SKTranslationSourceTests.swift`: Unit tests for translation logic and HTML parsing.

## Testing Strategy
- **Unit Tests:** Focus on testing core business logic, such as HTML parsing, URL generation, and color conversion.
- **Mocking:** Currently, the project requires `@testable import` to access internal methods. `SKTranslationSource` protocol enables injecting mock sources into `SKWordDetailsViewModel` and `SKWordFetchService` via their `init(translationSource:)` parameter. Future improvements could include Dependency Injection to allow easier mocking of `URLSession` and `SKVocabularyIndex`.
- **Async Tests:** Modern Swift concurrency (`async/await`) is used in tests for methods like `attributedString`.
