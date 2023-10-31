//
//  SKSwiftUiViewController.swift
//  Skarnik
//
//  Created by Logout on 1.11.23.
//  Copyright © 2023 Skarnik. All rights reserved.
//

import SwiftUI
import UIKit

class SKSwiftUiViewController <T: View>: UIViewController {
    private let contentView: UIHostingController<T>
    
    init(_ contentView: T) {
        self.contentView = UIHostingController(rootView: contentView)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(self.contentView)
        self.view.backgroundColor = .clear
        self.view.addSubview(self.contentView.view)
        self.contentView.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.contentView.view.bottomAnchor.constraint (equalTo: view.bottomAnchor).isActive = true
        self.contentView.view.leftAnchor.constraint (equalTo: view.leftAnchor).isActive = true
        self.contentView.view.rightAnchor.constraint (equalTo: view.rightAnchor).isActive = true
    }
    
    
}
