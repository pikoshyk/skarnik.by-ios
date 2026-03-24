//
//  SceneDelegate.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        if let url = connectionOptions.urlContexts.first?.url {
            handleDeepLink(url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let word = SceneDelegate.word(from: url) else { return }
        openWord(word)
    }

    static func word(from url: URL) -> SKWord? {
        guard url.scheme == "skarnik",
              url.host == "word",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idStr = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let langStr = components.queryItems?.first(where: { $0.name == "lang" })?.value,
              let wordId = Int64(idStr),
              let langRaw = Int(langStr),
              let lang = ESKVocabularyType(rawValue: langRaw)
        else { return nil }

        return SKVocabularyIndex.shared.word(id: wordId, vocabularyType: lang)
    }

    private func openWord(_ word: SKWord) {
        guard let splitVC = window?.rootViewController as? SKSplitViewController else { return }

        var wordDetailsVC: SKWordDetailsViewController?
        if #available(iOS 14.0, *) {
            wordDetailsVC = splitVC.viewController(for: .secondary) as? SKWordDetailsViewController
        } else {
            let controllers = splitVC.viewControllers
            if controllers.count >= 2 {
                wordDetailsVC = controllers.last as? SKWordDetailsViewController
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                wordDetailsVC = storyboard.instantiateViewController(withIdentifier: "SKWordDetailsViewController") as? SKWordDetailsViewController
            }
        }

        guard let wordDetailsVC = wordDetailsVC else { return }
        wordDetailsVC.entryPoint = "widget"
        wordDetailsVC.word = word
        splitVC.showDetailViewController(wordDetailsVC, sender: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

