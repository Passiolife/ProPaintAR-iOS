//
//  UIColor+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let stringRepresentation = hex.replacingOccurrences(of: "#", with: "")
        
        guard !hex.isEmpty,
              let hexInt = Int(stringRepresentation, radix: 16) else {
            self.init(white: 0, alpha: alpha)
            return
        }
        
        let red = CGFloat((hexInt >> 16) & 0xFF) / 255.0
        let green = CGFloat((hexInt >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hexInt & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    typealias HSB = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)?

    var hsbValues: HSB {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        let getHueValue = getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        guard getHueValue else { return nil }
        return (hue: hue, saturation: saturation, brightness: brightness)
    }
    
    var isLightColor: Bool {
        guard let hsb = hsbValues else { return false }
        return hsb.brightness > 0.75 && (hsb.saturation < 0.5 || (hsb.hue >= 0.05 && hsb.hue <= 0.55))
    }
    
    var inverseColor: UIColor {
        var alpha: CGFloat = 1.0

        var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: 1.0 - red,
                           green: 1.0 - green,
                           blue: 1.0 - blue,
                           alpha: alpha)
        }

        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0
        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: 1.0 - hue,
                           saturation: 1.0 - saturation,
                           brightness: 1.0 - brightness,
                           alpha: alpha)
        }

        var white: CGFloat = 0.0
        if self.getWhite(&white, alpha: &alpha) {
            return UIColor(white: 1.0 - white, alpha: alpha)
        }

        return self
    }
}

extension UIColor {
    private static func color(name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            return .black
        }
        return color
    }
}
