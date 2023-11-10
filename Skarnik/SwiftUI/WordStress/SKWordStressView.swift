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
        Group {
            if self.viewModel.isLoading {
                if #available(iOS 14.0, *) {
                    ProgressView()
                } else {
                    Text("Пачакайце, калі-ласка")
                }
            } else {
                if let error = viewModel.error {
                    Text(error)
                } else {
                    self.list
                }
            }
        }
    }
    
    var list: some View {
        List {
            ForEach(viewModel.table) { row in
                self.row(row)
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    func row(_ element: SKStarnikParserByController.StarnikTableElement) -> some View {
        HStack(content: {
            SKHtmlTextView(element.titleHtml)
                .frame(minWidth: 0, maxWidth: .infinity)
            SKHtmlTextView(element.contentHtml)
                .frame(minWidth: 0, maxWidth: .infinity)
        })
    }
}

#Preview {
    SKWordStressView(viewModel: SKWordStressViewModel())
}
