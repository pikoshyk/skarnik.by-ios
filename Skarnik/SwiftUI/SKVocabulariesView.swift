//
//  SKVocabulariesView.swift
//  Skarnik
//

import SwiftUI

extension View {
    @ViewBuilder
    fileprivate func vocabularyListBackground() -> some View {
        if #available(iOS 16, *) {
            self.scrollContentBackground(.hidden).background(Color.appBackground)
        } else {
            self.background(Color.appBackground)
        }
    }
}

// MARK: - UIKit bridge: scroll-driven nav bar collapse
//
// hidesBarsOnSwipe does not detect the UITableView inside UIHostingController automatically.
// Instead we walk the parent view controller's view tree to find the UIScrollView,
// attach a KVO observer on contentOffset, and drive setNavigationBarHidden manually.

private struct HidesBarsOnSwipeModifier: UIViewControllerRepresentable {
    let enabled: Bool
    /// Incremented by the caller whenever the tracked scroll view is replaced
    /// (e.g. tab switch with .id() causes List to recreate its UITableView).
    let resetToken: Int

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ vc: Controller, context: Context) {
        if !enabled {
            vc.enabled = false
        } else if vc.lastResetToken != resetToken {
            vc.lastResetToken = resetToken
            vc.showAndReattach()
        } else {
            vc.enabled = true
        }
    }

    final class Controller: UIViewController {
        var enabled = false {
            didSet { if !enabled { resetToVisible() } }
        }
        var lastResetToken = 0

        private var observation: NSKeyValueObservation?
        private var lastOffset: CGFloat = 0

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if enabled { attachObservation() }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            observation = nil
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }

        /// Show the nav bar and re-attach KVO on the (possibly new) UITableView.
        /// Deferred one run loop so SwiftUI can finish creating the new List first.
        func showAndReattach() {
            navigationController?.setNavigationBarHidden(false, animated: true)
            DispatchQueue.main.async { [weak self] in self?.attachObservation() }
        }

        private func attachObservation() {
            observation = nil
            guard enabled, let scrollView = firstScrollView(in: parent?.view) else { return }
            lastOffset = scrollView.contentOffset.y
            observation = scrollView.observe(\.contentOffset, options: .new) { [weak self] sv, _ in
                DispatchQueue.main.async { self?.handleOffset(sv.contentOffset.y) }
            }
        }

        private func resetToVisible() {
            observation = nil
            navigationController?.setNavigationBarHidden(false, animated: true)
        }

        private func firstScrollView(in view: UIView?) -> UIScrollView? {
            guard let view else { return nil }
            if let sv = view as? UIScrollView { return sv }
            for sub in view.subviews {
                if let found = firstScrollView(in: sub) { return found }
            }
            return nil
        }

        private func handleOffset(_ offset: CGFloat) {
            guard enabled, let nav = navigationController else { return }
            let delta = offset - lastOffset
            lastOffset = offset
            if delta > 10 && offset > 40 && !nav.isNavigationBarHidden {
                nav.setNavigationBarHidden(true, animated: true)
            } else if delta < -10 && nav.isNavigationBarHidden {
                nav.setNavigationBarHidden(false, animated: true)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SKVocabulariesViewModel: ObservableObject {
    @Published var selectedType: ESKVocabularyType = .rus_bel {
        didSet { updateSectionTitles() }
    }
    @Published private(set) var sectionTitles: [String] = []
    @Published private(set) var sectionWords: [String: [SKWord]] = [:]

    private var loadWordsTask: Task<Void, Never>?

    init() {
        updateSectionTitles()
    }

    func updateSectionTitles() {
        loadWordsTask?.cancel()
        sectionTitles = SKVocabularyIndex.shared.wordsIndexes(vocabularyType: selectedType)
        sectionWords = [:]
        loadSectionWords()
    }

    private func loadSectionWords() {
        let type = selectedType
        let titles = sectionTitles
        loadWordsTask = Task.detached(priority: .userInitiated) { [weak self] in
            for title in titles {
                guard !Task.isCancelled else { return }
                let words = SKVocabularyIndex.shared.word(index: 0, query: title, vocabularyType: type, limit: 10_000)
                guard !words.isEmpty else { continue }
                await MainActor.run { self?.sectionWords[title] = words }
            }
        }
    }

}

// MARK: - Section index scrubber

private struct SectionScrubber: View {
    let titles: [String]
    let proxy: ScrollViewProxy

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ForEach(titles, id: \.self) { title in
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let fraction = value.location.y / max(geo.size.height, 1)
                        let index = Int(fraction * CGFloat(titles.count))
                        let clamped = max(0, min(titles.count - 1, index))
                        proxy.scrollTo(titles[clamped], anchor: .top)
                    }
            )
        }
    }
}

// MARK: - Content view

private struct SKVocabulariesContentView: View {
    @ObservedObject var viewModel: SKVocabulariesViewModel
    var onWordSelected: (SKWord, String) -> Void

    @State private var swipeModifierToken = 0

    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            Divider()
            dictionaryContent
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .background(HidesBarsOnSwipeModifier(enabled: true, resetToken: swipeModifierToken))
        .onChange(of: viewModel.selectedType) { _ in swipeModifierToken += 1 }
    }

    // MARK: Segmented picker

    private var segmentPicker: some View {
        Picker("", selection: $viewModel.selectedType) {
            Text(SKLocalization.segmentRusBel).tag(ESKVocabularyType.rus_bel)
            Text(SKLocalization.segmentBelRus).tag(ESKVocabularyType.bel_rus)
            Text(SKLocalization.segmentDefinition).tag(ESKVocabularyType.bel_definition)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Dictionary with A–Z scrubber

    private var dictionaryContent: some View {
        let titles = viewModel.sectionTitles
        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(titles, id: \.self) { section in
                        Section(section) {
                            ForEach(viewModel.sectionWords[section] ?? [], id: \.word_id) { word in
                                Button {
                                    onWordSelected(word, "vocabulary")
                                } label: {
                                    Text(word.word)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .listRowBackground(Color.appBackground)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .vocabularyListBackground()
                .id(viewModel.selectedType)
                .transition(.identity)

                if !titles.isEmpty {
                    SectionScrubber(titles: titles, proxy: proxy)
                        .frame(width: 18)
                }
            }
        }
    }

    // MARK: Cell helper

    @ViewBuilder
    private func wordCell(_ word: SKWord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(word.word).foregroundColor(.primary)
            if let name = word.lang_id.name {
                Text(name.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Main view

struct SKVocabulariesView: View {
    @ObservedObject var viewModel: SKVocabulariesViewModel
    var onWordSelected: (SKWord, String) -> Void = { _, _ in }

    var body: some View {
        SKVocabulariesContentView(viewModel: viewModel, onWordSelected: onWordSelected)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#if DEBUG
    #Preview("Vocabularies") {
        NavigationView {
            SKVocabulariesView(viewModel: SKVocabulariesViewModel())
        }
    }

    #Preview("Russian–Belarusian") {
        let vm = SKVocabulariesViewModel()
        vm.selectedType = .rus_bel
        return NavigationView {
            SKVocabulariesView(viewModel: vm)
        }
    }

    #Preview("Belarusian–Russian") {
        let vm = SKVocabulariesViewModel()
        vm.selectedType = .bel_rus
        return NavigationView {
            SKVocabulariesView(viewModel: vm)
        }
    }
#endif
