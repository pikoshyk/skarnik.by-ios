//
//  SKSkarnikByController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import SwiftSoup
import UIKit

struct SKSkarnikTranslation {
    let word: SKWord
    let url: String
    let html: String

    func attributedString(resultBlock: @escaping (_ : NSAttributedString?) -> Void) {
        let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let color = UIColor.label.webHexString()
        let html = "<html><body style=\"font-size: \(fontSize); color: \(color); font-family: -apple-system; line-height: 150%;\">" + self.html + "</body></html>"
        if let textData = html.data(using: .utf8) {
            DispatchQueue.main.async {
                let attributedString = try? NSAttributedString(data: textData, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding ], documentAttributes: nil)
                resultBlock(attributedString)
            }
        }
    }
    
    var belWords: [String] {
        get {

            func parseWord(_ word: String) -> [String] {
                var words: [String] = []
                words = word.components(separatedBy: ",").compactMap { word in
                    let word = word.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if word.contains(" ") {
                        return nil
                    }
                    return word
                }
                return words
            }

            func isCorrectWord(_ word: String) -> Bool {
                if word.contains(" ") {
                    return false
                }
                return true
            }
            let word = self.word
            
            var words: [String] = []
            
            if word.lang_id == .bel_rus || word.lang_id == .bel_definition {
                if isCorrectWord(word.word) {
                    words = [word.word]
                }
            } else if word.lang_id == .rus_bel {
                let html = self.html
                var foundWords: [String] = []
                do {
                    let doc = try SwiftSoup.parse(html)
                    let fonts: Elements = try doc.select("font")
                    for fontContent in fonts {
                        if let colorValue = try? fontContent.attr("color") {
                            if colorValue.lowercased() == "831b03".lowercased() {
                                if let word = try? fontContent.text().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                                    let parsedWords = parseWord(word)
                                    for parsedWord in parsedWords {
                                        if foundWords.contains(parsedWord) == false {
                                            if SKVocabularyIndex.shared.word(parsedWord, vocabularyType: .bel_definition) != nil {
                                                foundWords.append(parsedWord)
                                            } else if SKVocabularyIndex.shared.word(parsedWord, vocabularyType: .bel_rus) != nil {
                                                foundWords.append(parsedWord)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    words = foundWords
                } catch {
                    
                }

            }
            words = words.sorted { str1, str2 in
                return str1.lowercased().compare(str2.lowercased()) == .orderedAscending
            }
            return words
        }
    }
}

enum SKSkarnikError: Error {
    case nextWordIndexRequired
    case networkError
}

class SKSkarnikByController: Any {

    class func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        guard let urlStr = self.url(vocabularyType: word.lang_id, wordId: word.word_id) else {
            return nil
        }

        guard let data = await self.download(url: urlStr) else {
            throw SKSkarnikError.networkError
        }

        var html: String?
        do {
            html = try self.parseHtml(data: data)
        } catch SKSkarnikError.nextWordIndexRequired {
            var nextWord = word
            nextWord.word_id += 1
            return try await self.wordTranslation(nextWord)
        } catch {
            throw error
        }
        guard let html = html else {
            return nil
        }

        let translation = SKSkarnikTranslation(word: word, url: urlStr, html: html)

        return translation
    }
    
    class private func url(vocabularyType: ESKVocabularyType, wordId: Int64) -> String? {
        guard let vocabularySkarnikId = vocabularyType.skarnikId else {
            return nil
        }
        let urlStr = "https://www.skarnik.by/\(vocabularySkarnikId)/\(wordId)"
        return urlStr
    }

    class private func download(url: String) async -> Data? {
        
        guard let url = URL(string: url) else {
            return nil
        }
        
        var data: Data?
        do {
            var retrievedData: Data?
            var response: URLResponse?
            (retrievedData, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if retrievedData?.count ?? 0 > 0 {
                        data = retrievedData
                    }
                }
            }
        } catch {
        }

        return data
    }

    class private func parseHtml(data: Data) throws -> String? {
        var rawHtmlText: String?

        let html = String(data: data, encoding: .utf8) ?? ""
        let doc = try SwiftSoup.parse(html)
        let translation = try doc.getElementById("trn")
        rawHtmlText = try translation?.html()
        if rawHtmlText == nil {
            let rdr = try doc.getElementById("rdr")
            if rdr != nil {
                throw SKSkarnikError.nextWordIndexRequired
            }
        }

        return rawHtmlText
    }
}

extension ESKVocabularyType {
    var skarnikId: String? {
        get {
            if self == .rus_bel { return "rusbel" }
            if self == .bel_rus { return "belrus" }
            if self == .bel_definition { return "tsbm" }
            return nil
        }
    }
}
