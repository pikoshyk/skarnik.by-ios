//
//  Task+Skarnik.swift
//  Skarnik
//
//  Created by Logout on 26.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

