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
    
    struct WordList: Codable {
        struct WordListBody: Codable {
            let lemma: String
            let id: Int
            let table_name: String
            let meaning: String
        }
        struct FormListBody: Codable {
            let lemma: String
            let id: Int
            let state: String
        }

        let word_list: [WordListBody]
        let form_list: [FormListBody]
    }

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
        guard let wordList = try? JSONDecoder().decode(WordList.self, from: data) else {
            return nil
        }
        let words: [SKStarnikSpellingWord] = wordList.word_list.compactMap { word in
            SKStarnikSpellingWord(word: word.lemma, wordIdStr: String(word.id), wordType: word.table_name, unknownParam1: word.meaning)
        }
        return words.count > 0 ? words : nil
    }

    class private func spellingWordUrlStr(belWord: String) -> String? {
        guard let escapedBelWord = belWord.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return nil
        }

        let strUrl = "https://starnik.by/api/wordList?lemma=\(escapedBelWord)"
        return strUrl
    }
}

