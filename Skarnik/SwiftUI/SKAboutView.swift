//
//  SKAboutView.swift
//  Skarnik
//
//  Created by Aleh Mazok on 04.04.26.
//  Copyright © 2026 Skarnik. All rights reserved.
//

import UIKit
import SwiftUI

struct SKAboutView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                Text(SKLocalization.aboutDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(UIColor.secondaryLabel))

                Divider()

                creditsSection

                Divider()

                Text((try? AttributedString(markdown: SKLocalization.aboutSupport)) ?? AttributedString(SKLocalization.aboutSupport))
                    .font(.system(size: 15))
                    .foregroundStyle(Color(UIColor.secondaryLabel))
            }
            .padding()
        }
    }

    private var creditsSection: some View {
        VStack(spacing: 16) {
            creditRow(
                title: SKLocalization.aboutSubscriptionCreator,
                handles: ["skarnikby"]
            )
            creditRow(
                title: SKLocalization.aboutSubscriptionDeveloper,
                handles: ["pikoshyk", "alehm666"]
            )
            creditRow(
                title: SKLocalization.aboutSubscriptionDesigner,
                handles: ["AlenaBakanouska"]
            )
        }
    }

    private func creditRow(title: String, handles: [String]) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(handles, id: \.self) { handle in
                    Button {
                        guard let url = URL(string: "https://x.com/\(handle)") else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Label {
                            Text("@\(handle)")
                                .frame(maxWidth: .infinity)
                        } icon: {
                            if UIImage(named: "x-icon") != nil {
                                Image("x-icon")
                            } else {
                                Image(systemName: "link")
                            }
                        }
                        .lineLimit(1)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(UIColor.label))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - UIKit host

class SKAboutViewController: UIHostingController<SKAboutView> {

    init() {
        super.init(rootView: SKAboutView())
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: SKAboutView())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Skarnik"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: SKLocalization.vocabulariesAdvancedSearch,
            style: .plain,
            target: self,
            action: #selector(openStarnikBy)
        )
    }

    @objc private func openStarnikBy() {
        guard let url = URL(string: "https://starnik.by") else { return }
        SKAnalyticsManager.logStarnikByOpened()
        UIApplication.shared.open(url)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        SKAboutView()
    }
}
#endif

