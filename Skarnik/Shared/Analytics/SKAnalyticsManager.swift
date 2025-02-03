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

    static func logEvent(_ name: SKAnalyticsEvent) {
        shared.service.logEvent(name)
    }

    static func logSearch(query: String) {
        shared.service.logSearch(query: query)
    }

    static func logWordView(word: SKWord) {
        shared.service.logWordView(word: word)
    }

    static func logError(_ error: Error, context: String) {
        shared.service.logError(error, context: context)
    }

    static func logTranslation(uri: String) {
        shared.service.logTranslation(uri: uri)
    }
}
