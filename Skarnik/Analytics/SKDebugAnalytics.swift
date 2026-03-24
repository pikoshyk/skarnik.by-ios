import Foundation

class SKDebugAnalytics: SKAnalyticsService {
    func logStressClicked(word: String) {
        print("📊 Stress clicked: \(word)")
    }

    func logAppOpen() {
        print("📊 App Open")
    }

    func logStarnikByOpened() {
        print("📊 Starnik.by opened")
    }

    func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String, source_name: String, entry_point: String
    ) {
        print("📊 Translation: \(uri), \(word), \(word_id), \(lang_id), \(dict_name), \(dict_path), \(source_name), \(entry_point)")
    }
}
