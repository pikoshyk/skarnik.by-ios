//
//  SKDictionary.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import SQLite
import SQLite3
import Foundation

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
    
    var skarnikId: String? {
        if self == .rus_bel { return "rusbel" }
        if self == .bel_rus { return "belrus" }
        if self == .bel_definition { return "tsbm" }
        return nil
    }

    var wordDetailsSubtitle: String? {
        if self == .rus_bel { return SKLocalization.wordDetailsSubtitleRusBel }
        if self == .bel_rus { return SKLocalization.wordDetailsSubtitleBelRus }
        if self == .bel_definition { return SKLocalization.wordDetailsSubtitleDenifition }
        return nil
    }

    static func from(vocabularyPath pathValue: String) -> ESKVocabularyType? {
        switch pathValue {
        case "tsbm": return .bel_definition
        case "belrus": return .bel_rus
        case "rusbel": return .rus_bel
        default: return nil
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
    private let cacheLock = NSLock()
    
    private init() {
        let dbUrl = Bundle.main.url(forResource: "vocabulary", withExtension: "db")
        self.db = try! Connection(dbUrl!.absoluteString)
    }
    
    func preprocessQuery(_ query: String, vocabularyType: ESKVocabularyType) -> String {
        var newQuery = query.lowercased().replacingOccurrences(of: "`", with: "'").replacingOccurrences(of: "‘", with: "'").replacingOccurrences(of: "’", with: "'")
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
        cacheLock.lock()
        let cached = self.indexCountCache[vocabularyType]?[preprocessedQuery]
        cacheLock.unlock()
        if let count = cached {
            return count
        }

        var count: Int64?
        
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

        guard let sqlQuery = sqlQuery else {
            return 0
        }

        do {
            count = try self.db.scalar(sqlQuery) as? Int64
        } catch {
        }

        guard let count = count else {
            return 0
        }

        let intCount = Int(count)
        if preprocessedQuery.count == 1 {
            cacheLock.lock()
            if self.indexCountCache[vocabularyType] == nil {
                self.indexCountCache[vocabularyType] = [preprocessedQuery: intCount]
            } else {
                self.indexCountCache[vocabularyType]?[preprocessedQuery] = intCount
            }
            cacheLock.unlock()
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
    
    func word(_ word: String, vocabularyType: ESKVocabularyType) -> SKWord? {
        let query = word.lowercased()
        var rows: Statement?
        do {
            rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND lword=? LIMIT 1", vocabularyType.rawValue, "\(query)")
        } catch {
        }

        guard let row = rows?.next() else {
            return nil
        }
        

        let word = SKWord(word_id: row[0] as! Int64, word: row[1] as! String, lang_id: vocabularyType)
        return word
    }
    
    func word(id: Int64, vocabularyType: ESKVocabularyType) -> SKWord? {
        var rows: Statement?
        do {
            rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND word_id=? LIMIT 1", vocabularyType.rawValue, id)
        } catch {
        }

        guard let row = rows?.next() else {
            return nil
        }
        
        let word = SKWord(word_id: row[0] as! Int64, word: row[1] as! String, lang_id: vocabularyType)
        return word
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
                    rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND first_char=? ORDER BY lword LIMIT ? OFFSET ?", vocabularyType.rawValue, "\(preprocessedQuery)", limit, index)
                } else {
                    let firstChar = String(preprocessedQuery.prefix(1))
                    rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? AND first_char=? AND word_mask LIKE ? ORDER BY lword LIMIT ? OFFSET ?", vocabularyType.rawValue, firstChar, "\(preprocessedQuery)%",  limit, index)
                }
            }
        } catch {
        }
        
        guard let rows = rows else {
            return []
        }
        
        var lang_id = vocabularyType
        for row in rows {
            if vocabularyType == .all {
                lang_id = ESKVocabularyType(rawValue: Int(row[2] as! Int64))!
            }
            let word = SKWord(word_id: row[0] as! Int64, word: row[1] as! String, lang_id: lang_id)
            words.append(word)
        }

        return words
    }
    
    // Single bulk query via raw C SQLite API — avoids SQLite.swift per-row overhead (~5–7× faster).
    // ORDER BY lword uses lword_lang_index: no temp B-TREE sort.
    // Returns sections in alphabet order; filters by vocabularyType's alphabet to skip unexpected first_char values.
    func allWords(vocabularyType: ESKVocabularyType) -> [(title: String, words: [SKWord])] {
        guard vocabularyType != .history, vocabularyType != .all else { return [] }
        let alphabet = wordsIndexes(vocabularyType: vocabularyType)
        let alphabetSet = Set(alphabet)

        let sql = "SELECT word_id, word, first_char FROM vocabulary WHERE lang_id=? ORDER BY lword"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db.handle, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(vocabularyType.rawValue))

        // Collect into a dictionary — SQL byte-order puts ё/і/ў after я (U+0451/0456/045E > U+044F).
        // Reconstruct in linguistic order using the predefined alphabet array.
        var byLetter: [String: [SKWord]] = [:]
        byLetter.reserveCapacity(alphabet.count)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let wordId = sqlite3_column_int64(stmt, 0)
            let word = String(cString: sqlite3_column_text(stmt, 1)!)
            let firstChar = String(cString: sqlite3_column_text(stmt, 2)!).uppercased()
            guard alphabetSet.contains(firstChar) else { continue }
            byLetter[firstChar, default: []].append(SKWord(word_id: wordId, word: word, lang_id: vocabularyType))
        }

        return alphabet.compactMap { letter in
            guard let words = byLetter[letter], !words.isEmpty else { return nil }
            return (title: letter, words: words)
        }
    }

    func randomWord(vocabularyType: ESKVocabularyType) -> SKWord? {
        var rows: Statement?
        do {
            rows = try self.db.prepare("SELECT word_id, word FROM vocabulary WHERE lang_id=? ORDER BY random() LIMIT 1", vocabularyType.rawValue)
        } catch {
        }
        
        guard let row = rows?.next() else {
            return nil
        }
        
        let word = SKWord(word_id: row[0] as! Int64, word: row[1] as! String, lang_id: vocabularyType)
        return word
    }
}
