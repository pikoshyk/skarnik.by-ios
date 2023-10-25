//
//  SKWordFetchService.swift
//  WordWidgetExtension
//
//  Created by Logout on 24.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation

class SKWordFetchService: Any {
    
    private var storage = SKWordFetchStorage()
    
    init() {
    }
    
    public func fetchRandomWord(_ vocabulary: ESKVocabularyType, maxTries: Int = 30) async -> SKWordFetchEntry? {
        var loop = 0
        while true {
            loop += 1
            let word = await self.randomWord(vocabulary)
            if self.storage.hasWord(vocabularyType: word.lang_id, wordId: word.word_id) && loop < maxTries {
                continue
            }

            guard let newWordEntry = await self.fetchWord(word) else {
                return nil
            }

            self.storage.addWord(newWordEntry)
            
            if newWordEntry.isSimilar && loop < maxTries {
                continue
            }
            
            return newWordEntry
        }
    }
    
    public func fetchWord(_ word: SKWord) async -> SKWordFetchEntry? {
        guard let wordTranslation = try? await SKSkarnikByController.wordTranslation(word)?.attributedString?.string else {
            return nil
        }
        let newWordEntry = SKWordFetchEntry(word: word, translation: wordTranslation, createdAt: Date())
        
        return newWordEntry
    }
    
    private func randomWord(_ vocabularyType: ESKVocabularyType) async -> SKWord {
        while(true) {
            if let word = SKVocabularyIndex.shared.randomWord(vocabularyType: vocabularyType) {
                return word
            }
        }
    }
}
