//
//  SKWordStressViewModel.swift
//  Skarnik
//
//  Created by Logout on 10.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import Foundation
import Combine

class SKWordStressViewModel: ObservableObject {
    @Published var table: [SKStarnikParserByController.StarnikTableElement] = []
    @Published var error: String?
    @Published var isLoading: Bool
    
    init() {
        self.isLoading = true
        self.fetchWord(48920)
    }
    
    func fetchWord(_ starnikWordId: Int) {
        Task {
            guard let content = await SKStarnikParserByController.wordContent(url: "https://starnik.by/pravapis/\(starnikWordId)") else {
                DispatchQueue.main.async {
                    self.error = "Нешта пайшло не так, мо праблемы з інтэрнэтам ці серверам."
                    self.isLoading = false
                }
                return
            }
            DispatchQueue.main.async {
                self.isLoading = false
                self.table = content
            }
        }

    }
}
