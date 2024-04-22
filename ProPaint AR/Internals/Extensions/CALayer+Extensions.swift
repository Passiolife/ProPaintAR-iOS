//
//  CALayer+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/22/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    override open func setValue(_ value: Any?, forKey key: String) {
        guard key == "borderColor",
              let color = value as? UIColor
        else {
            super.setValue(value, forKey: key)
            return
        }
        
        self.borderColor = color.cgColor
    }
}
