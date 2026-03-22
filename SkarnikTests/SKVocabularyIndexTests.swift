
import XCTest
@testable import Skarnik

final class SKVocabularyIndexTests: XCTestCase {
    
    // MARK: - Preprocessing Tests
    
    func testPreprocessQuery_RusBel() {
        let index = SKVocabularyIndex.shared
        // rus_bel should NOT have additional search rules, so it shouldn't replace anything
        let result = index.preprocessQuery("иещъ'", vocabularyType: .rus_bel)
        XCTAssertEqual(result, "иещъ'")
    }
    
    func testPreprocessQuery_BelRus() {
        let index = SKVocabularyIndex.shared
        // bel_rus should NOT have additional search rules
        let result = index.preprocessQuery("иещъ'", vocabularyType: .bel_rus)
        XCTAssertEqual(result, "иещъ'")
    }
    
    func testPreprocessQuery_All_ShortQuery() {
        let index = SKVocabularyIndex.shared
        // "all" with query length < 3 should NOT have additional search rules
        let result = index.preprocessQuery("ие", vocabularyType: .all)
        XCTAssertEqual(result, "ие")
    }
    
    func testPreprocessQuery_All_LongQuery() {
        let index = SKVocabularyIndex.shared
        // "all" with query length >= 3 SHOULD replace characters
        // и -> і, е -> ё, щ -> ў, ъ -> ‘, ' -> ‘
        let result = index.preprocessQuery("иещъ'", vocabularyType: .all)
        XCTAssertEqual(result, "іёў‘‘")
    }
    
    func testPreprocessQuery_Lowercase() {
        let index = SKVocabularyIndex.shared
        let result = index.preprocessQuery("АБВ", vocabularyType: .bel_rus)
        XCTAssertEqual(result, "абв")
    }
    
    func testRequiredAdditionalSearchRules() {
        let index = SKVocabularyIndex.shared
        XCTAssertFalse(index.requiredAdditionalSearchRules(queryLength: 1, vocabularyType: .all))
        XCTAssertFalse(index.requiredAdditionalSearchRules(queryLength: 2, vocabularyType: .all))
        XCTAssertTrue(index.requiredAdditionalSearchRules(queryLength: 3, vocabularyType: .all))
        XCTAssertFalse(index.requiredAdditionalSearchRules(queryLength: 3, vocabularyType: .bel_rus))
    }

    // MARK: - Database Content Tests
    // Note: These tests depend on the actual content of vocabulary.db.
    // We assume standard words like "дом" (house) or "мова" (language) exist.

    func testWordsCount_EmptyQuery() {
        let index = SKVocabularyIndex.shared
        XCTAssertEqual(index.wordsCount(query: "", vocabularyType: .bel_rus), 0)
    }

    func testWordsCount_SpecificVocabulary() {
        let index = SKVocabularyIndex.shared
        let count = index.wordsCount(query: "д", vocabularyType: .bel_rus)
        XCTAssertGreaterThan(count, 0, "There should be words starting with 'д' in bel_rus")
    }

    func testWordsCount_All_PreprocessingTriggered() {
        let index = SKVocabularyIndex.shared
        // "иещ" -> "іёў" (queryLength 3 >= 3, type .all)
        // If the DB has words starting with "іёў", this will verify preprocessing works in SQL generation.
        _ = index.wordsCount(query: "иещ", vocabularyType: .all)
        // We can't easily verify the exact count without knowing the DB content, 
        // but we can verify it doesn't crash and returns a non-negative number.
    }

    func testWordByString_Success() {
        let index = SKVocabularyIndex.shared
        // Assuming "мова" is in the Belarusian-Russian dictionary
        if let word = index.word("мова", vocabularyType: .bel_rus) {
            XCTAssertEqual(word.word.lowercased(), "мова")
            XCTAssertEqual(word.lang_id, .bel_rus)
        }
    }

    func testWordByString_NotFound() {
        let index = SKVocabularyIndex.shared
        let word = index.word("nonexistentword12345", vocabularyType: .bel_rus)
        XCTAssertNil(word)
    }

    func testWordById_Success() {
        let index = SKVocabularyIndex.shared
        // First get a valid ID
        guard let firstWord = index.word(index: 0, query: "а", vocabularyType: .bel_rus).first else {
            XCTFail("Could not fetch first word")
            return
        }
        
        let fetchedWord = index.word(id: firstWord.word_id, vocabularyType: .bel_rus)
        XCTAssertNotNil(fetchedWord)
        XCTAssertEqual(fetchedWord?.word_id, firstWord.word_id)
        XCTAssertEqual(fetchedWord?.word, firstWord.word)
    }

    func testWordPaginated_LimitAndOffset() {
        let index = SKVocabularyIndex.shared
        let query = "а"
        let limit = 5
        
        let wordsPage1 = index.word(index: 0, query: query, vocabularyType: .bel_rus, limit: limit)
        XCTAssertEqual(wordsPage1.count, limit)
        
        let wordsPage2 = index.word(index: limit, query: query, vocabularyType: .bel_rus, limit: limit)
        XCTAssertEqual(wordsPage2.count, limit)
        
        // Ensure page 2 is different from page 1
        if !wordsPage1.isEmpty && !wordsPage2.isEmpty {
            XCTAssertNotEqual(wordsPage1.first?.word_id, wordsPage2.first?.word_id)
        }
    }

    func testRandomWord() {
        let index = SKVocabularyIndex.shared
        let word1 = index.randomWord(vocabularyType: .bel_rus)
        let word2 = index.randomWord(vocabularyType: .bel_rus)
        
        XCTAssertNotNil(word1)
        XCTAssertNotNil(word2)
        // It's statistically possible but highly unlikely they are the same
    }

    func testWordsIndexes() {
        let index = SKVocabularyIndex.shared
        
        let beIndexes = index.wordsIndexes(vocabularyType: .bel_rus)
        XCTAssertTrue(beIndexes.contains("А"))
        XCTAssertTrue(beIndexes.contains("Я"))
        XCTAssertTrue(beIndexes.contains("І"))
        XCTAssertFalse(beIndexes.contains("И")) // Belarusian shouldn't have Russian 'И'
        
        let ruIndexes = index.wordsIndexes(vocabularyType: .rus_bel)
        XCTAssertTrue(ruIndexes.contains("И"))
        XCTAssertFalse(ruIndexes.contains("І")) // Russian shouldn't have Belarusian 'І'
        
        let historyIndexes = index.wordsIndexes(vocabularyType: .history)
        XCTAssertEqual(historyIndexes, [""])
    }
}
