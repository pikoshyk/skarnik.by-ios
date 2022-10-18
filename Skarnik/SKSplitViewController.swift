//
//  SKSplitViewController.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import UIKit

class SKSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
}

extension SKSplitViewController: UISplitViewControllerDelegate {

    @available(iOS 14.0, *)
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        return true
    }
}
