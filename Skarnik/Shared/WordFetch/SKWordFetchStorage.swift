//
//  SKWordFetchStorage.swift
//  Skarnik
//
//  Created by Logout on 25.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation

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
