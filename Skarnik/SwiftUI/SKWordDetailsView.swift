//
//  SKWordDetailsView.swift
//  Skarnik
//

import SwiftUI
import UIKit
import Combine

// MARK: - UITextView representable

struct SKAttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString?
    let onLinkTap: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkTap: onLinkTap)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 17)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.onLinkTap = onLinkTap
        uiView.attributedText = attributedText
        uiView.invalidateIntrinsicContentSize()
    }

    @available(iOS 16, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.frame.width
        guard width > 0 else { return nil }
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var onLinkTap: (URL) -> Void

        init(onLinkTap: @escaping (URL) -> Void) {
            self.onLinkTap = onLinkTap
        }

        func textView(_ textView: UITextView,
                      shouldInteractWith URL: URL,
                      in characterRange: NSRange,
                      interaction: UITextItemInteraction) -> Bool {
            onLinkTap(URL)
            return false
        }
    }
}

// MARK: - Translation content view (handles async attributed string loading)

private struct SKWordDetailsTranslationView: View {
    let translation: SKSkarnikTranslation
    let onLinkTap: (URL) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var attributedText: NSAttributedString?

    var body: some View {
        SKAttributedTextView(attributedText: attributedText, onLinkTap: onLinkTap)
            .task(id: "\(translation.url)-\(colorScheme)") {
                translation.attributedString { text in
                    attributedText = text
                }
            }
    }
}

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Main view

struct SKWordDetailsView: View {
    @ObservedObject var viewModel: SKWordDetailsViewModel
    var onSpellingWord: (String) -> Void = { _ in }
    var onReport: () -> Void = {}

    @State private var toastMessage: String?
    @State private var showShareSheet = false

    private var displayTitle: String {
        if case .success(let translation) = viewModel.state, let stress = translation.stress {
            return "«\u{200E}\(stress)»"
        }
        return viewModel.navigationTitle ?? ""
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    urlVocabularyRow
                    contentView
                }
                .padding(.horizontal, 15)
            }

            if let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(radius: 5)
                        )
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.spellingWords.isEmpty {
                    spellingControl
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    if let translation = viewModel.translation {
                        SKAnalyticsManager.logShareClicked(word: translation.word, url: translation.sharingUrl)
                    }
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.translation == nil)
                Spacer()
                // TODO: re-enable report button when ready
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let urlStr = viewModel.translation?.sharingUrl, let url = URL(string: urlStr) {
                ShareSheet(url: url)
            }
        }
        .onReceive(viewModel.effectSubject) { effect in
            handleEffect(effect)
        }
    }

    // MARK: URL / vocabulary row

    @ViewBuilder
    private var urlVocabularyRow: some View {
        VStack(spacing: 2) {
            Text(viewModel.vocabularySubtitle ?? " ")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            if case .success(let translation) = viewModel.state {
                Button(action: { openUrl(translation.sharingUrl) }) {
                    HStack(spacing: 3) {
                        Text(translation.sharingUrl)
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                        Image("external-link-icon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .frame(width: 10.5, height: 10.5)
                    }
                }
            } else {
                Text(" ").font(.system(size: 10.5))
            }
        }
        .frame(height: 50)
    }

    // MARK: Content

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            HStack {
                ProgressView()
                Spacer()
            }
            .padding(.top, 8)
        case .success(let translation):
            SKWordDetailsTranslationView(
                translation: translation,
                onLinkTap: { url in viewModel.handleUrl(url.absoluteString) }
            )
        case .error(let message):
            ScrollView {
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: Spelling toolbar control

    @ViewBuilder
    private var spellingControl: some View {
        let words = viewModel.spellingWords
        if words.count == 1 {
            Button(action: { onSpellingWord(words[0]) }) {
                Text(SKLocalization.wordDetailsSpelling)
                    .foregroundColor(Color.accentColor)
            }
        } else {
            Menu {
                ForEach(words, id: \.self) { word in
                    Button(word) { onSpellingWord(word) }
                }
            } label: {
                Text(SKLocalization.wordDetailsSpelling)
                    .foregroundColor(Color.accentColor)
            }
        }
    }

    // MARK: Helpers

    private func openUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func handleEffect(_ effect: SKWordDetailsEffect) {
        switch effect {
        case .redirection(let originalWord):
            showToast("Перанакіравана з «‎\(originalWord)»")
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Previews

#if DEBUG
private struct MockTranslationSource: SKTranslationSource {
    let translation: SKSkarnikTranslation?

    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        translation
    }
}

private struct ErrorTranslationSource: SKTranslationSource {
    func wordTranslation(_ word: SKWord) async throws -> SKSkarnikTranslation? {
        throw SKSkarnikError.networkError
    }
}

private let previewWord = SKWord(word_id: 1, word: "слова", lang_id: .bel_definition)

private let previewTranslation = SKSkarnikTranslation(
    word: previewWord,
    url: "https://skarnik.app/r/rusbel/1",
    html: """
    <p>
     <strong>
      <span style="color: #0000a0;">
       ка́ра,
      </span>
     </strong>
     <span style="color: #a52a2a;">
      -ы, жаночы род
     </span>
     <br/>
     Суровае пакаранне, спагнанне за правіннасць.
     <span style="color: #5f5f5f;">
      Панесці кару. Адбываць кару. ▪ У заключэнне пракурор патрабаваў вышэйшай меры кары, што азначана ў артыкулах, па якіх адбываўся суд.
     </span>
     <em>
      <span style="color: #151b54;">
       Колас.
      </span>
     </em>
     <span style="color: #5f5f5f;">
      Ні бацькі, ні дзяўчат гестапаўцам злавіць не ўдалося: іх папярэдзілі сувязныя. Увесь цяжар кары лёг на кволыя матчыны плечы.
     </span>
     <em>
      <span style="color: #151b54;">
       Брыль.
      </span>
     </em>
     <br/>
     <strong>
      <span style="color: #0000a0;">
       кара́,
      </span>
     </strong>
     <span style="color: #a52a2a;">
      -ы́, жаночы род
     </span>
     <br/>
     <strong>
      1.
     </strong>
     Паверхневая частка ствала, галін і кораня дрэвавых раслін, якая звычайна лёгка аддзяляецца.
     <span style="color: #5f5f5f;">
      Лазовая кара. Здымаць кару. ▪ Сонца заходзіла, распырскваючы чырвона-медзяныя пырскі па траве, па белай кары маладых бярозак.
     </span>
     <em>
      <span style="color: #151b54;">
       Мурашка.
      </span>
     </em>
     <span style="color: #5f5f5f;">
      Доўгімі і вострымі кіпцюрамі мядзведзіца здзірала кару з дрэў.
     </span>
     <em>
      <span style="color: #151b54;">
       В. Вольскі.
      </span>
     </em>
     <br/>
     <strong>
      2.
     </strong>
     чаго або якая. Верхні цвёрды слой на чым-н.
     <span style="color: #5f5f5f;">
      У лагчынах блішчэлі ахопленыя ледзяной карой лужыны.
     </span>
     <em>
      <span style="color: #151b54;">
       Бядуля.
      </span>
     </em>
     <span style="color: #5f5f5f;">
      Конь цвёрда ступаў, прабіваючы слабую кару гразі.
     </span>
     <em>
      <span style="color: #151b54;">
       Гартны.
      </span>
     </em>
     <span style="color: #cc33ff;">
      <strong>
       //
      </strong>
     </span>
     пераноснае значэнне; чаго. Аб чым-н. знешнім, паверхневым, за якім хаваецца якая-н. сутнасць.
     <span style="color: #5f5f5f;">
      Дрымота і здранцвеласць цела туманіла нам галовы і зацягвала сэрца карою абыякавасці.
     </span>
     <em>
      <span style="color: #151b54;">
       Чорны.
      </span>
     </em>
     <br/>
     •••
     <br/>
     <strong>
      <span style="color: #5f5f5f;">
       <span style="color: #4863a0;">
        Зямная кара
       </span>
      </span>
     </strong>
     — верхняя цвёрдая абалонка Зямлі.
     <br/>
     <strong>
      <span style="color: #5f5f5f;">
       <span style="color: #4863a0;">
        Кара вялікіх паўшар'яў галаўнога мозгу
       </span>
      </span>
     </strong>
     ;
     <strong>
      <span style="color: #5f5f5f;">
       <span style="color: #4863a0;">
        кара галаўнога мозгу
       </span>
      </span>
     </strong>
     — паверхневы слой галаўнога мозгу ў вышэйшых пазваночных жывёл і чалавека.
     <br/>
     <strong>
      <span style="color: #5f5f5f;">
       <span style="color: #4863a0;">
        Абрасці карою
       </span>
      </span>
     </strong>
     глядзі абрасці.
    </p>
    """,
//    stress: "сло́ва",
    stress: "добразычлівасць",
    sourceName: "mock"
)
#Preview("Loading") {
    NavigationView {
        NavigationLink(isActive: .constant(true)) {
            SKWordDetailsView(viewModel: SKWordDetailsViewModel())
        } label: { EmptyView() }
    }
}

#Preview("Success") {
    let vm = SKWordDetailsViewModel(
        translationSource: MockTranslationSource(translation: previewTranslation)
    )
    return NavigationView {
        NavigationLink(isActive: .constant(true)) {
            SKWordDetailsView(viewModel: vm)
                .onAppear { vm.updateWord(previewWord) }
        } label: { EmptyView() }
    }
}

#Preview("Error") {
    let vm = SKWordDetailsViewModel(translationSource: ErrorTranslationSource())
    return NavigationView {
        NavigationLink(isActive: .constant(true)) {
            SKWordDetailsView(viewModel: vm)
                .onAppear { vm.updateWord(previewWord) }
        } label: { EmptyView() }
    }
}
#endif
