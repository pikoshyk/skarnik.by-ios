import Foundation

protocol SKAnalyticsService {
    func logEvent(_ name: SKAnalyticsEvent)
    func logSearch(query: String)
    func logWordView(word: SKWord)
    func logError(_ error: Error, context: String)
    
    func logTranslation(uri: String)
}

enum SKAnalyticsEvent: String {
    case appOpen = "app_open"
    case searchPerformed = "search_performed"
    case wordViewed = "word_viewed"
    case errorOccurred = "error_occurred"
    case spellingChecked = "spelling_checked"
    case externalLinkOpened = "external_link_opened"
    
    case translation = "translation"
}
