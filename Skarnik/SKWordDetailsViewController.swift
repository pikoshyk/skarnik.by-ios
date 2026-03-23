//
//  SKWordDetailsViewController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import SwiftUI
import UIKit
import Combine

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
    
    private let viewModel = SKWordDetailsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    var word: SKWord? {
        get { viewModel.word }
        set { viewModel.updateWord(newValue) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.$state
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
            
        viewModel.$word
            .sink { [weak self] word in
                self?.updateWordUI(word)
            }
            .store(in: &cancellables)
            
        viewModel.effectSubject
            .sink { [weak self] effect in
                self?.handleEffect(effect)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: SKWordDetailsState) {
        switch state {
        case .idle:
            setLoading(false)
            textView.attributedText = nil
            updateUrlVisibility(translation: nil)
            updateSpellingButtonVisibility(spellingWords: [])
        case .loading:
            setLoading(true)
            textView.attributedText = nil
            updateUrlVisibility(translation: nil)
            updateSpellingButtonVisibility(spellingWords: [])
        case .success(let translation):
            setLoading(false)
            updateUrlVisibility(translation: translation)
            translation.attributedString { [weak self] attributedString in
                self?.textView.attributedText = attributedString
            }
            updateSpellingButtonVisibility(spellingWords: translation.belWords)
        case .error(let message):
            setLoading(false)
            textView.text = message
            updateUrlVisibility(translation: nil)
            updateSpellingButtonVisibility(spellingWords: [])
        }
    }
    
    private func handleEffect(_ effect: SKWordDetailsEffect) {
        switch effect {
        case .redirection(let originalWord):
            toast(text: "Перанакіравана з «‎\(originalWord)»")
        }
    }
    
    private func updateWordUI(_ word: SKWord?) {
        navigationItem.title = word.map { "«\u{200E}\($0.word)»" }
        labelVocabulary.text = word?.lang_id.wordDetailsSubtitle?.uppercased()
    }
    
    private func setLoading(_ isLoading: Bool) {
        activityIndicatorView.isHidden = !isLoading
        if isLoading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    private func updateUrlVisibility(translation: SKSkarnikTranslation?) {
        if let translation = translation {
            labelUrl.text = translation.url
            labelUrlIcon.isHidden = false
            buttonUrl.isHidden = false
        } else {
            labelUrl.text = " "
            labelUrlIcon.isHidden = true
            buttonUrl.isHidden = true
        }
    }
    
    private func updateSpellingButtonVisibility(spellingWords: [String]) {
        if !spellingWords.isEmpty {
            let buttonItem = UIBarButtonItem(title: SKLocalization.wordDetailsSpelling, 
                                             style: .plain, 
                                             target: self, 
                                             action: #selector(onSpelling))
            buttonItem.tintColor = UIColor(named: "AccentColor")
            navigationItem.rightBarButtonItem = buttonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @IBAction func onOpenUrl() {
        guard let urlStr = viewModel.translation?.url, 
              let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Re-render the attributed string to update colors for the new theme
        viewModel.translation?.attributedString(resultBlock: { [weak self] attributedString in
            self?.textView.attributedText = attributedString
        })
    }

    func toast(text: String) {
        let alertDisapperTimeInSeconds = 2.0
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + alertDisapperTimeInSeconds) {
            alert.dismiss(animated: true)
        }
    }
    
    private func openSpellingWord(_ word: String) {
        setLoading(true)
        SKAnalyticsManager.logStressClicked(word: word)

        Task { @MainActor [weak self] in
            guard let word = await SKStarnikByController.spellingWordSuggestions(belWord: word)?.first,
                  word.wordId != nil else {
                self?.setLoading(false)
                return
            }
            self?.setLoading(false)
            let wordStressViewModel = SKWordStressViewModel(word)
            let wordStressView = SKWordStressView(viewModel: wordStressViewModel)
            let wordStressViewController = UIHostingController(rootView: wordStressView)
            self?.navigationController?.pushViewController(wordStressViewController, animated: true)
        }
    }
    
    @objc func onSpelling() {
        let spellingWords = viewModel.spellingWords
        guard !spellingWords.isEmpty else { return }
        
        if spellingWords.count == 1 {
            openSpellingWord(spellingWords[0])
        } else {
            let alertController = UIAlertController(title: SKLocalization.wordDetailsSpellingTitle, 
                                                    message: SKLocalization.wordDetailsSpellingMessage, 
                                                    preferredStyle: .actionSheet)
            alertController.modalPresentationStyle = .popover
            alertController.view.tintColor = UIColor(named: "AccentColor")
            
            if let popPresenter = alertController.popoverPresentationController {
                popPresenter.barButtonItem = navigationItem.rightBarButtonItem
            }
            
            for spellingWord in spellingWords {
                let action = UIAlertAction(title: spellingWord, style: .default) { [weak self] action in
                    if let word = action.title {
                        self?.openSpellingWord(word)
                    }
                }
                alertController.addAction(action)
            }
            alertController.addAction(UIAlertAction(title: SKLocalization.wordDetailsSpellingCancel, style: .cancel))
            present(alertController, animated: true)
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        viewModel.handleUrl(URL.absoluteString)
        return false
    }
}
