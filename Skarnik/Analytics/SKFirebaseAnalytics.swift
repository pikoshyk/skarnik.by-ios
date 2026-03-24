import FirebaseAnalytics
import Foundation

class SKFirebaseAnalytics: SKAnalyticsService {
    func logStressClicked(word: String) {
        Analytics.logEvent(
            SKAnalyticsEvent.stressClicked.rawValue,
            parameters: [
                "word": word,
            ])
    }
    
    func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String, source_name: String, entry_point: String
    ) {
        Analytics.logEvent(
            SKAnalyticsEvent.translation.rawValue,
            parameters: [
                "uri": uri,
                "word": word,
                "word_id": word_id,
                "lang_id": lang_id,
                "dict_name": dict_name,
                "dict_path": dict_path,
                "source_name": source_name,
                "entry_point": entry_point,
            ])
    }

    func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [:])
    }

    func logStarnikByOpened() {
        Analytics.logEvent(SKAnalyticsEvent.starnikByOpened.rawValue, parameters: [:])
    }

    func logWidgetDeepLink(word: SKWord, appState: SKWidgetDeepLinkAppState) {
        Analytics.logEvent(SKAnalyticsEvent.widgetDeepLink.rawValue, parameters: [
            "word": word.word,
            "word_id": word.word_id,
            "lang_id": word.lang_id.rawValue,
            "app_state": appState.rawValue,
        ])
    }

}
