//
//  SKWordFetchService.swift
//  WordWidgetExtension
//
//  Created by Logout on 24.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import WidgetKit
import Foundation
import UIKit

struct SKWordFetchEntry: Codable {
    let language: ESKVocabularyType
    let wordId: Int64
    let word: String
    let translation: String
    let createdAt: Date
    
    init(word: SKWord, translation: String, createdAt: Date) {
        self.language = word.lang_id
        self.wordId = word.word_id
        self.word = word.word
        self.createdAt = createdAt
        self.translation = translation
    }
}

extension SKWordFetchEntry {
    
    var similarity: Float {
        let levenshteinDistance = self.levenshteinDistance
        if levenshteinDistance == 0 {
            return .infinity
        }
        let similar = Float(self.word.count) / Float(levenshteinDistance)
        return similar
    }
    
    var isSimilar: Bool {
        return self.similarity > 1.8
    }
    
    var levenshteinDistance: Int {
        
        func replaceLetters(str: String) -> String {
            var newStr = str
            let replacers = [["o":"a"], ["и":"і"], ["щ":"шч"], ["ъ":"'"], ["ў":"у"], ["❛":"'"], ["❜":"'"], ["`":"'"], ["‛":"'"], ["’":"'"], ["‘":"'"]]
            for pair in replacers {
                let key = pair.keys.first!
                let value = pair.values.first!
                newStr = newStr.replacingOccurrences(of: key, with: value)
            }
            return newStr
        }
        
        guard let translation = self.translation.components(separatedBy: CharacterSet(charactersIn: "­­–‑—-‒-")).first?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return 0
        }
        let wordA = replaceLetters(str: self.word.lowercased())
        let wordB = replaceLetters(str: translation.lowercased())
        return levenshtein(aStr: wordA, bStr: wordB)
    }

}

extension UserDefaults {
    static let skWordFetchStorageKey = "skWordFetchStorageKey"
}

class SKWordFetchStorage {
    
    private typealias VocabularyStorage = [ESKVocabularyType : [Int64: SKWordFetchEntry]]
    
    private var vocabularyStorage: VocabularyStorage = [:]
    
    init() {
        self.load()
    }
    
    private func load() {
        guard let wordFetchStorageData = UserDefaults.standard.object(forKey: UserDefaults.skWordFetchStorageKey) as? Data else {
            self.vocabularyStorage = [:]
            return
        }
        
        guard let vocabularyStorage = try? JSONDecoder().decode(VocabularyStorage.self, from: wordFetchStorageData) else {
            self.vocabularyStorage = [:]
            return
        }
        
        self.vocabularyStorage = vocabularyStorage
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(self.vocabularyStorage) else {
            return
        }
        UserDefaults.standard.setValue(data, forKey: UserDefaults.skWordFetchStorageKey)
        UserDefaults.standard.synchronize()
    }
    
    func addWord(_ wordFetchEntry: SKWordFetchEntry) {
        if self.vocabularyStorage[wordFetchEntry.language] == nil {
            self.vocabularyStorage[wordFetchEntry.language] = [:]
        }
        self.vocabularyStorage[wordFetchEntry.language]![wordFetchEntry.wordId] = wordFetchEntry
        self.save()
    }
    
    func word(vocabularyType: ESKVocabularyType, wordId: Int64) -> SKWordFetchEntry? {
        self.vocabularyStorage[vocabularyType]?[wordId]
    }
    
    func hasWord(vocabularyType: ESKVocabularyType, wordId: Int64) -> Bool {
        guard let fewDaysAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {
            return false
        }

        guard let word = self.word(vocabularyType: vocabularyType, wordId: wordId) else {
            return false
        }

        if word.createdAt < fewDaysAgo {
            return word.isSimilar
        }
        
        return true
    }
}

class SKWordFetchService: Any {
    
    private var storage = SKWordFetchStorage()
    
    init() {
    }
    
    public func fetchWord(_ vocabularyType: ESKVocabularyType, maxTries: Int = 20) async -> SKWordFetchEntry? {
        var loop = 0
        while true {
            loop += 1
            let word = await self.randomWord(vocabularyType)
            if self.storage.hasWord(vocabularyType: word.lang_id, wordId: word.word_id) && loop < maxTries {
                continue
            }

            guard let wordTranslation = try? await SKSkarnikByController.wordTranslation(word)?.attributedString?.string else {
                return nil
            }
            let newWordEntry = SKWordFetchEntry(word: word, translation: wordTranslation, createdAt: Date())
            self.storage.addWord(newWordEntry)
            
            if newWordEntry.isSimilar && loop < maxTries {
                continue
            }
            
            return newWordEntry
        }
    }
    
    private func randomWord(_ vocabularyType: ESKVocabularyType) async -> SKWord {
        while(true) {
            if let word = SKVocabularyIndex.shared.randomWord(vocabularyType: vocabularyType) {
                return word
            }
        }
    }
}
