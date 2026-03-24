//
//  SKWordDetailsViewModel.swift
//  Skarnik
//
//  Created by Gemini on 8.03.26.
//

import Foundation
import UIKit
import Combine

enum SKWordDetailsState {
    case idle
    case loading
    case success(SKSkarnikTranslation)
    case error(String)
}

enum SKWordDetailsEffect {
    case redirection(String)
}

@MainActor
class SKWordDetailsViewModel: ObservableObject {
    @Published private(set) var state: SKWordDetailsState = .idle
    @Published var word: SKWord?

    private var fetchTask: Task<Void, Never>?
    let effectSubject = PassthroughSubject<SKWordDetailsEffect, Never>()
    private let translationSource: any SKTranslationSource

    init(translationSource: any SKTranslationSource = SKFallbackTranslationSource.shared) {
        self.translationSource = translationSource
    }
    
    var translation: SKSkarnikTranslation? {
        if case .success(let translation) = state {
            return translation
        }
        return nil
    }
    
    var spellingWords: [String] {
        return translation?.belWords ?? []
    }
    
    var navigationTitle: String? {
        guard let word = word else { return nil }
        return "«‎\(word.word)»"
    }
    
    var vocabularySubtitle: String? {
        return word?.lang_id.wordDetailsSubtitle?.uppercased()
    }
    
    func updateWord(_ word: SKWord?) {
        // Cancel any ongoing fetch task for a previous word
        fetchTask?.cancel()
        
        guard let word = word else {
            self.word = nil
            self.state = .idle
            return
        }
        
        // Avoid redundant updates if it's the same word and already loaded
        if self.word?.word_id == word.word_id && self.word?.lang_id == word.lang_id {
            if case .success = state { return }
            if case .loading = state { return }
        }

        self.word = word
        self.state = .loading
        
        fetchTask = Task {
            do {
                guard let translation = try await translationSource.wordTranslation(word) else {
                    if !Task.isCancelled {
                        self.state = .error(SKLocalization.errorWordNotFound)
                    }
                    return
                }
                
                // Check cancellation again after the async call
                guard !Task.isCancelled else { return }
                
                SKAnalyticsManager.logTranslation(
                    uri: translation.url,
                    word: translation.word.word,
                    word_id: word.word_id,
                    lang_id: word.lang_id.rawValue,
                    dict_name: word.lang_id.name ?? "unknown",
                    dict_path: word.lang_id.skarnikId ?? "unknown",
                    source_name: translation.sourceName
                )
                
                if word.word_id == translation.word.word_id && word.lang_id == translation.word.lang_id {
                    self.state = .success(translation)
                    SKAppstoreReviewController.requestReview()
                } else {
                    let redirectedFrom = word.word
                    self.word = translation.word
                    self.state = .success(translation)
                    self.effectSubject.send(.redirection(redirectedFrom))
                }
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch SKSkarnikError.networkError {
                if !Task.isCancelled {
                    self.state = .error(SKLocalization.errorNetworkErrorTryAgainLater)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func handleUrl(_ urlString: String) {
        let regexPattern = #"(https?://(www.)?skarnik.by)?/(?<vocabularyPath>belrus|rusbel|tsbm)/(?<wordId>[0-9]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []),
              let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.utf16.count)) else {
            return
        }
        
        let vocabularyPath = extractNamedGroup(from: match, named: "vocabularyPath", in: urlString)
        let wordIdString = extractNamedGroup(from: match, named: "wordId", in: urlString)
        
        if let vocabularyPath = vocabularyPath,
           let wordIdString = wordIdString,
           let wordId = Int64(wordIdString),
           let vocabularyType = ESKVocabularyType.from(vocabularyPath: vocabularyPath) {
            let newWord = SKVocabularyIndex.shared.word(id: wordId, vocabularyType: vocabularyType)
            self.updateWord(newWord)
        }
    }
    
    private func extractNamedGroup(from match: NSTextCheckingResult, named groupName: String, in text: String) -> String? {
        let groupRange = match.range(withName: groupName)
        if groupRange.location != NSNotFound, let range = Range(groupRange, in: text) {
            return String(text[range])
        }
        return nil
    }
}
