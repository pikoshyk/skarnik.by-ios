//
//  SKWordFetchEntry.swift
//  Skarnik
//
//  Created by Logout on 25.10.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation

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
            let replacers = [["о":"а"], ["щ":"шч"], ["ъ":"'"], ["ў":"у"], ["❛":"'"], ["❜":"'"], ["`":"'"], ["‛":"'"], ["’":"'"], ["‘":"'"], ["ся":"ца"], ["ый":"і"], ["ы":"і"], ["ий":"і"], ["и":"і"], ["т":"ц"], ["ё": "е"]]
            for pair in replacers {
                let key = pair.keys.first!
                let value = pair.values.first!
                newStr = newStr.replacingOccurrences(of: key, with: value, options: .diacriticInsensitive)
            }
            return newStr
        }
        
        let wordA = replaceLetters(str: self.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        let translations = self.translation.lowercased().components(separatedBy: .newlines)
        var maxDistance: Int = 1000
        for translation in translations {
            if let translationWord = translation.components(separatedBy: CharacterSet(charactersIn: "­­–‑—‒")).first?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let wordB = replaceLetters(str: translationWord)
                let levenshtein = SKLevenshtein.distance(aStr: wordA, bStr: wordB)
                if levenshtein < maxDistance {
                    maxDistance = levenshtein
                }
            }
        }
        return maxDistance
    }

}
