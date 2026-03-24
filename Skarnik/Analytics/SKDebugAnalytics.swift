import Foundation

class SKDebugAnalytics: SKAnalyticsService {
    func logStressClicked(word: String) {
        print("📊 Stress clicked: \(word)")
    }

    func logAppOpen() {
        print("📊 App Open")
    }

    func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String, source_name: String
    ) {
        print("📊 Translation: \(uri), \(word), \(word_id), \(lang_id), \(dict_name), \(dict_path), \(source_name)")
    }
}
