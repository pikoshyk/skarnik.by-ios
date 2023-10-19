//
//  SKWordTimelineProvider.swift
//  WordWidget
//
//  Created by Logout on 17.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation
import WidgetKit
import SwiftUI

struct SKWordTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SKWordWidgetEntry {
        SKWordWidgetEntry(date: Date(),
                          configuration: SKWordWidgetConfigurationIntent(),
                          word: SKLocalization.widgetWordSampleWord,
                          wordTranslation: SKLocalization.widgetWordSampleTranslation)

    }

    func snapshot(for configuration: SKWordWidgetConfigurationIntent, in context: Context) async -> SKWordWidgetEntry {
        SKWordWidgetEntry(date: Date(),
                          configuration: configuration,
                          word: SKLocalization.widgetWordSampleWord,
                          wordTranslation: SKLocalization.widgetWordSampleTranslation)
    }
    
    func timeline(for configuration: SKWordWidgetConfigurationIntent, in context: Context) async -> Timeline<SKWordWidgetEntry> {

        guard let word = SKVocabularyIndex.shared.randomWord(vocabularyType: .bel_rus) else {
            return Timeline(entries: [], policy: .atEnd)
        }
        
        guard let translation = try? await SKSkarnikByController.wordTranslation(word) else {
            return Timeline(entries: [], policy: .atEnd)
        }
        let attributedString = await translation.attributedString
        guard let wordTranslation = attributedString?.string else {
            return Timeline(entries: [], policy: .atEnd)
        }
        
        
        let entry = SKWordWidgetEntry(date: Date(),
                                      configuration: configuration,
                                      word: word.word,
                                      wordTranslation: wordTranslation)

        return Timeline(entries: [entry], policy: .atEnd)
    }
}
