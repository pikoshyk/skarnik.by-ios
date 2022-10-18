//
//  SKAdditionalKeyboardView.swift
//  Skarnik
//
//  Created by Logout on 9.10.22.
//

import UIKit

protocol SKAdditionalKeyboardViewDelegate {
    func onAdditionalKeyboardCharPressed(char: String)
}

class SKAdditionalKeyboardView: UIView {
    
    var delegate: SKAdditionalKeyboardViewDelegate?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func onButton(_ button: UIButton) {
        let keyIndex = button.tag
        var char: String?
        switch keyIndex {
        case 1: char = "‘"
        case 2: char = "ў"
        case 3: char = "і"
        case 4: char = "ъ"
        case 5: char = "щ"
        case 6: char = "и"
        default: char = nil
        }
        
        if let delegate = self.delegate, let char = char {
            delegate.onAdditionalKeyboardCharPressed(char: char)
        }
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
