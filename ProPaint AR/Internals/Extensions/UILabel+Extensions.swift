//
//  UILabel+Extensions.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 9/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func setLineHeight(lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.lineHeightMultiple = lineHeight
        paragraphStyle.alignment = self.textAlignment

        let attrString = NSMutableAttributedString()
        if let attributedText = attributedText {
            attrString.append(attributedText)
        } else {
            if let text = text {
                attrString.append(NSMutableAttributedString(string: text))
            }
            if let font = font {
                attrString.addAttribute(NSAttributedString.Key.font,
                                        value: font,
                                        range: NSRange(location: 0, length: attrString.length))
            }
        }
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                value: paragraphStyle,
                                range: NSRange(location: 0, length: attrString.length))
        self.attributedText = attrString
    }
    
    func addShadow(
        color: UIColor,
        radius: CGFloat,
        opacity: Float
    ) {
        self.layer.masksToBounds = false
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}
