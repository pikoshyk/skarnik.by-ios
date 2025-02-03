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
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String
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
            ])
    }

    func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [:])
    }

}
