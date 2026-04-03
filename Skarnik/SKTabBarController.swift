//
//  SKTabBarController.swift
//  Skarnik
//

import UIKit

class SKTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // History tab
        let historyVC = SKHistoryViewController()
        historyVC.tabBarItem = UITabBarItem(
            title: SKLocalization.tabHistory,
            image: UIImage(systemName: "clock"),
            tag: 0
        )
        let historyNav = UINavigationController(rootViewController: historyVC)

        // Vocabularies tab
        let vocabVC = SKVocabulariesTableViewController()
        vocabVC.tabBarItem = UITabBarItem(
            title: SKLocalization.tabVocabularies,
            image: UIImage(systemName: "text.book.closed"),
            tag: 1
        )
        let vocabNav = UINavigationController(rootViewController: vocabVC)

        // About tab
        let aboutVC = storyboard.instantiateViewController(
            withIdentifier: "SKAboutViewController"
        ) as! SKAboutViewController
        aboutVC.tabBarItem = UITabBarItem(
            title: SKLocalization.tabAbout,
            image: UIImage(systemName: "info.circle"),
            tag: 2
        )
        let aboutNav = UINavigationController(rootViewController: aboutVC)

        viewControllers = [historyNav, vocabNav, aboutNav]
        selectedIndex = 0
    }
}
