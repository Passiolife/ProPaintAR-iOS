//
//  FontTheme.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

enum FontFamily: String {
    case HelveticaNeue
    case Montserrat
    case SFProText
}

enum FontWeight: String {
    case Regular
    case Medium
    case Semibold
    case Bold
    
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .Regular:
            return .regular
            
        case .Medium:
            return .medium
            
        case .Semibold:
            return .semibold
            
        case .Bold:
            return .bold
        }
    }
}

enum FontTheme {
    static func font(family: FontFamily, weight: FontWeight, size: CGFloat) -> UIFont {
        let font = UIFont(name: "\(family.rawValue)-\(weight.rawValue)", size: size)
        let alternate = UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        return font ?? alternate
    }
}
