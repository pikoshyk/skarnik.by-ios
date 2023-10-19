//
//  URLSession.swift
//  Skarnik
//
//  Created by Logout on 4.11.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension URLSession {
    
    class private func skarnikDownload(url: URL) async throws -> Data?  {
        let urlRequest = URLRequest(url: url)
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 500
        if 200..<300 ~= statusCode {
            return data
        }
        return nil
    }
    
    class func skarnikDownload(urlStr: String) async -> Data?  {
        
        guard let url = URL(string: urlStr) else {
            return nil
        }

        return try? await skarnikDownload(url: url)
    }}
