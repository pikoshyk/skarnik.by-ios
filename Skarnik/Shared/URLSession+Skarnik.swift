//
//  URLSession.swift
//  Skarnik
//
//  Created by Logout on 4.11.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension URLSession {
    
    class private func skarnikDownload(request: URLRequest) async throws -> Data? {
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 500
        if 200..<300 ~= statusCode {
            return data
        }
        return nil
    }

    class func skarnikDownload(urlStr: String) async -> Data? {
        guard let url = URL(string: urlStr) else { return nil }
        return try? await skarnikDownload(request: URLRequest(url: url))
    }

    class func skarnikDownload(urlStr: String, headers: [String: String]) async -> Data? {
        guard let url = URL(string: urlStr) else { return nil }
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try? await skarnikDownload(request: request)
    }}
