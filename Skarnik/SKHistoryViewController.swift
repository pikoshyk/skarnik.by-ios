//
//  SKHistoryViewController.swift
//  Skarnik
//

import SwiftUI
import UIKit

class SKHistoryViewController: UIHostingController<SKHistoryView> {

    let viewModel: SKHistoryViewModel

    init() {
        let vm = SKHistoryViewModel()
        self.viewModel = vm
        super.init(rootView: SKHistoryView(viewModel: vm))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SKLocalization.tabHistory
        navigationItem.largeTitleDisplayMode = .never
        rootView = SKHistoryView(
            viewModel: viewModel,
            onWordSelected: { [weak self] word, entryPoint in
                self?.openWord(word, entryPoint: entryPoint)
            }
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
           let word = sceneDelegate.pendingWord {
            sceneDelegate.pendingWord = nil
            openWord(word, entryPoint: "widget")
        }
    }

    // MARK: - Private

    private func openWord(_ word: SKWord, entryPoint: String) {
        if entryPoint != "history" {
            SKStorageController.shared.addWord(word)
            viewModel.reload()
        }
        showWordInDetail(word, entryPoint: entryPoint)
    }
}
