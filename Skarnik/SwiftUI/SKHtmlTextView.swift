//
//  SKHtmlTextView.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import UIKit
import SwiftUI

struct SKHtmlTextView: UIViewRepresentable {
    
    private let html: String

    init(_ html: String) {
        self.html = html
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
         let label = UILabel()
         label.numberOfLines = 0
         DispatchQueue.main.async {
             let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
             let colorHex = UIColor.label.webHexString()
             let html = "<html><body style=\"font-size: \(fontSize); color:\(colorHex); font-family: -apple-system; line-height: 150%;\">" + self.html + "</body></html>"
             let data = html.data(using: .utf8) ?? Data()
             if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
                 DispatchQueue.main.async {
                     label.attributedText = attributedString
                 }
             }
         }

         return label
     }
    
    func updateUIView(_ uiView: UILabel, context: Context) {}
}
