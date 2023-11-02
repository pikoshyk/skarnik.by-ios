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
    
    init(date: Date, word: String, wordTranslation: String) {
        self.date = date
        self.word = word
        self.wordTranslation = wordTranslation
    }
    
    @available(iOSApplicationExtension 17.0, *)
    init(date: Date, configuration: SKWordWidgetConfigurationIntent, word: String, wordTranslation: String) {
        self.date = date
        self._configuration = configuration
        self.word = word
        self.wordTranslation = wordTranslation
    }
}
