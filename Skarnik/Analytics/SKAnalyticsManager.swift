import Foundation

class SKAnalyticsManager {
    static let shared = SKAnalyticsManager()

    private let service: SKAnalyticsService

    private init() {
        #if DEBUG
            self.service = SKDebugAnalytics()
        #else
            self.service = SKFirebaseAnalytics()
        #endif
    }
    
    static func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String
    ) {
        shared.service.logTranslation(
            uri: uri, word: word, word_id: word_id, lang_id: lang_id, dict_name: dict_name, dict_path: dict_path
        )
    }

    static func logAppOpen() {
        shared.service.logAppOpen()
    }
    
    static func logStressClicked(word: String) {
        shared.service.logStressClicked(word: word)
    }
}
