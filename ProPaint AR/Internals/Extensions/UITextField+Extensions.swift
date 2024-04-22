//
//  UITextField+Extensions.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 26/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

extension UITextField {
    func move(to textField: UITextField, string: String) -> Bool {
        if let count = textField.text?.count,
           count < 2,
           string.count == 1 {
            let nextTag = textField.tag + 1
            let nextResponder = textField.superview?.viewWithTag(nextTag)
            textField.text = string
            if !textField.canBecomeFirstResponder {
                textField.resignFirstResponder()
            } else if let nextResponder = nextResponder {
                nextResponder.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
            return true
        } else if let count = textField.text?.count,
                  count == 1,
                  string.isEmpty {
            let previousTag = textField.tag - 1
            textField.text = ""
            let previousResponder = textField.superview?.viewWithTag(previousTag)
            if let previousResponder = previousResponder,
               previousResponder.canBecomeFirstResponder {
                previousResponder.becomeFirstResponder()
            }
            return false
        } else {
            textField.text = string
            return false
        }
    }
}
