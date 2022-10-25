//
//  Array+Skarnik.swift
//  Skarnik
//
//  Created by Logout on 26.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
