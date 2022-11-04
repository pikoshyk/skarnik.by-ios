//
//  URLSession.swift
//  Skarnik
//
//  Created by Logout on 4.11.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import Foundation

extension URLSession {
    
    class private func skarnikDownload(url: URL, completeBlock: @escaping (Data?) -> Void )  {

        URLSession.shared.dataTask(with: URLRequest(url: url), completionHandler: { data, urlResponse, error in
            guard let urlResponse = urlResponse as? HTTPURLResponse else {
                completeBlock(nil)
                return
            }
            if urlResponse.statusCode >= 200 && urlResponse.statusCode < 300 {
                completeBlock(data)
            } else {
                completeBlock(nil)
            }
        }).resume()
    }
    
    class func skarnikDownload(urlStr: String) async -> Data?  {
        
        guard let url = URL(string: urlStr) else {
            return nil
        }

        if #available(iOS 13.0, macCatalyst 15.0, *) {
            var data: Data?
            do {
                var retrievedData: Data?
                var response: URLResponse?
                (retrievedData, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if retrievedData?.count ?? 0 > 0 {
                            data = retrievedData
                        }
                    }
                }
            } catch {
            }
            return data
        }
        else {
            return await withCheckedContinuation { continuation in
                skarnikDownload(url: url) { data in
                    continuation.resume(returning: data)
                }
            }
        }
    }}
