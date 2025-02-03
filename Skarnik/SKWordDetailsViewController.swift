//
//  SKWordDetailsViewController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import SwiftUI
import UIKit

class SKWordDetailsViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var labelVocabulary: UILabel!
    @IBOutlet var buttonUrl: UIButton!
    @IBOutlet var labelUrl: UILabel!
    @IBOutlet var labelUrlIcon: UIImageView!
    @IBOutlet var textView: UITextView! {
        didSet {
            textView.delegate = self
            textView.isEditable = false
            textView.isSelectable = true
            textView.dataDetectorTypes = .link
        }
    }
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var showLoadingIndicator: Bool {
        get {
            return !self.activityIndicatorView.isHidden
        }
        set {
            let status = newValue
            if status {
                self.activityIndicatorView.startAnimating()
                self.activityIndicatorView.isHidden = false
            } else {
                self.activityIndicatorView.isHidden = true
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
    var translation: SKSkarnikTranslation? {
        didSet {
            if let translation = self.translation {
                self.labelUrl.text = translation.url
                self.labelUrlIcon.isHidden = false
                self.buttonUrl.isHidden = false
                translation.attributedString(resultBlock: { attributedString in
                    self.textView.attributedText = attributedString
                })
                self.spellingWords = translation.belWords
            } else {
                self.spellingWords = []
                self.labelUrl.text = " "
                self.labelUrlIcon.isHidden = true
                self.buttonUrl.isHidden = true
                self.textView.attributedText = nil
            }
        }
    }
    
    var spellingWords: [String]? {
        didSet {
            if (self.spellingWords?.count ?? 0) > 0 {
                self.showSpellButton = true
            } else {
                self.showSpellButton = false
            }
        }
    }
    
    var showSpellButton: Bool? {
        didSet {
            if self.showSpellButton ?? false {
                let buttonItem = UIBarButtonItem(title: SKLocalization.wordDetailsSpelling, style: .plain, target: self, action: #selector(onSpelling))
                buttonItem.tintColor = UIColor(named: "AccentColor")
                self.navigationItem.rightBarButtonItem = buttonItem
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }

    var word: SKWord? {
        didSet {
            _ = self.view
            self.updateWord(self.word)
        }
    }
    
    @IBAction func onOpenUrl() {
        guard let urlStr = self.translation?.url else {
            return
        }

        guard let url = URL(string: urlStr) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.translation?.attributedString(resultBlock: { attributedString in
            self.textView.attributedText = attributedString
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateWord(_ word: SKWord?) {
        guard let word = word else {
            self.navigationItem.title = nil
            self.textView.attributedText = nil
            self.translation = nil
            self.labelVocabulary.text = nil
            self.showLoadingIndicator = false
            return
        }

        self.navigationItem.title = "«‎\(word.word)»"
        self.labelVocabulary.text = word.lang_id.wordDetailsSubtitle?.uppercased()
        self.textView.attributedText = nil
        self.translation = nil
        self.showLoadingIndicator = true
        Task { @MainActor [weak self] in
            var translation: SKSkarnikTranslation?
            do {
                translation = try await SKSkarnikByController.wordTranslation(word)
            } catch SKSkarnikError.networkError {
                self?.showLoadingIndicator = false
                self?.textView.text = SKLocalization.errorNetworkErrorTryAgainLater
                return
            }

            guard let translation = translation else {
                self?.showLoadingIndicator = false
                self?.textView.text = SKLocalization.errorWordNotFound
                return
            }
            if self?.word?.word_id == translation.word.word_id {
                self?.showLoadingIndicator = false
                self?.translation = translation
                
                SKAppstoreReviewController.requestReview()
            } else {
                self?.showLoadingIndicator = false
                self?.toast(text: "Перанакіравана з «‎\(word.word)»")
                self?.word = translation.word
                self?.translation = translation
            }
        }
    }

    func toast(text: String) {
        let alertDisapperTimeInSeconds = 2.0
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + alertDisapperTimeInSeconds) {
            alert.dismiss(animated: true)
        }
    }
    
    func openSpellingWord(_ word: String) {
        self.showLoadingIndicator = true

        Task { @MainActor [weak self] in
            guard let word = await SKStarnikByController.spellingWordSuggestions(belWord: word)?.first else {
                self?.showLoadingIndicator = false
                return
            }
            guard word.wordId != nil else {
                self?.showLoadingIndicator = false
                return
            }
            self?.showLoadingIndicator = false
            let wordStressViewModel = SKWordStressViewModel(word)
            let wordStressView = SKWordStressView(viewModel: wordStressViewModel)
            let wordStressViewController = UIHostingController(rootView: wordStressView)
            DispatchQueue.main.async {
                self?.navigationController?.pushViewController(wordStressViewController, animated: true)
            }
        }
    }
    
    @objc func onSpelling() {
        guard let spellingWords = self.spellingWords else {
            return
        }
        if spellingWords.count == 1 {
            if let word = spellingWords.first {
                self.openSpellingWord(word)
            }
        } else {
            let alertController = UIAlertController(title: SKLocalization.wordDetailsSpellingTitle, message: SKLocalization.wordDetailsSpellingMessage, preferredStyle: .actionSheet)
            alertController.modalPresentationStyle = .popover
            alertController.view.tintColor = UIColor(named: "AccentColor")
            let popPresenter = alertController.popoverPresentationController
            popPresenter?.barButtonItem = self.navigationItem.rightBarButtonItem
            for spellingWord in spellingWords {
                let action = UIAlertAction(title: spellingWord, style: .default, handler: { action in
                    if let word = action.title {
                        self.openSpellingWord(word)
                    }
                })
                alertController.addAction(action)
            }
            alertController.addAction(UIAlertAction(title: SKLocalization.wordDetailsSpellingCancel, style: .cancel))
            self.present(alertController, animated: true)
        }
        
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        parseAndHandleSkarnikUrl(URL.absoluteString)
        return false
    }

    /// Parses a Skarnik URL and extracts dictionary path and word ID components
    /// - Parameter urlLink: The URL string to parse (e.g. "https://skarnik.by/belrus/60754")
    /// - Note: Supports URLs with or without protocol/www prefix
    /// - Note: Valid dictionary paths are: belrus, rusbel, tsbm
    private func parseAndHandleSkarnikUrl(_ urlLink: String) {
        let regexPattern = #"(https?://(www.)?skarnik.by)?/(?<vocabularyPath>belrus|rusbel|tsbm)/(?<wordId>[0-9]+)"#

        do {
            // Create the regular expression
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])

            // Check if the appLink matches the regex
            let range = NSRange(location: 0, length: urlLink.utf16.count)
            if regex.firstMatch(in: urlLink, options: [], range: range) == nil {
                throw NSError(
                    domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse link \(urlLink)"])
            }

            // Extract named capturing groups
            let matches = regex.matches(in: urlLink, options: [], range: range)
            guard let firstMatch = matches.first else {
                throw NSError(
                    domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse link \(urlLink)"])
            }

            // Extract `vocabularyPath` and `wordId`
            guard let vocabularyPath = extractNamedGroup(from: firstMatch, named: "vocabularyPath", in: urlLink),
                  let wordIdString = extractNamedGroup(from: firstMatch, named: "wordId", in: urlLink),
                  let wordId = Int64(wordIdString),
                  let vocabularyType = ESKVocabularyType.with(vocabularyPath: vocabularyPath)
            else {
                return
            }
            
            let newWord = SKVocabularyIndex.shared.word(id: wordId, vocabularyType: vocabularyType)
            self.word = newWord
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    /// Extracts a named capture group value from a regex match result
    /// - Parameters:
    ///   - match: The NSTextCheckingResult containing the match data
    ///   - groupName: The name of the capture group to extract
    ///   - text: The original text that was matched against
    /// - Returns: The extracted string if the named group exists and has a valid range, nil otherwise
    private func extractNamedGroup(from match: NSTextCheckingResult, named groupName: String, in text: String) -> String? {
        let groupRange = match.range(withName: groupName)
        if groupRange.location != NSNotFound, let range = Range(groupRange, in: text) {
            return String(text[range])
        }
        return nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ESKVocabularyType {
    var wordDetailsSubtitle: String? {
        get {
            if self == .rus_bel { return SKLocalization.wordDetailsSubtitleRusBel }
            if self == .bel_rus { return SKLocalization.wordDetailsSubtitleBelRus }
            if self == .bel_definition { return SKLocalization.wordDetailsSubtitleDenifition }
            return nil
        }
    }
    
    static func with(vocabularyPath pathValue: String)-> ESKVocabularyType? {
        return switch(pathValue) {
        case "tsbm": .bel_definition
        case "belrus": .bel_rus
        case "rusbel": .rus_bel
        default: nil
        }
    }
}
