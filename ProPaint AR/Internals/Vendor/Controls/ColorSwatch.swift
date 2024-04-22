//
//  ColorSwatch.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/12/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ColorSwatch: RoundedButton {
    @IBInspectable var outlineWidth: CGFloat = 4 {
        didSet {
            layer.borderWidth = outlineWidth
        }
    }
    
    @IBInspectable var outlineSelectedColor: UIColor = .white {
        didSet {
            updateOutlineColor()
        }
    }
    
    @IBInspectable var outlineDeselectedColor: UIColor = .lightGray {
        didSet {
            updateOutlineColor()
        }
    }
    
    @IBInspectable var isActive: Bool = false {
        didSet {
            updateOutlineColor()
        }
    }
    
    private func updateOutlineColor() {
        if isActive {
            layer.borderColor = outlineSelectedColor.cgColor
        } else {
            layer.borderColor = outlineDeselectedColor.cgColor
        }
    }
}
