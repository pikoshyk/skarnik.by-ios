//
//  SKHistoryView.swift
//  Skarnik
//

import SwiftUI

// MARK: - ViewModel

@MainActor
final class SKHistoryViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet { updateSearch(searchText) }
    }
    @Published private(set) var searchResults: [SKWord] = []
    @Published private(set) var words: [SKWord] = []

    private var searchTask: Task<Void, Never>?

    func reload() {
        words = SKStorageController.shared.words
    }

    func deleteWord(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            SKStorageController.shared.removeWord(index: index)
        }
        reload()
    }

    func updateSearch(_ text: String) {
        searchTask?.cancel()
        guard !text.isEmpty else {
            searchResults = []
            return
        }
        let query = text.lowercased()
        searchTask = Task {
            let detachedTask = Task.detached(priority: .userInitiated) {
                SKVocabularyIndex.shared.word(index: 0, query: query, vocabularyType: .all, limit: 20)
            }
            let results = await withTaskCancellationHandler {
                await detachedTask.value
            } onCancel: {
                detachedTask.cancel()
            }
            guard !Task.isCancelled else { return }
            searchResults = results
        }
    }
}

// MARK: - Content view (reads isSearching from environment)

private struct SKHistoryContentView: View {
    @ObservedObject var viewModel: SKHistoryViewModel
    @Environment(\.isSearching) private var isSearching
    var onWordSelected: (SKWord, String) -> Void

    private static let rusKeyboardChars = ["и", "щ", "ъ"]
    private static let belKeyboardChars = ["і", "ў", "'"]

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .overlay(alignment: .bottom) {
                if isSearching { belarusianKeyboardRow }
            }
    }

    // MARK: Content routing

    @ViewBuilder
    private var mainContent: some View {
        if isSearching {
            searchContent
        } else if viewModel.words.isEmpty {
            emptyState
        } else {
            wordList
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            Text(SKLocalization.historyEmptyPlaceholder)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }

    // MARK: History list

    private var wordList: some View {
        List {
            ForEach(viewModel.words, id: \.word_id) { word in
                Button {
                    onWordSelected(word, "history")
                } label: {
                    wordCell(word)
                }
                .listRowBackground(Color.appBackground)
            }
            .onDelete { viewModel.deleteWord(at: $0) }
        }
        .listStyle(.plain)
        .modifier(ListBackgroundModifier())
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
                .listRowBackground(Color.appBackground)
            }
            .listStyle(.plain)
            .modifier(ListBackgroundModifier())
        }
    }

    // MARK: Belarusian character row

    private var belarusianKeyboardRow: some View {
        HStack(spacing: 0) {
            ForEach(Self.rusKeyboardChars, id: \.self) { keyboardKey($0, tint: .secondary) }
            Spacer()
            ForEach(Self.belKeyboardChars, id: \.self) { keyboardKey($0, tint: .accentColor) }
        }
        .padding(.horizontal, 6)
        .frame(height: 52)
        .padding(.bottom, 6)
    }

    private var buttonBorderShape: ButtonBorderShape {
        if #available(iOS 17, *) { return .circle }
        return .roundedRectangle
    }

    @ViewBuilder
    private func keyboardKey(_ char: String, tint: Color) -> some View {
        let button = Button(action: { viewModel.searchText += char }) {
            Text(char)
                .font(.system(size: 17))
                .frame(width: 24, height: 24)
        }
        .buttonBorderShape(buttonBorderShape)
        .tint(tint)

        if #available(iOS 26.0, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.borderedProminent)
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

struct SKHistoryView: View {
    @ObservedObject var viewModel: SKHistoryViewModel
    var onWordSelected: (SKWord, String) -> Void = { _, _ in }

    var body: some View {
        SKHistoryContentView(viewModel: viewModel, onWordSelected: onWordSelected)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: SKLocalization.searchbarSearchWords
            )
    }
}
