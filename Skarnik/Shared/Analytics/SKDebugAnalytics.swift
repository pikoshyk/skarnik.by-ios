import Foundation

class SKDebugAnalytics: SKAnalyticsService {
    func logEvent(_ name: SKAnalyticsEvent) {
        print("📊 Analytics Event: \(name.rawValue)")
    }

    func logSearch(query: String) {
        print("📊 Search Event: \(query)")
    }

    func logWordView(word: SKWord) {
        print("📊 Word View: \(word.word) (ID: \(word.word_id))")
    }

    func logError(_ error: Error, context: String) {
        print("📊 Error: \(error.localizedDescription) in \(context)")
    }
    
    func logTranslation(uri: String) {
        print("📊 Translation: \(uri)")
    }
}
