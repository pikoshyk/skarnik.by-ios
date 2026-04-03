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

    init() {
        let vm = SKVocabulariesViewModel()
        self.viewModel = vm
        super.init(rootView: SKVocabulariesView(viewModel: vm))
    }

    required init?(coder: NSCoder) {
        let vm = SKVocabulariesViewModel()
        self.viewModel = vm
        super.init(coder: coder, rootView: SKVocabulariesView(viewModel: vm))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SKLocalization.tabVocabularies
        navigationItem.largeTitleDisplayMode = .never
        rootView = SKVocabulariesView(
            viewModel: viewModel,
            onWordSelected: { [weak self] word, entryPoint in
                self?.openWord(word, entryPoint: entryPoint)
            }
        )
    }

    // MARK: - Private

    private func openWord(_ word: SKWord, entryPoint: String) {
        SKStorageController.shared.addWord(word)
        showWordInDetail(word, entryPoint: entryPoint)
    }
}
