//
//  SKWordDetailsViewController.swift
//  Skarnik
//
//  Created by Logout on 11.10.22.
//

import SwiftUI
import UIKit

class SKWordDetailsViewController: UIHostingController<SKWordDetailsView> {

    let viewModel: SKWordDetailsViewModel

    required init?(coder: NSCoder) {
        let vm = SKWordDetailsViewModel()
        self.viewModel = vm
        super.init(coder: coder, rootView: SKWordDetailsView(viewModel: vm))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = SKWordDetailsView(
            viewModel: viewModel,
            onSpellingWord: { [weak self] word in self?.openSpellingWord(word) },
            onReport: { [weak self] in self?.presentReport() }
        )
    }

    var word: SKWord? {
        get { viewModel.word }
        set { viewModel.updateWord(newValue) }
    }

    var entryPoint: String {
        get { viewModel.entryPoint }
        set { viewModel.entryPoint = newValue }
    }

    func onReport() {
        presentReport()
    }

    // MARK: - Private

    private func presentReport() {
        if #available(iOS 14, *) {
            let reportView = SKReportIssueView(
                word: viewModel.word,
                translationUrl: viewModel.translation?.url
            )
            let hostingController = UIHostingController(rootView: reportView)
            if #available(iOS 15, *) {
                if let sheet = hostingController.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    if #available(iOS 16, *) {
                        sheet.preferredCornerRadius = 20
                    }
                }
            }
            present(hostingController, animated: true)
        }
    }

    private func openSpellingWord(_ word: String) {
        SKAnalyticsManager.logStressClicked(word: word)

        Task { @MainActor [weak self] in
            guard let word = await SKStarnikByController.spellingWordSuggestions(belWord: word)?.first,
                  word.wordId != nil else {
                return
            }
            let wordStressViewModel = SKWordStressViewModel(word)
            let wordStressView = SKWordStressView(viewModel: wordStressViewModel)
            let wordStressViewController = UIHostingController(rootView: wordStressView)
            self?.navigationController?.pushViewController(wordStressViewController, animated: true)
        }
    }
}
