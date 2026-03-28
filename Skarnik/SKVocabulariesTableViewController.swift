//
//  SKDictionariesTableViewController.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import SwiftUI
import UIKit

class SKVocabulariesTableViewController: UIHostingController<SKVocabulariesView> {

    let viewModel: SKVocabulariesViewModel

    required init?(coder: NSCoder) {
        let vm = SKVocabulariesViewModel()
        self.viewModel = vm
        super.init(coder: coder, rootView: SKVocabulariesView(viewModel: vm))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = SKVocabulariesView(
            viewModel: viewModel,
            onWordSelected: { [weak self] word, entryPoint in
                self?.openWord(word, fromHistory: entryPoint == "history", entryPoint: entryPoint)
            },
            onOpenStarnikBy: { [weak self] in
                self?.openStarnikBy()
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadHistory()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           let word = sceneDelegate.pendingWord {
            sceneDelegate.pendingWord = nil
            openWord(word, fromHistory: false, entryPoint: "widget")
        }
    }

    // MARK: - Private

    private func openWord(_ word: SKWord, fromHistory: Bool, entryPoint: String = "vocabulary") {
        if !fromHistory {
            SKStorageController.shared.addWord(word)
            viewModel.reloadHistory()
        }

        var wordDetailsViewController: SKWordDetailsViewController?
        if #available(iOS 14.0, *) {
            wordDetailsViewController = splitViewController?.viewController(for: .secondary) as? SKWordDetailsViewController
        } else {
            let controllers = splitViewController?.viewControllers
            let count = controllers?.count ?? 0
            if count == 1 {
                wordDetailsViewController = storyboard?.instantiateViewController(
                    withIdentifier: "SKWordDetailsViewController"
                ) as? SKWordDetailsViewController
            } else if count >= 2 {
                wordDetailsViewController = controllers?.last as? SKWordDetailsViewController
            }
        }

        if let vc = wordDetailsViewController {
            splitViewController?.showDetailViewController(vc, sender: self)
            vc.entryPoint = entryPoint
            vc.word = word
        }
    }

    private func openStarnikBy() {
        guard let url = URL(string: "https://starnik.by") else { return }
        SKAnalyticsManager.logStarnikByOpened()
        UIApplication.shared.open(url)
    }
}
