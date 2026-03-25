//
//  SKSkarnikByController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import SwiftSoup
import UIKit
import os.log

private let translationLog = OSLog(subsystem: "by.skarnik", category: "TranslationSource")

private func skLog(_ message: @autoclosure () -> String, type: OSLogType = .debug) {
    #if DEBUG
    os_log("%{public}@", log: translationLog, type: type, "🪲 " + message())
    #endif
}

// MARK: - Domain Types

struct SKSkarnikTranslation {
    let word: SKWord
    let url: String
    let html: String
    var stress: String? = nil
    var sourceName: String = ""

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
                html = html.regexSub(pattern: "color=\"#\(colorInitial)\"", template: "color=\"#\(color)\"", options: [.caseInsensitive])
                html = html.regexSub(pattern: "color:\\s*#\(colorInitial)(?=[\\s;\"'])", template: "color: #\(color)", options: [.caseInsensitive])
            }
            html = html.regexSub(pattern: "font-size:\\s*small;?\\s*", template: "", options: [.caseInsensitive])
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

                    let dataWordElements: Elements = try doc.select("[data-word]")
                    if !dataWordElements.isEmpty {
                        for element in dataWordElements {
                            let candidate = (try? element.attr("data-word").trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
                            guard !candidate.isEmpty, !candidate.contains(" "),
                                  !foundWords.contains(candidate) else { continue }
                            if SKVocabularyIndex.shared.word(candidate, vocabularyType: .bel_definition) != nil ||
                               SKVocabularyIndex.shared.word(candidate, vocabularyType: .bel_rus) != nil {
                                foundWords.append(candidate)
                            }
                        }
                    } else {
                        let fonts: Elements = try doc.select("font")
                        for fontContent in fonts {
                            let colorAttr = (try? fontContent.attr("color"))?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "#")) ?? ""
                            let styleAttr = (try? fontContent.attr("style")) ?? ""
                            let styleColorMatch = styleAttr.range(of: "color:\\s*#?831b03", options: [.regularExpression, .caseInsensitive]) != nil
                            if colorAttr == "831b03" || styleColorMatch {
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

// MARK: - Protocol

protocol SKTranslationSource {
    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation?
}

// MARK: - HTML Source

struct SKHtmlTranslationSource: SKTranslationSource {

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        guard let urlStr = Self.url(vocabularyType: word.lang_id, wordId: word.word_id) else {
            return nil
        }

        skLog("[HTML] Fetching word: \"\(word.word)\" (id: \(word.word_id), lang: \(word.lang_id.rawValue)) url: \(urlStr)")

        guard let data = await URLSession.skarnikDownload(urlStr: urlStr) else {
            skLog("[HTML] Network error for url: \(urlStr)", type: .error)
            throw SKSkarnikError.networkError
        }

        var html: String?
        do {
            html = try Self.parseHtml(data: data)
        } catch SKSkarnikError.nextWordIndexRequired {
            let nextId = word.word_id + 1
            skLog("[HTML] Redirect — retrying with next word id: \(nextId)")
            guard let nextWord = SKVocabularyIndex.shared.word(id: nextId, vocabularyType: word.lang_id) else {
                return nil
            }
            return try await self.wordTranslation(nextWord)
        } catch {
            throw error
        }
        guard let html = html else {
            return nil
        }

        skLog("[HTML] Parsed successfully for word: \"\(word.word)\" (id: \(word.word_id))")
        return SKSkarnikTranslation(word: word, url: urlStr, html: html, sourceName: "html")
    }

    static func url(vocabularyType: ESKVocabularyType, wordId: Int64) -> String? {
        guard let vocabularySkarnikId = vocabularyType.skarnikId else {
            return nil
        }
        return "https://www.skarnik.by/\(vocabularySkarnikId)/\(wordId)"
    }

    static func parseHtml(data: Data) throws -> String? {
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

// MARK: - API Source

struct SKApiTranslationSource: SKTranslationSource {

    private struct APIResponse: Decodable {
        let translation: String?
        let redirect_to: Int64?
        let stress: String?
    }

    static func url(vocabularyType: ESKVocabularyType, wordId: Int64) -> String? {
        guard let skarnikId = vocabularyType.skarnikId else { return nil }
        return "https://skarnik.play.of.by/api/words/\(skarnikId)/\(wordId)/"
    }

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        guard let urlStr = Self.url(vocabularyType: word.lang_id, wordId: word.word_id) else {
            return nil
        }

        skLog("[API] Fetching word: \"\(word.word)\" (id: \(word.word_id), lang: \(word.lang_id.rawValue)) url: \(urlStr)")

        guard let data = await URLSession.skarnikDownload(urlStr: urlStr) else {
            skLog("[API] Network error for url: \(urlStr)", type: .error)
            throw SKSkarnikError.networkError
        }

        let response = try JSONDecoder().decode(APIResponse.self, from: data)

        if let redirectId = response.redirect_to {
            skLog("[API] Redirect — retrying with word id: \(redirectId)")
            guard let nextWord = SKVocabularyIndex.shared.word(id: redirectId, vocabularyType: word.lang_id) else {
                return nil
            }
            return try await self.wordTranslation(nextWord)
        }

        guard let html = response.translation else {
            return nil
        }

        let displayUrl = SKHtmlTranslationSource.url(vocabularyType: word.lang_id, wordId: word.word_id) ?? urlStr
        skLog("[API] Parsed successfully for word: \"\(word.word)\" (id: \(word.word_id))")
        return SKSkarnikTranslation(word: word, url: displayUrl, html: html, stress: response.stress, sourceName: "api")
    }
}

// MARK: - Supabase Source

struct SKSupabaseTranslationSource: SKTranslationSource {
    private static let projectURL = "https://cxblykicbulwcilncgxd.supabase.co"
    private static let apiKey = "sb_publishable_aJ4mKd11QBgS0A3PG7P1HA_c8JOBqfo"
    private static let headers = [
        "apikey": apiKey,
        "Authorization": "Bearer \(apiKey)"
    ]

    private struct SupabaseResponse: Decodable {
        let translation: String?
        let redirect_to: Int64?
        let stress: String?
    }

    static func url(vocabularyType: ESKVocabularyType, wordId: Int64) -> String? {
        guard let skarnikId = vocabularyType.skarnikId else { return nil }
        return "\(projectURL)/rest/v1/main_word?external_id=eq.\(wordId)&direction=eq.\(skarnikId)"
    }

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        guard let urlStr = Self.url(vocabularyType: word.lang_id, wordId: word.word_id) else {
            return nil
        }

        skLog("[Supabase] Fetching word: \"\(word.word)\" (id: \(word.word_id), lang: \(word.lang_id.rawValue)) url: \(urlStr)")

        guard let data = await URLSession.skarnikDownload(urlStr: urlStr, headers: Self.headers) else {
            skLog("[Supabase] Network error for url: \(urlStr)", type: .error)
            throw SKSkarnikError.networkError
        }

        let responses = try JSONDecoder().decode([SupabaseResponse].self, from: data)
        guard let response = responses.first else {
            return nil
        }

        if let redirectId = response.redirect_to {
            skLog("[Supabase] Redirect — retrying with word id: \(redirectId)")
            guard let nextWord = SKVocabularyIndex.shared.word(id: redirectId, vocabularyType: word.lang_id) else {
                return nil
            }
            return try await self.wordTranslation(nextWord)
        }

        guard let html = response.translation else {
            return nil
        }

        let displayUrl = SKHtmlTranslationSource.url(vocabularyType: word.lang_id, wordId: word.word_id) ?? urlStr
        skLog("[Supabase] Parsed successfully for word: \"\(word.word)\" (id: \(word.word_id))")
        return SKSkarnikTranslation(word: word, url: displayUrl, html: html, stress: response.stress, sourceName: "supabase")
    }
}

// MARK: - Fallback Chain

struct SKFallbackTranslationSource: SKTranslationSource {
    let sources: [any SKTranslationSource]

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        skLog("[Fallback] Starting fetch for word: \"\(word.word)\" (id: \(word.word_id), lang: \(word.lang_id.rawValue)) — \(sources.count) source(s) available")
        var lastError: Error?
        for source in sources {
            let sourceName = String(describing: type(of: source))
            skLog("[Fallback] Trying \(sourceName)")
            do {
                if let result = try await source.wordTranslation(word) {
                    skLog("[Fallback] \(sourceName) succeeded")
                    return result
                }
                skLog("[Fallback] \(sourceName) returned nil, trying next")
            } catch {
                skLog("[Fallback] \(sourceName) failed with error: \(error), trying next", type: .error)
                lastError = error
            }
        }
        skLog("[Fallback] All sources exhausted for word: \"\(word.word)\"", type: lastError == nil ? .default : .error)
        if let lastError { throw lastError }
        return nil
    }

    static let shared = SKFallbackTranslationSource(sources: [
        SKSupabaseTranslationSource(),
        SKApiTranslationSource(),
        SKHtmlTranslationSource()
    ])
}

// MARK: - Backward Compatibility

typealias SKSkarnikByController = SKHtmlTranslationSource
