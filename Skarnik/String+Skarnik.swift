//
//  String+Skarnik.swift
//  Skarnik
//
//  Created by Logout on 18.11.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension String {
    func regexSub(pattern: String, template: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSMakeRange(0, self.count)
        let subString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
        return subString
    }
}
