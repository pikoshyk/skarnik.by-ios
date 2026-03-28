//
//  SKVocabulariesView.swift
//  Skarnik
//

import SwiftUI

// MARK: - ViewModel

@MainActor
final class SKVocabulariesViewModel: ObservableObject {
    @Published var selectedType: ESKVocabularyType = .history {
        didSet { reloadHistory(); updateSectionTitles() }
    }
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [SKWord] = []
    @Published private(set) var historyWords: [SKWord] = []
    @Published private(set) var sectionTitles: [String] = []

    private var searchTask: Task<Void, Never>?

    init() {
        reloadHistory()
        updateSectionTitles()
    }

    func reloadHistory() {
        historyWords = SKStorageController.shared.words
    }

    func updateSectionTitles() {
        guard selectedType != .history else {
            sectionTitles = []
            return
        }
        sectionTitles = SKVocabularyIndex.shared.wordsIndexes(vocabularyType: selectedType)
    }

    func updateSearch(_ text: String) {
        searchTask?.cancel()
        guard !text.isEmpty else { searchResults = []; return }
        let query = text.lowercased()
        searchTask = Task {
            let results = await Task.detached(priority: .userInitiated) {
                SKVocabularyIndex.shared.word(index: 0, query: query, vocabularyType: .all, limit: 20)
            }.value
            guard !Task.isCancelled else { return }
            searchResults = results
        }
    }

    func deleteHistoryWord(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            SKStorageController.shared.removeWord(index: index)
        }
        reloadHistory()
    }
}

// MARK: - Lazy section content

private struct LazySectionContent: View {
    let sectionTitle: String
    let vocabularyType: ESKVocabularyType
    let onSelect: (SKWord) -> Void
    @State private var words: [SKWord] = []

    var body: some View {
        if words.isEmpty {
            Color.clear.frame(height: 0).onAppear(perform: load)
        } else {
            ForEach(words, id: \.word_id) { word in
                Button {
                    onSelect(word)
                } label: {
                    Text(word.word)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func load() {
        let section = sectionTitle
        let type = vocabularyType
        Task.detached(priority: .userInitiated) {
            let count = SKVocabularyIndex.shared.wordsCount(query: section, vocabularyType: type)
            guard count > 0 else { return }
            let loaded = SKVocabularyIndex.shared.word(
                index: 0, query: section, vocabularyType: type, limit: count
            )
            await MainActor.run { words = loaded }
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
                        .foregroundColor(Color("AccentColor"))
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

// MARK: - Content view (reads isSearching from environment)

private struct SKVocabulariesContentView: View {
    @ObservedObject var viewModel: SKVocabulariesViewModel
    @Environment(\.isSearching) private var isSearching
    var onWordSelected: (SKWord, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !isSearching {
                segmentPicker
                Divider()
            }
            mainContent
        }
    }

    // MARK: Segmented picker

    private var segmentPicker: some View {
        Picker("", selection: $viewModel.selectedType) {
            Text(SKLocalization.segmentHistory).tag(ESKVocabularyType.history)
            Text(SKLocalization.segmentRusBel).tag(ESKVocabularyType.rus_bel)
            Text(SKLocalization.segmentBelRus).tag(ESKVocabularyType.bel_rus)
            Text(SKLocalization.segmentDefinition).tag(ESKVocabularyType.bel_definition)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: Content routing

    @ViewBuilder
    private var mainContent: some View {
        if isSearching {
            searchContent
        } else if viewModel.selectedType == .history {
            historyContent
        } else {
            dictionaryContent
        }
    }

    // MARK: History

    @ViewBuilder
    private var historyContent: some View {
        if viewModel.historyWords.isEmpty {
            VStack {
                Spacer()
                Text(SKLocalization.historyEmptyPlaceholder)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        } else {
            List {
                ForEach(viewModel.historyWords, id: \.word_id) { word in
                    Button {
                        onWordSelected(word, "history")
                    } label: {
                        wordCell(word)
                    }
                }
                .onDelete { viewModel.deleteHistoryWord(at: $0) }
            }
            .listStyle(.plain)
        }
    }

    // MARK: Dictionary with A–Z scrubber

    private var dictionaryContent: some View {
        let titles = viewModel.sectionTitles
        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    ForEach(titles, id: \.self) { section in
                        Section(section) {
                            LazySectionContent(
                                sectionTitle: section,
                                vocabularyType: viewModel.selectedType,
                                onSelect: { onWordSelected($0, "vocabulary") }
                            )
                        }
                        .id(section)
                    }
                }
                .listStyle(.plain)
                .id(viewModel.selectedType)

                if !titles.isEmpty {
                    SectionScrubber(titles: titles, proxy: proxy)
                        .frame(width: 18)
                }
            }
        }
    }

    // MARK: Search results

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.searchResults.isEmpty {
            VStack {
                Text(SKLocalization.searchHeaderAdditionalRules)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding()
                Spacer()
            }
        } else {
            List(viewModel.searchResults, id: \.word_id) { word in
                Button {
                    onWordSelected(word, "search")
                } label: {
                    wordCell(word)
                }
            }
            .listStyle(.plain)
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
    var onOpenStarnikBy: () -> Void = {}

    private let keyboardChars = ["'", "ў", "і", "ъ", "щ", "и"]

    var body: some View {
        SKVocabulariesContentView(viewModel: viewModel, onWordSelected: onWordSelected)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(SKLocalization.vocabulariesAdvancedSearch, action: onOpenStarnikBy)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    ForEach(keyboardChars, id: \.self) { char in
                        Button(char) { viewModel.searchText += char }
                            .font(.system(size: 17))
                    }
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: SKLocalization.searchbarSearchWords
            )
            .onChange(of: viewModel.searchText) { text in
                viewModel.updateSearch(text)
            }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("History (empty)") {
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
