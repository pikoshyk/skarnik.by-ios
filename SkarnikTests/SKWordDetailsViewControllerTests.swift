
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
    func testViewDidLoad_SetupUI() {
        XCTAssertNotNil(sut.labelVocabulary)
        XCTAssertNotNil(sut.textView)
        XCTAssertNotNil(sut.activityIndicatorView)
    }
    
    @MainActor
    func testLoadingState_ShowsIndicator() {
        // Trigger loading state via word update if possible, 
        // or just mock the viewModel if we refactored sut to allow it.
        // For now, let's just check if we can trigger updateWord.
        
        let word = SKWord(word_id: 1, word: "тэст", lang_id: .bel_rus)
        sut.word = word
        
        // After setting word, it should go into loading state immediately.
        XCTAssertFalse(sut.activityIndicatorView.isHidden)
        XCTAssertTrue(sut.activityIndicatorView.isAnimating)
    }
    
    // Regression test: navigation title must reflect the word passed to the $word publisher,
    // not viewModel.word read back inside the sink (which would still be the old value due
    // to @Published using willSet semantics).
    @MainActor
    func testNavigationTitle_ShowsOnFirstWord() {
        let word = SKWord(word_id: 1, word: "тэст", lang_id: .bel_rus)
        sut.word = word
        XCTAssertEqual(sut.navigationItem.title, "«\u{200E}тэст»")
    }

    @MainActor
    func testNavigationTitle_UpdatesImmediatelyOnWordChange() {
        let word1 = SKWord(word_id: 1, word: "першы", lang_id: .bel_rus)
        let word2 = SKWord(word_id: 2, word: "другі", lang_id: .bel_rus)

        sut.word = word1
        sut.word = word2

        XCTAssertEqual(sut.navigationItem.title, "«\u{200E}другі»")
    }

    @MainActor
    func testNilWord_ResetsUI() {
        sut.word = nil
        
        XCTAssert(sut.navigationItem.title == nil || sut.navigationItem.title?.isEmpty == true)
        XCTAssert(sut.labelVocabulary.text == nil || sut.labelVocabulary.text?.trimmingCharacters(in: .whitespaces).isEmpty == true)
        XCTAssertTrue(sut.textView.attributedText?.string.isEmpty ?? true)
        XCTAssertTrue(sut.activityIndicatorView.isHidden)
    }
}
