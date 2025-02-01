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

    static let colorConversions = [
        ["initial": "FFFFFF", "light": "F2F2F7", "dark": "1C1C1E"],
        
        ["initial": "831b03", "light": "F44C3E", "dark": "F44C3E"],
        ["initial": "0000A0", "light": "F44C3E", "dark": "F44C3E"],
        ["initial": "4863A0", "light": "F44C3E", "dark": "F44C3E"],
        
        ["initial": "008000", "light": "5856D6", "dark": "5E5CE6"],
        ["initial": "A52A2A", "light": "5856D6", "dark": "5E5CE6"],
        ["initial": "CC33FF", "light": "5856D6", "dark": "5E5CE6"],
        
        ["initial": "000000", "light": "000000", "dark": "FFFFFF"],
        
        ["initial": "5f5f5f", "light": "68686E", "dark": "98989F"],
        ["initial": "151B54", "light": "68686E", "dark": "98989F"]
    ]

    var labelColorHex: String {
        let filteredColors = Self.colorConversions.filter {$0["initial"] == "000000"}
        guard let colorLight = filteredColors.first?["light"],
              let colorDark = filteredColors.first?["dark"] else {
            return UIColor.label.webHexString()
        }
        var color = colorLight
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                color = colorDark
            }
        }
        
        return color
    }


    var recoloredHtml: String {
        get {
            var html = self.html
            
            
            for colorPair in Self.colorConversions {
                guard let colorInitial = colorPair["initial"],
                      let colorLight = colorPair["light"],
                      let colorDark = colorPair["dark"] else {
                    continue
                }
                
                var color = colorLight
                if #available(iOS 13.0, macCatalyst 13.0, *) {
                    if UITraitCollection.current.userInterfaceStyle == .dark {
                        color = colorDark
                    }
                }

                html = html.regexSub(pattern: "color=\"\(colorInitial)\"", template: "color=\"\(color)\"", options: [.caseInsensitive])
            }
//            if [.bel_rus, .rus_bel].contains(word.lang_id) {
//                html = html.regexSub(pattern: "color=\"831b03\"", template: "color=\"ff0000\"")
//                html = html.regexSub(pattern: "color=\"008000\"", template: "color=\"5f5f5f\"")
//            } else if word.lang_id == .bel_definition {
//                html = html.regexSub(pattern: "color=\"0000A0\"", template: "color=\"00aaff\"")
//                html = html.regexSub(pattern: "color=\"151B54\"", template: "color=\"880000\"")
//                html = html.regexSub(pattern: "color=\"5f5f5f\"", template: "color=\"aa0000\"")
//                html = html.regexSub(pattern: "color=\"A52A2A\"", template: "color=\"5f5f5f\"")
//            }
            return html
        }
    }
    
    var attributedString: NSAttributedString? {
        get async {
            await withCheckedContinuation { continuation in
                self.attributedString { attributedString in
                    continuation.resume(returning: attributedString)
                }
            }
        }
    }

    func attributedString(resultBlock: @escaping (_ : NSAttributedString?) -> Void) {
        let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let color = self.labelColorHex
        let html = "<html><body style=\"font-size: \(fontSize); color: \(color); font-family: -apple-system; line-height: 150%;\">" + self.recoloredHtml + "</body></html>"
        if let textData = html.data(using: .utf8) {
            DispatchQueue.main.async {
                let attributedString = try? NSAttributedString.string(htmlData: textData)
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

        guard let data = await URLSession.skarnikDownload(urlStr: urlStr) else {
            throw SKSkarnikError.networkError
        }

        var html: String?
        do {
            html = try self.parseHtml(data: data)
        } catch SKSkarnikError.nextWordIndexRequired {
            guard let nextWord = SKVocabularyIndex.shared.word(id: word.word_id + 1, vocabularyType: word.lang_id) else {
                return nil
            }
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
