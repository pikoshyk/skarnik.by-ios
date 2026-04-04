//
//  SKVocabulariesView.swift
//  Skarnik
//

import SwiftUI

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

    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            Divider()
            dictionaryContent
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
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
                .modifier(ListBackgroundModifier())
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
