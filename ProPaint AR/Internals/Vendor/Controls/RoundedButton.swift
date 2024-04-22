//
//  RoundedButton.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class RoundedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 10 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    func fixTextAlignment() {
        contentVerticalAlignment = .fill
        contentMode = .center
        imageView?.contentMode = .scaleAspectFit
    }
}
