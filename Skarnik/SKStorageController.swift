//
//  SKWordHistoryController.swift
//  Skarnik
//
//  Created by Logout on 10.10.22.
//

import UIKit

class SKStorageController: Any {
    static let shared = SKStorageController()
    var words:[SKWord] = []
    private static let wordsHistoryKey = "wordsHistoryKey"
    
    private init() {
        self.words = self.loadWords()
    }
    
    private func loadWords() -> [SKWord] {
        var words: [SKWord]?
        if let jsonData = UserDefaults.standard.object(forKey: SKStorageController.wordsHistoryKey) as? Data {
            words = try? JSONDecoder().decode([SKWord].self, from: jsonData)
        }
        return words ?? []
    }
    
    private func saveWords(words: [SKWord]) {
        if let jsonData = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(jsonData, forKey: SKStorageController.wordsHistoryKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func addWord(_ word: SKWord, maxWords: Int = 100) {
        var words = self.words
        for i in 0..<words.count {
            if words[i].word_id == word.word_id && words[i].lang_id == word.lang_id {
                words.remove(at: i)
                break
            }
        }
        words.insert(word, at: 0)
        while words.count > maxWords {
            words.removeLast()
        }
        self.words = words
        self.saveWords(words: words)
    }
    
    func removeWord(index: Int) {
        if 0..<self.words.count ~= index {
            self.words.remove(at: index)
            self.saveWords(words: self.words)
        }
    }
}
