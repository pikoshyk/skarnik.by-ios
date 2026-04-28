
import XCTest
import Combine
@testable import Skarnik

final class SKWordDetailsViewControllerTests: XCTestCase {

    private var sut: SKWordDetailsViewController!
    private var storyboard: UIStoryboard!

    @MainActor
    override func setUp() {
        super.setUp()
        storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "SKWordDetailsViewController") as? SKWordDetailsViewController
        sut.loadViewIfNeeded()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        storyboard = nil
        super.tearDown()
    }

    @MainActor
    func testInitialState_IsIdle() {
        XCTAssertNil(sut.word)
        guard case .idle = sut.viewModel.state else {
            XCTFail("Expected idle state on init")
            return
        }
    }

    @MainActor
    func testLoadingState_AfterWordSet() {
        let word = SKWord(word_id: 1, word: "тэст", lang_id: .bel_rus)
        sut.word = word

        guard case .loading = sut.viewModel.state else {
            XCTFail("Expected loading state after setting word")
            return
        }
    }

    // Regression test: navigation title must reflect the word passed to the $word publisher,
    // not viewModel.word read back inside the sink (which would still be the old value due
    // to @Published using willSet semantics).
    @MainActor
    func testNavigationTitle_ShowsOnFirstWord() {
        let word = SKWord(word_id: 1, word: "тэст", lang_id: .bel_rus)
        sut.word = word
        XCTAssertEqual(sut.viewModel.navigationTitle, "«\u{200E}тэст»")
    }

    @MainActor
    func testNavigationTitle_UpdatesImmediatelyOnWordChange() {
        let word1 = SKWord(word_id: 1, word: "першы", lang_id: .bel_rus)
        let word2 = SKWord(word_id: 2, word: "другі", lang_id: .bel_rus)

        sut.word = word1
        sut.word = word2

        XCTAssertEqual(sut.viewModel.navigationTitle, "«\u{200E}другі»")
    }

    @MainActor
    func testNilWord_ResetsState() {
        sut.word = SKWord(word_id: 1, word: "тэст", lang_id: .bel_rus)
        sut.word = nil

        XCTAssertNil(sut.viewModel.navigationTitle)
        guard case .idle = sut.viewModel.state else {
            XCTFail("Expected idle state after setting nil word")
            return
        }
    }
}
