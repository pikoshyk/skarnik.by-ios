//
//  SKDictionary.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import SQLite
import UIKit

enum ESKVocabularyType: Int, Codable {
    case history = 0
    case rus_bel = 1
    case bel_rus = 2
    case bel_definition = 3
    case all = 4
}

extension ESKVocabularyType {
    var name: String? {
        get {
            var typeStr = ""
            switch self {
            case .history:
                typeStr = SKLocalization.cellSubtitleHistory
            case .rus_bel:
                typeStr = SKLocalization.cellSubtitleRusBel
            case .bel_rus:
                typeStr = SKLocalization.cellSubtitleBelRus
            case .bel_definition:
                typeStr = SKLocalization.cellSubtitleDenifition
            default:
                _ = 0
            }

            return typeStr
        }
    }
}

struct SKWord: Codable {
    var id: Int64? = 0
    var word_id: Int64
    let word: String
    var lword: String?
    let lang_id: ESKVocabularyType
}

class SKVocabularyIndex {
    static let shared = SKVocabularyIndex()
    private var db: Connection
    static let abcBe = "абвгдеёжзійклмнопрстуўфхцчшьыэюя".uppercased().map { String($0) }
    static let abcRu = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя".uppercased().map { String($0) }
    private var indexCountCache: [ESKVocabularyType: [String: Int]] = [:]
    
    private init() {
        let dbUrl = Bundle.main.url(forResource: "vocabulary", withExtension: "db")
        self.db = try! Connection(dbUrl!.absoluteString)
    }
    
    func preprocessQuery(_ query: String, vocabularyType: ESKVocabularyType) -> String {
        var newQuery = query.lowercased()
        if self.requiredAdditionalSearchRules(queryLength: query.count, vocabularyType: vocabularyType) {
            let charPairs = ["и": "і", "е": "ё", "щ": "ў", "ъ": "‘", "'": "‘"]
            for (key, value) in charPairs {
                newQuery = newQuery.replacingOccurrences(of: key, with: value, options: .literal)
            }
        }
        return newQuery
    }
    
    func requiredAdditionalSearchRules(queryLength: Int, vocabularyType: ESKVocabularyType) -> Bool {
        if vocabularyType != .all {
            return false
        }
        let status = queryLength >= 3
        return status
    }
    
    func wordsCount(query: String, vocabularyType: ESKVocabularyType) -> Int {
        let preprocessedQuery = self.preprocessQuery(query, vocabularyType: vocabularyType)
        if preprocessedQuery.isEmpty {
            return 0
        }
        if let count = self.indexCountCache[vocabularyType]?[preprocessedQuery] {
            return count
        }

        var count: Int64 = 0
        
        var sqlQuery: String?
        if vocabularyType == .all {
            if self.requiredAdditionalSearchRules(queryLength: query.count, vocabularyType: vocabularyType) {
                sqlQuery = "SELECT COUNT(*) FROM vocabulary WHERE word_mask LIKE \"\(preprocessedQuery)%\""
            } else {
                sqlQuery = "SELECT COUNT(*) FROM vocabulary WHERE lword LIKE \"\(preprocessedQuery)%\""
            }
        } else {
            if preprocessedQuery.count == 1 {
                sqlQuery = "SELECT COUNT(*) FROM vocabulary WHERE lang_id=\(vocabularyType.rawValue) AND first_char = \"\(preprocessedQuery)\""
            } else {
                let firstChar = String(preprocessedQuery.prefix(1))
                sqlQuery = "SELECT COUNT(*) FROM vocabulary WHERE lang_id=\(vocabularyType.rawValue) AND first_char=\"\(firstChar)\" AND word_mask LIKE \"\(preprocessedQuery)%\""
            }
        }

        do {
            count = try self.db.scalar(sqlQuery!) as! Int64
        } catch {
        }

        let intCount = Int(count)
        if(preprocessedQuery.count == 1) {
            if self.indexCountCache[vocabularyType] == nil {
                self.indexCountCache[vocabularyType] = [preprocessedQuery:intCount]
            } else {
                self.indexCountCache[vocabularyType]?[preprocessedQuery] = intCount
            }
        }
        return intCount
    }
    
    func wordsIndexes(vocabularyType: ESKVocabularyType) -> [String] {
        if vocabularyType == .history {
            return [""]
        }
        if vocabularyType == .rus_bel {
            return SKVocabularyIndex.abcRu
        }

        return SKVocabularyIndex.abcBe
    }
    
    func word(index: Int, query: String, vocabularyType: ESKVocabularyType, limit: Int = 1) -> [SKWord] {
        let preprocessedQuery = self.preprocessQuery(query, vocabularyType: vocabularyType)
        var words: [SKWord] = []

        var rows: Statement?
        do {
            if vocabularyType == .all {
                if self.requiredAdditionalSearchRules(queryLength: query.count, vocabularyType: vocabularyType) {
                    rows = try self.db.prepare("SELECT word_id, word, lang_id FROM vocabulary WHERE word_mask LIKE ? ORDER BY word_mask LIMIT ? OFFSET ?", "\(preprocessedQuery)%", limit, index)
                }else {
                    rows = try self.db.prepare("SELECT word_id, word, lang_id FROM vocabulary WHERE lword LIKE ? ORDER BY lword LIMIT ? OFFSET ?", "\(preprocessedQuery)%", limit, index)
                }
            } else {
                if preprocessedQuery.count == 1 {
                    rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND first_char=? ORDER BY lword LIMIT 1 OFFSET ?", vocabularyType.rawValue, "\(preprocessedQuery)", index)
                } else {
                    let firstChar = String(preprocessedQuery.prefix(1))
                    rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND first_char=? AND word_mask LIKE ? ORDER BY lword LIMIT 1 OFFSET ?", vocabularyType.rawValue, firstChar, "\(preprocessedQuery)%",  index)
                }

                
            }
        } catch {
        }
        
        var lang_id = vocabularyType
        for row in rows! {
            if vocabularyType == .all {
                lang_id = ESKVocabularyType(rawValue: Int(row[2] as! Int64))!
            }
            let word = SKWord(word_id: row[0] as! Int64, word: row[1] as! String, lang_id: lang_id)
            words.append(word)
        }

        return words
    }
}
