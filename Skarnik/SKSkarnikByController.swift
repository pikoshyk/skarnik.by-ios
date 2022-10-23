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

extension UIColor {
    func webHexString() -> String {
        var red:CGFloat = 0
        var blue:CGFloat = 0
        var green:CGFloat = 0
        var alpha:CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb:Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        let hexString = String.localizedStringWithFormat("#%06x", rgb)
        return hexString
     }
}
