//
//  SKWordDetailsViewController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import UIKit

class SKWordDetailsViewController: UIViewController {
    
    @IBOutlet var labelVocabulary: UILabel!
    @IBOutlet var labelUrl: UILabel!
    @IBOutlet var textView: UITextView!
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
                translation.attributedString(resultBlock: { attributedString in
                    self.textView.attributedText = attributedString
                })
                if translation.word.lang_id == .bel_definition || translation.word.lang_id == .bel_rus {
                    let buttonItem = UIBarButtonItem(title: SKLocalization.wordDetailsSpelling, style: .plain, target: self, action: #selector(onSpelling))
                    buttonItem.tintColor = UIColor.systemRed
                    self.navigationItem.rightBarButtonItem = buttonItem
                } else {
                    self.navigationItem.rightBarButtonItem = nil
                }
            } else {
                self.navigationItem.rightBarButtonItem = nil
                self.labelUrl.text = " "
                self.textView.attributedText = nil
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
        Task {
            var translation: SKSkarnikTranslation?
            do {
                translation = try await SKSkarnikByController.wordTranslation(word)
            } catch SKSkarnikError.networkError {
                self.showLoadingIndicator = false
                self.textView.text = SKLocalization.errorNetworkErrorTryAgainLater
                return
            }

            guard let translation = translation else {
                self.showLoadingIndicator = false
                self.textView.text = SKLocalization.errorWordNotFound
                return
            }
            if self.word?.word_id == translation.word.word_id {
                self.showLoadingIndicator = false
                self.translation = translation
            }
        }
    }
    
    @objc func onSpelling() {
        guard let word = self.translation?.word.word else {
            return
        }
        
        Task {
            guard let word = await SKStarnikByController.spellingWordSuggestions(belWord: word)?.first else {
                return
            }
            guard let url = word.url else {
                return
            }
            _ = await UIApplication.shared.open(url)
        }
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
}
