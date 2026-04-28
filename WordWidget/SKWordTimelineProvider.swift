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

@available(iOSApplicationExtension 17.0, *)
struct SKWordAppIntentTimelineProvider: AppIntentTimelineProvider {
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
        let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        guard let word = await self.wordFetchService.fetchRandomWord(.bel_rus) else {
            let fallback = SKWordWidgetEntry(date: date,
                                             configuration: configuration,
                                             word: SKLocalization.widgetWordSampleWord,
                                             wordTranslation: SKLocalization.widgetWordSampleTranslation)
            return Timeline(entries: [fallback], policy: .atEnd)
        }
        let entry = SKWordWidgetEntry(date: date,
                                      configuration: configuration,
                                      word: word.word,
                                      wordTranslation: word.translation,
                                      wordId: word.wordId,
                                      language: word.language)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

struct SKWordTimelineProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (SKWordWidgetEntry) -> Void) {
        let entry = SKWordWidgetEntry(date: Date(),
                                      word: SKLocalization.widgetWordSampleWord,
                                      wordTranslation: SKLocalization.widgetWordSampleTranslation)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SKWordWidgetEntry>) -> Void) {
        Task {
            let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            guard let word = await self.wordFetchService.fetchRandomWord(.bel_rus) else {
                let fallback = SKWordWidgetEntry(date: date,
                                                 word: SKLocalization.widgetWordSampleWord,
                                                 wordTranslation: SKLocalization.widgetWordSampleTranslation)
                completion(Timeline(entries: [fallback], policy: .atEnd))
                return
            }
            let entry = SKWordWidgetEntry(date: date,
                                          word: word.word,
                                          wordTranslation: word.translation,
                                          wordId: word.wordId,
                                          language: word.language)
            completion(Timeline(entries: [entry], policy: .atEnd))
        }
    }
    
    func placeholder(in context: Context) -> SKWordWidgetEntry {
        SKWordWidgetEntry(date: Date(),
                          word: SKLocalization.widgetWordSampleWord,
                          wordTranslation: SKLocalization.widgetWordSampleTranslation)
    }

    
    private var wordFetchService = SKWordFetchService()
    
}
