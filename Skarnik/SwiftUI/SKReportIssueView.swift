//
//  SKReportIssueView.swift
//  Skarnik
//

import SwiftUI

@available(iOS 14.0, *)
struct SKReportIssueView: View {

    enum IssueType: String, CaseIterable, Identifiable {
        case translationError
        case spellingError
        case other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .translationError: return SKLocalization.reportIssueTypeTranslation
            case .spellingError:    return SKLocalization.reportIssueTypeSpelling
            case .other:            return SKLocalization.reportIssueTypeOther
            }
        }
    }

    let word: SKWord?
    let translationUrl: String?

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedIssue: IssueType = .translationError
    @State private var details: String = ""

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                formContent
                    .scrollContentBackground(.hidden)
            }
        } else {
            NavigationView {
                formContent
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section {
                Picker(SKLocalization.reportIssueTitle, selection: $selectedIssue) {
                    ForEach(IssueType.allCases) { issue in
                        Text(issue.title).tag(issue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section(header: Text(SKLocalization.reportIssueDetailsPlaceholder)) {
                if #available(iOS 16.0, *) {
                    TextEditor(text: $details)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80, maxHeight: 160)
                } else {
                    TextEditor(text: $details)
                        .frame(minHeight: 80, maxHeight: 160)
                }
            }
        }
        .navigationTitle(SKLocalization.reportIssueTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: sendReport) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                }
            }
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

    private func sendReport() {
        let wordName = word?.word ?? ""
        let subject = "Памылка ў Скарніку: \(wordName)"
        let body = [
            "Слова: \(wordName)",
            "Спасылка: \(translationUrl ?? "—")",
            "Тып праблемы: \(selectedIssue.title)",
            details.isEmpty ? nil : "Падрабязнасці: \(details)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        let query = "subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:skarnikapp@gmail.com?\(query)") {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}
