import Foundation

protocol SKAnalyticsService {
    func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String
    )

    func logAppOpen()
    
    func logStressClicked(word: String)
}

enum SKAnalyticsEvent: String {
    case stressClicked = "stress_clicked"
    case translation = "translation"
}
