//
//  NSAttributedString+Skarnik.swift
//  Skarnik
//
//  Created by Logout on 4.11.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension NSAttributedString {
    class func string(htmlData: Data ) throws -> NSAttributedString? {
#if targetEnvironment(macCatalyst)
        let encoding = String.Encoding.utf8.rawValue
#elseif os(iOS)
        let encoding = NSUTF8StringEncoding
#endif
        return try NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: encoding ], documentAttributes: nil)
    }
}
