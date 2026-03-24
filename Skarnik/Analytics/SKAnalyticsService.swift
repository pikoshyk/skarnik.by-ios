import Foundation

protocol SKAnalyticsService {
    func logTranslation(
        uri: String, word: String, word_id: Int64, lang_id: Int, dict_name: String, dict_path: String, source_name: String, entry_point: String
    )

    func logAppOpen()
    
    func logStressClicked(word: String)

    func logStarnikByOpened()

    func logWidgetDeepLink(word: SKWord, appState: SKWidgetDeepLinkAppState)
}

enum SKAnalyticsEvent: String {
    case stressClicked = "stress_clicked"
    case translation = "translation"
    case starnikByOpened = "starnik_by_opened"
    case widgetDeepLink = "widget_deep_link"
}

enum SKWidgetDeepLinkAppState: String {
    case coldStart = "cold_start"
    case background = "background"
}
