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
    
    private var wordFetchService = SKWordFetchService()
    
    func timeline(for configuration: SKWordWidgetConfigurationIntent, in context: Context) async -> Timeline<SKWordWidgetEntry> {

        guard let word = await self.wordFetchService.fetchRandomWord(.bel_rus) else {
            return Timeline(entries: [], policy: .atEnd)
        }
        let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let entry = SKWordWidgetEntry(date: date,
                                      configuration: configuration,
                                      word: word.word,
                                      wordTranslation: word.translation)

        return Timeline(entries: [entry], policy: .atEnd)
    }
}
