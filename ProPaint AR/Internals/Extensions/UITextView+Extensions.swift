//
//  UITextView+Extensions.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 26/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

extension UITextView {
    func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        for (hyperLink, urlString) in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link,
                                                value: urlString,
                                                range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle,
                                                value: style,
                                                range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font,
                                                value: UIFont.systemFont(ofSize: 14),
                                                range: fullRange)
        }
        
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        self.attributedText = attributedOriginalText
    }
}
