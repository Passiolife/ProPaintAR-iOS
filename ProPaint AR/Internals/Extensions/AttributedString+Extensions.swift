//
//  AttributedString+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    func replaceFont(with font: UIFont) {
        beginEditing()
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { value, range, _ in
            if let f = value as? UIFont,
               let ufd = f.fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(f.fontDescriptor.symbolicTraits) {
                let newFont = UIFont(descriptor: ufd, size: f.pointSize)
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
            }
        }
        endEditing()
    }
    
    func appendImage(image: UIImage?) {
        let image1Attachment = NSTextAttachment()
        image1Attachment.bounds = CGRect(x: 0,
                                         y: 0,
                                         width: 21,
                                         height: 21)
        image1Attachment.image = image
        
        let image1String = NSAttributedString(attachment: image1Attachment)
        
        append(image1String)
    }
}

extension NSAttributedString {
    var font: UIFont? {
        var enumeratedFont: UIFont?
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { value, _, _ in
            if let font = value as? UIFont {
                enumeratedFont = font
            }
        }
        return enumeratedFont
    }
    
    convenience init(image: UIImage?) {
        let image1Attachment = NSTextAttachment()
        image1Attachment.bounds = CGRect(x: 0,
                                         y: 0,
                                         width: 21,
                                         height: 21)
        image1Attachment.image = image
        
        self.init(attributedString: NSAttributedString(attachment: image1Attachment))
    }
    
    func appending(string: NSAttributedString) -> NSAttributedString {
        let value = NSMutableAttributedString(attributedString: self)
        value.append(string)
        return value
    }
}
