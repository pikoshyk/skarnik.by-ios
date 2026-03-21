
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
}
