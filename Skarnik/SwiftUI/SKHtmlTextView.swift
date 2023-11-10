//
//  SKHtmlTextView.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import UIKit
import SwiftUI

struct SKHtmlTextView: View {
    var html: String
    
    @MainActor @State private var height: CGFloat = .zero
    
    var body: some View {
        SKHtmlLabelView(html: html, dynamicHeight: $height)
            .combinedBackground(.clear)
            .frame(minHeight: height)
            .combinedBackground(.clear)

    }
}

struct SKHtmlLabelView: UIViewRepresentable {
    
    let html: String
    @Binding var dynamicHeight: CGFloat
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let colorHex = UIColor.label.webHexString()
        let html = "<html><body style=\"font-size: \(fontSize); color:\(colorHex); font-family: -apple-system; line-height: 150%;\">" + self.html + "</body></html>"
        let data = html.data(using: .utf8) ?? Data()
        let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)

        DispatchQueue.main.async {
            uiView.attributedText = attributedString
            self.dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        }
    }
}
