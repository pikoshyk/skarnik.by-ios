//
//  SKWordWidgetEntry.swift
//  WordWidget
//
//  Created by Logout on 17.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation
import WidgetKit

struct SKWordWidgetEntry: TimelineEntry {
    let date: Date
    
    private var _configuration: Any? = nil
    @available(iOSApplicationExtension 17.0, *)
    var configuration: SKWordWidgetConfigurationIntent? {
        get {
            return _configuration as? SKWordWidgetConfigurationIntent
        }
        set {
            _configuration = newValue
        }
    }
    
    let word: String
    let wordTranslation: String
    let wordId: Int64
    let language: ESKVocabularyType

    var deepLinkURL: URL? {
        URL(string: "skarnik://word?id=\(wordId)&lang=\(language.rawValue)")
    }

    init(date: Date, word: String, wordTranslation: String, wordId: Int64 = 0, language: ESKVocabularyType = .bel_rus) {
        self.date = date
        self.word = word
        self.wordTranslation = wordTranslation
        self.wordId = wordId
        self.language = language
    }

    @available(iOSApplicationExtension 17.0, *)
    init(date: Date, configuration: SKWordWidgetConfigurationIntent, word: String, wordTranslation: String, wordId: Int64 = 0, language: ESKVocabularyType = .bel_rus) {
        self.date = date
        self._configuration = configuration
        self.word = word
        self.wordTranslation = wordTranslation
        self.wordId = wordId
        self.language = language
    }
}
