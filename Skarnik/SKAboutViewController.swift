//
//  SKAboutViewController.swift
//  Skarnik
//
//  Created by Logout on 15.10.22.
//  Copyright © 2022 Skarnik. All rights reserved.
//

import UIKit

class SKAboutViewController: UIViewController {
    
    @IBOutlet var labelSubscriptionCreator: UILabel!
    @IBOutlet var labelSubscriptionDeveloper: UILabel!
    @IBOutlet var labelDescription: UILabel!
    @IBOutlet var textViewSupport: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: SKLocalization.aboutDone, style: .done, target: self, action: #selector(self.onDismiss))

        self.labelSubscriptionCreator.text = SKLocalization.aboutSubscriptionCreator
        self.labelSubscriptionDeveloper.text = SKLocalization.aboutSubscriptionDeveloper
        self.labelDescription.text = SKLocalization.aboutDescription
        self.updateSupportText()
    }
    
    func updateSupportText() {
        let fontSize = 15.0
        let color = UIColor.label.webHexString()
        let text = SKLocalization.aboutSupportHtml
        let html = "<html><body style=\"font-size: \(fontSize); color: \(color); font-family: -apple-system;\">" + text + "</body></html>"
        self.textViewSupport.text = ""
        if let textData = html.data(using: .utf8) {
            DispatchQueue.main.async {
                let attributedString = try? NSAttributedString.string(htmlData: textData)
                self.textViewSupport.attributedText = attributedString
            }
        }
    }
    
    @objc func onDismiss() {
        self.dismiss(animated: true)
    }
    
    func openTwitterAccount(account: String) {
        let urlStr = "https://twitter.com/\(account)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func onCreator() {
        self.openTwitterAccount(account: "skarnikby")
    }
    
    @IBAction func onDeveloper() {
        self.openTwitterAccount(account: "pikoshyk")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
