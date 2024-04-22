//
//  Array+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/14/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension Array where Element == UIColor {
    var equatableString: String {
        map({ $0.toHexString() }).joined(separator: ",")
    }
    
    var average: UIColor? {
        guard let first = self.first
        else { return nil }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        for color in self.enumerated() {
            let values = color.element.rgbaValues
            r += values.red
            g += values.green
            b += values.green
        }
        r /= CGFloat(self.count)
        g /= CGFloat(self.count)
        b /= CGFloat(self.count)
        return UIColor(red: r, green: g, blue: b, alpha: first.rgbaValues.alpha)
    }
}
