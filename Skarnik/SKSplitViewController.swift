//
//  SKSplitViewController.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import UIKit

class SKSplitViewController: UISplitViewController {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        self.preferredDisplayMode = .oneBesideSecondary
        
    }
    
}

// MARK: - Word detail navigation helper

extension UIViewController {
    /// Opens `word` in the word details screen.
    ///
    /// - Collapsed (iPhone): pushes a new `SKWordDetailsViewController` onto the
    ///   current navigation stack, which is the standard list→detail pattern.
    /// - Non-collapsed (iPad): updates the existing secondary column VC in place.
    func showWordInDetail(_ word: SKWord, entryPoint: String) {
        guard let splitVC = view.window?.rootViewController as? SKSplitViewController else { return }

        if splitVC.isCollapsed {
            // iPhone: push a fresh instance onto the visible nav stack.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(
                withIdentifier: "SKWordDetailsViewController"
            ) as? SKWordDetailsViewController else { return }
            vc.hidesBottomBarWhenPushed = true
            vc.entryPoint = entryPoint
            vc.word = word
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // iPad: update the existing secondary column VC and show it.
            let wordDetailsVC: SKWordDetailsViewController
            if #available(iOS 14.0, *),
               let existing = splitVC.viewController(for: .secondary) as? SKWordDetailsViewController {
                wordDetailsVC = existing
            } else if let existing = splitVC.viewControllers.last as? SKWordDetailsViewController {
                wordDetailsVC = existing
            } else {
                return
            }
            wordDetailsVC.entryPoint = entryPoint
            wordDetailsVC.word = word
            splitVC.showDetailViewController(wordDetailsVC, sender: self)
        }
    }
}

extension SKSplitViewController: UISplitViewControllerDelegate {
    
    @available(iOS 14.0, *)
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        return true
    }
}
