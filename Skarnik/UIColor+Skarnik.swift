//
//  UIColor+Skarnik.swift
//  Skarnik
//
//  Created by Logout on 26.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import UIKit

extension UIColor {
    func webHexString() -> String {
        var red:CGFloat = 0
        var blue:CGFloat = 0
        var green:CGFloat = 0
        var alpha:CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb:Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        let hexString = String.localizedStringWithFormat("#%06x", rgb)
        return hexString
     }
}
