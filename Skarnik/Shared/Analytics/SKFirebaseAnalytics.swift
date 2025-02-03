import FirebaseAnalytics
import Foundation

class SKFirebaseAnalytics: SKAnalyticsService {
    func logEvent(_ name: SKAnalyticsEvent) {
        Analytics.logEvent(name.rawValue, parameters: nil)
    }

    func logSearch(query: String) {
        Analytics.logEvent(
            SKAnalyticsEvent.searchPerformed.rawValue,
            parameters: [
                "search_term": query
            ])
    }

    func logWordView(word: SKWord) {
        Analytics.logEvent(
            SKAnalyticsEvent.wordViewed.rawValue,
            parameters: [
                "word_id": word.word_id,
                "word": word.word,
                "vocabulary": word.lang_id.rawValue,
            ])
    }

    func logError(_ error: Error, context: String) {
        Analytics.logEvent(
            SKAnalyticsEvent.errorOccurred.rawValue,
            parameters: [
                "error_description": error.localizedDescription,
                "context": context,
            ])
    }

    func logTranslation(uri: String) {
        Analytics.logEvent(
            SKAnalyticsEvent.translation.rawValue,
            parameters: [
                "uri": uri,
            ])
    }
}
