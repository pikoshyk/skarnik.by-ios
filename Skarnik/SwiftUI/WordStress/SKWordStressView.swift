//
//  SKWordStressView.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI

struct SKWordStressView: View {
    @ObservedObject var viewModel: SKWordStressViewModel
    var body: some View {
        ZStack {
            self.background
            Group {
                if self.viewModel.isLoading {
                    if #available(iOS 14.0, *) {
                        ProgressView()
                    } else {
                        Text(self.viewModel.presentLoadingLabel)
                            .font(.body)
                    }
                } else {
                    if let error = self.viewModel.error {
                        Text(error)
                            .font(.body)
                            .frame(maxWidth: 300)
                            .padding()
                    } else {
                        self.list
                    }
                }
            }
        }
        .combinedNavigationTitle(self.viewModel.presentTitle)
    }
    
    var background: some View {
        Group {
            if #available(iOS 15.0, *) {
                Color(uiColor: UIColor.secondarySystemBackground)
                    .ignoresSafeArea()
            } else {
                Color(UIColor.secondarySystemBackground)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    var list: some View {
        List {
            ForEach(self.viewModel.table) { row in
                self.row(row)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    func row(_ element: SKStarnikParserByController.StarnikTableElement) -> some View {
        HStack(content: {
            SKHtmlTextView(html: element.titleHtml)
                .frame(minWidth: 0, maxWidth: .infinity)

            SKHtmlTextView(html: element.contentHtml)
                .frame(minWidth: 0, maxWidth: .infinity)

        })
        .combinedVerticalPadding()
    }
}
