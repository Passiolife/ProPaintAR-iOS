//
//  ColorTheme.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/3/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public protocol ColorTheme {
    associatedtype ColorValue
    static func colorFor(hex: String, alpha: CGFloat) -> ColorValue
    static func colorFor(name: String) -> ColorValue?
    static func colorFor(color: UIColor) -> ColorValue
}

extension UIColor: ColorTheme {
    public static func colorFor(hex: String, alpha: CGFloat) -> UIColor {
        UIColor(hex: hex).withAlphaComponent(alpha)
    }
    
    public static func colorFor(name: String) -> UIColor? {
        UIColor(named: name)
    }
    
    public static func colorFor(color: UIColor) -> UIColor {
        color
    }
}

@available(iOS 13.0, *)
extension Color: ColorTheme {
    public static func colorFor(hex: String, alpha: CGFloat) -> Color {
        Color(UIColor.colorFor(hex: hex, alpha: alpha))
    }
    
    public static func colorFor(name: String) -> Color? {
        guard let uiColor = UIColor.colorFor(name: name)
        else { return nil }
        return Color(uiColor)
    }
    
    public static func colorFor(color: UIColor) -> Color {
        Color(color)
    }
}

extension ColorTheme {
    static var button: ColorValue {
        colorFor(name: "button") ?? colorFor(color: .init(white: 0.86, alpha: 1))
    }
    static var buttonText: ColorValue {
        colorFor(name: "buttonText") ?? colorFor(color: .black)
    }
    static var frameBackground: ColorValue {
        colorFor(name: "frameBackground") ?? colorFor(color: .init(white: 0, alpha: 0.53))
    }
    static var icon: ColorValue {
        colorFor(name: "icon") ?? colorFor(color: .white)
    }
    static var iconBackground: ColorValue {
        colorFor(name: "iconBackground") ?? colorFor(color: .init(white: 0, alpha: 0.5))
    }
    static var overlayBackground: ColorValue {
        colorFor(name: "overlayBackground") ?? colorFor(color: .init(white: 0, alpha: 0.8))
    }
    static var subframeBackground: ColorValue {
        colorFor(name: "subframeBackground") ?? colorFor(color: .init(white: 0, alpha: 0.44))
    }
    static var text: ColorValue {
        colorFor(name: "text") ?? colorFor(color: .white)
    }
}
