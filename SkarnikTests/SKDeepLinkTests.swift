//
//  SKDeepLinkTests.swift
//  SkarnikTests
//

import XCTest
@testable import Skarnik

final class SKDeepLinkTests: XCTestCase {

    // MARK: - URL parsing

    func testValidURL_resolvesWord() {
        guard let realWord = SKVocabularyIndex.shared.word(index: 0, query: "м", vocabularyType: .bel_rus).first else {
            XCTFail("Could not fetch a real word from DB")
            return
        }
        let url = URL(string: "skarnik://word?id=\(realWord.word_id)&lang=\(realWord.lang_id.rawValue)")!
        let resolved = SceneDelegate.word(from: url)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.word_id, realWord.word_id)
        XCTAssertEqual(resolved?.lang_id, realWord.lang_id)
    }

    func testWrongScheme_returnsNil() {
        let url = URL(string: "https://word?id=1&lang=2")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testWrongHost_returnsNil() {
        let url = URL(string: "skarnik://something?id=1&lang=2")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testMissingIdParam_returnsNil() {
        let url = URL(string: "skarnik://word?lang=2")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testMissingLangParam_returnsNil() {
        let url = URL(string: "skarnik://word?id=1")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testNonNumericId_returnsNil() {
        let url = URL(string: "skarnik://word?id=abc&lang=2")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testNonNumericLang_returnsNil() {
        let url = URL(string: "skarnik://word?id=1&lang=xyz")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testInvalidLangRawValue_returnsNil() {
        // ESKVocabularyType has rawValues 0–4; 99 is invalid
        let url = URL(string: "skarnik://word?id=1&lang=99")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    func testNonExistentWordId_returnsNil() {
        let url = URL(string: "skarnik://word?id=999999999&lang=2")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }

    // MARK: - All vocabulary types round-trip

    func testVocabularyType_rusBel() {
        guard let realWord = SKVocabularyIndex.shared.word(index: 0, query: "м", vocabularyType: .rus_bel).first else {
            XCTFail("Could not fetch a rus_bel word")
            return
        }
        let url = URL(string: "skarnik://word?id=\(realWord.word_id)&lang=\(ESKVocabularyType.rus_bel.rawValue)")!
        let resolved = SceneDelegate.word(from: url)
        XCTAssertEqual(resolved?.lang_id, .rus_bel)
    }

    func testVocabularyType_belDefinition() {
        guard let realWord = SKVocabularyIndex.shared.word(index: 0, query: "м", vocabularyType: .bel_definition).first else {
            XCTFail("Could not fetch a bel_definition word")
            return
        }
        let url = URL(string: "skarnik://word?id=\(realWord.word_id)&lang=\(ESKVocabularyType.bel_definition.rawValue)")!
        let resolved = SceneDelegate.word(from: url)
        XCTAssertEqual(resolved?.lang_id, .bel_definition)
    }

    // MARK: - deepLinkURL round-trip

    func testDeepLinkURL_roundTrip() {
        // Simulates what SKWordWidgetEntry.deepLinkURL produces for a real word
        guard let realWord = SKVocabularyIndex.shared.word(index: 0, query: "а", vocabularyType: .bel_rus).first else {
            XCTFail("Could not fetch a real word from DB")
            return
        }
        let url = URL(string: "skarnik://word?id=\(realWord.word_id)&lang=\(realWord.lang_id.rawValue)")!
        let resolved = SceneDelegate.word(from: url)
        XCTAssertEqual(resolved?.word_id, realWord.word_id)
        XCTAssertEqual(resolved?.lang_id, realWord.lang_id)
    }

    func testDeepLinkURL_placeholderWordId_returnsNil() {
        // Placeholder entries use wordId = 0, which resolves to nil
        let url = URL(string: "skarnik://word?id=0&lang=\(ESKVocabularyType.bel_rus.rawValue)")!
        XCTAssertNil(SceneDelegate.word(from: url))
    }
}
