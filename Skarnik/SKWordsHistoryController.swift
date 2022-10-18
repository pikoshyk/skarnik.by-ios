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
        if let jsonData = UserDefaults.standard.object(forKey: SKWordsHistoryController.wordsHistoryKey) as? Data {
            words = try? JSONDecoder().decode([SKWord].self, from: jsonData)
        }
        return words ?? []
    }
    
    private func saveWords(words: [SKWord]) {
        if let jsonData = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(jsonData, forKey: SKWordsHistoryController.wordsHistoryKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func addWord(_ word: SKWord) {
        self.words.insert(word, at: 0)
        self.saveWords(words: self.words)
    }
    
    func removeWord(index: Int) {
        if 0..<self.words.count ~= index {
            self.words.remove(at: index)
            self.saveWords(words: self.words)
        }
    }
}
