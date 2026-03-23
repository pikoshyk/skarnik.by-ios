
import XCTest
@testable import Skarnik

final class SKSkarnikByControllerTests: XCTestCase {

    // MARK: - SKSkarnikTranslation Tests

    func testSKSkarnikTranslation_recoloredHtml() {
        let word = SKWord(word_id: 1, word: "test", lang_id: .rus_bel)
        let html = "<html><body><font color=\"831b03\">Беларускае слова</font></body></html>"
        let translation = SKSkarnikTranslation(word: word, url: "http://example.com", html: html)
        
        let recoloredHtml = translation.recoloredHtml
        
        // "831b03" is defined in colorConversions and should be replaced.
        // In the colorConversions table, 831b03 maps to F44C3E for both light and dark.
        XCTAssertTrue(recoloredHtml.contains("color=\"F44C3E\""))
        XCTAssertFalse(recoloredHtml.contains("color=\"831b03\""))
    }

    func testSKSkarnikTranslation_belWords_bel_rus() {
        let word = SKWord(word_id: 1, word: "беларускае", lang_id: .bel_rus)
        let html = "some translation"
        let translation = SKSkarnikTranslation(word: word, url: "http://example.com", html: html)
        
        // For bel_rus, it should return the word itself if it's correct (no spaces)
        XCTAssertEqual(translation.belWords, ["беларускае"])
    }

    func testSKSkarnikTranslation_belWords_with_spaces() {
        let word = SKWord(word_id: 1, word: "беларускае слова", lang_id: .bel_rus)
        let html = "some translation"
        let translation = SKSkarnikTranslation(word: word, url: "http://example.com", html: html)
        
        // Words with spaces are considered incorrect and should be excluded
        XCTAssertEqual(translation.belWords, [])
    }

    // MARK: - SKSkarnikByController Tests

    func testSKSkarnikByController_url_rus_bel() {
        let url = SKSkarnikByController.url(vocabularyType: .rus_bel, wordId: 123)
        XCTAssertEqual(url, "https://www.skarnik.by/rusbel/123")
    }

    func testSKSkarnikByController_url_bel_rus() {
        let url = SKSkarnikByController.url(vocabularyType: .bel_rus, wordId: 456)
        XCTAssertEqual(url, "https://www.skarnik.by/belrus/456")
    }

    func testSKSkarnikByController_url_tsbm() {
        let url = SKSkarnikByController.url(vocabularyType: .bel_definition, wordId: 789)
        XCTAssertEqual(url, "https://www.skarnik.by/tsbm/789")
    }

    func testSKSkarnikByController_parseHtml_success() throws {
        let html = """
        <html>
            <body>
                <div id="trn">
                    <font color="831b03">Пераклад</font>
                </div>
            </body>
        </html>
        """
        let data = html.data(using: .utf8)!
        let result = try SKSkarnikByController.parseHtml(data: data)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("Пераклад"))
    }

    func testSKSkarnikByController_parseHtml_redirect() throws {
        let html = """
        <html>
            <body>
                <div id="rdr">Redirect content</div>
            </body>
        </html>
        """
        let data = html.data(using: .utf8)!
        
        XCTAssertThrowsError(try SKSkarnikByController.parseHtml(data: data)) { error in
            XCTAssertEqual(error as? SKSkarnikError, SKSkarnikError.nextWordIndexRequired)
        }
    }

    func testSKSkarnikByController_parseHtml_empty() throws {
        let html = "<html><body></body></html>"
        let data = html.data(using: .utf8)!
        let result = try SKSkarnikByController.parseHtml(data: data)
        
        XCTAssertNil(result)
    }

    // MARK: - Async Tests

    func testSKSkarnikTranslation_attributedString() async {
        let word = SKWord(word_id: 1, word: "test", lang_id: .rus_bel)
        let html = "<b>Bold</b>"
        let translation = SKSkarnikTranslation(word: word, url: "http://example.com", html: html)

        let attrString = await translation.attributedString
        XCTAssertNotNil(attrString)
    }

    // MARK: - SKFallbackTranslationSource Tests

    private let sampleWord = SKWord(word_id: 42, word: "тэст", lang_id: .bel_rus)

    private func sampleTranslation(for word: SKWord) -> SKSkarnikTranslation {
        SKSkarnikTranslation(word: word, url: "https://example.com", html: "<b>тэст</b>")
    }

    func testFallback_returnsFirstSuccessfulResult() async throws {
        let translation = sampleTranslation(for: sampleWord)
        var secondSourceCalled = false

        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { translation },
            MockTranslationSource { secondSourceCalled = true; return nil }
        ])

        let result = try await source.wordTranslation(sampleWord)

        XCTAssertNotNil(result)
        XCTAssertFalse(secondSourceCalled, "Second source should not be called when first succeeds")
    }

    func testFallback_skipsNilAndUsesNextSource() async throws {
        let translation = sampleTranslation(for: sampleWord)

        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { nil },
            MockTranslationSource { translation }
        ])

        let result = try await source.wordTranslation(sampleWord)

        XCTAssertNotNil(result)
    }

    func testFallback_skipsErrorAndUsesNextSource() async throws {
        let translation = sampleTranslation(for: sampleWord)

        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { throw SKSkarnikError.networkError },
            MockTranslationSource { translation }
        ])

        let result = try await source.wordTranslation(sampleWord)

        XCTAssertNotNil(result)
    }

    func testFallback_throwsLastErrorWhenAllSourcesFail() async {
        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { throw SKSkarnikError.networkError },
            MockTranslationSource { throw SKSkarnikError.networkError }
        ])

        do {
            _ = try await source.wordTranslation(sampleWord)
            XCTFail("Expected an error to be thrown")
        } catch let error as SKSkarnikError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFallback_returnsNilWhenAllSourcesReturnNil() async throws {
        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { nil },
            MockTranslationSource { nil }
        ])

        let result = try await source.wordTranslation(sampleWord)
        XCTAssertNil(result)
    }

    func testFallback_usesSourcesInOrder() async throws {
        var callOrder: [Int] = []

        let source = SKFallbackTranslationSource(sources: [
            MockTranslationSource { callOrder.append(1); return nil },
            MockTranslationSource { callOrder.append(2); return nil },
            MockTranslationSource { callOrder.append(3); return nil }
        ])

        _ = try await source.wordTranslation(sampleWord)

        XCTAssertEqual(callOrder, [1, 2, 3])
    }

    // MARK: - Stub Source Tests

    func testApiTranslationSource_returnsNil() async throws {
        let result = try await SKApiTranslationSource().wordTranslation(sampleWord)
        XCTAssertNil(result)
    }

    func testSupabaseTranslationSource_returnsNil() async throws {
        let result = try await SKSupabaseTranslationSource().wordTranslation(sampleWord)
        XCTAssertNil(result)
    }
}

// MARK: - Mock

private struct MockTranslationSource: SKTranslationSource {
    let handler: () async throws -> SKSkarnikTranslation?

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        try await handler()
    }
}
