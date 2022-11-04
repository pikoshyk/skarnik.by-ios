//
//  SKStarnikByController.swift
//  Skarnik
//
//  Created by Logout on 16.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import UIKit

struct SKStarnikSpellingWord {
    let word: String?
    let wordIdStr: String?
    let wordType: String?
    let unknownParam1: String?
    
    var wordId: Int? {
        get {
            guard let wordIdStr = self.wordIdStr else {
                return nil
            }
            return Int(wordIdStr)
        }
    }
    
    var isValid: Bool {
        get {
            let status = (self.word ?? "").isEmpty == false && self.wordId != nil
            return status
        }
    }
    
    var url: URL? {
        guard let wordId = self.wordId else {
            return nil
        }
        let urlStr = "https://starnik.by/pravapis/\(wordId)"
        return URL(string: urlStr)
    }
}

class SKStarnikByController {
    
    class func spellingWordSuggestions(belWord: String) async -> [SKStarnikSpellingWord]? {
        guard let urlStr = self.spellingWordUrlStr(belWord: belWord) else {
            return nil
        }
        
        let data = await URLSession.skarnikDownload(urlStr: urlStr)
        guard let data = data else {
            return nil
        }
        
        let words = self.spellingWordSuggestions(data: data)
        
        return words
    }
    
    class private func spellingWordSuggestions(data: Data) -> [SKStarnikSpellingWord]? {
        guard let array = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        let chunks = array.chunked(into: 4)
        var words: [SKStarnikSpellingWord] = []
        for chunk in chunks {
            let word = SKStarnikSpellingWord(word: chunk[0], wordIdStr: chunk[1], wordType: chunk[2], unknownParam1: chunk[3])
            if word.isValid {
                words.append(word)
            }
        }
        return words.count > 0 ? words : nil
    }

    class private func spellingWordUrlStr(belWord: String) -> String? {
        guard let escapedBelWord = belWord.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return nil
        }

        let strUrl = "https://starnik.by/wordlist?lem=\(escapedBelWord)"
        return strUrl
    }
}

