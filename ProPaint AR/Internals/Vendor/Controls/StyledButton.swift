//
//  StyledButton.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/22/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class StyledButton: UIButton {
    @IBInspectable
    var outlineWidth: CGFloat = 0 {
       didSet {
           self.layer.borderWidth = outlineWidth
           self.layer.cornerRadius = frame.height / 2
           if outlineWidth > 0 {
               self.backgroundColor = .clear
           }
       }
    }
    
    @IBInspectable
    var outlineColor: UIColor = .blue {
       didSet {
           self.layer.borderColor = outlineColor.cgColor
       }
    }
    
    func fixTextAlignment() {
        contentVerticalAlignment = .fill
        contentMode = .center
        imageView?.contentMode = .scaleAspectFit
    }
}
