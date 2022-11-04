//
//  SKAppstoreReviewController.swift
//  Skarnik
//
//  Created by Logout on 24.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import StoreKit
import UIKit

class SKAppstoreReviewController: Any {
    
    static let wordsCompletedCountKey = "SKAppstoreReviewController.wordsCompletedCount"
    static let lastVersionPromptedKey = "SKAppstoreReviewController.lastVersionPrompted"
    static let maxCount = 5
    
    class func requestReview() {
        
        let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: self.lastVersionPromptedKey) ?? ""
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary.") }

        if currentVersion == lastVersionPromptedForReview {
            return
        }
        
        let count = 1 + UserDefaults.standard.integer(forKey: self.wordsCompletedCountKey)
        UserDefaults.standard.set(count, forKey: self.wordsCompletedCountKey)
        UserDefaults.standard.synchronize()

         // Verify the user completes the process several times and doesn’t receive a prompt for this app version.
        if count >= self.maxCount {
            Task {
                // Delay for two seconds to avoid interrupting the person using the app.
                try? await Task.sleep(seconds: 5.0)

                if await UIApplication.shared.applicationState != .active {
                    return
                }

                if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
#if targetEnvironment(macCatalyst)
                    if #available(macCatalyst 14.0, *) {
                        SKStoreReviewController.requestReview(in: windowScene)
                    } else {
                        SKStoreReviewController.requestReview()
                    }
#else
                    if #available(iOS 14.0, *) {
                        await SKStoreReviewController.requestReview(in: windowScene)
                    } else {
                        SKStoreReviewController.requestReview()
                    }
#endif
                    UserDefaults.standard.set(0, forKey: self.wordsCompletedCountKey)
                    UserDefaults.standard.set(currentVersion, forKey: self.lastVersionPromptedKey)
                    UserDefaults.standard.synchronize()
               }
            }
        }
    }
}
