//
//  ProviderCodeTextField.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 26/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

protocol ProviderCodeDelegate: AnyObject {
    func textFieldDidChange(_ textField: UITextField)
}

class ProviderCodeTextField: UITextField {
    weak var codeDelegate: ProviderCodeDelegate?

    var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1.5
        }
    }

    var isError = false {
        didSet {
            if isError {
                layer.borderColor = UIColor.red.cgColor
                layer.borderWidth = 1.5
            } else {
                layer.borderColor = borderColor.cgColor
                layer.borderWidth = 1.5
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTextField()
        configureKeyboard()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
    }
}

extension Optional where Wrapped == ProviderCodeTextField {
    var isEmpty: Bool {
        guard let self = self,
              let isEmpty = self.text?.isEmpty else {
            return false
        }
        return isEmpty
    }
}

extension ProviderCodeTextField {
    private func configureTextField() {
        let placeholderText = NSAttributedString(
            string: "-",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(white: 0.75, alpha: 0.5)]
        )
        
        attributedPlaceholder = placeholderText
        keyboardType = .numberPad
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        delegate = self
    }

    private func configureKeyboard() {
        let toolbar = UIToolbar()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .plain,
                                         target: self,
                                         action: #selector(textFieldEndEditing))
        doneButton.tintColor = .black
        toolbar.setItems([spacer, doneButton], animated: false)
//        inputAccessoryView = toolbar
    }

    @objc func textFieldEndEditing(_ textField: UITextField) {
        endEditing(true)
    }
}

extension ProviderCodeTextField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let value = textField.move(to: textField, string: string)
        if value || !(textField.text?.isEmpty ?? false) {
            borderColor = .white
        } else {
            borderColor = .clear
        }
        codeDelegate?.textFieldDidChange(textField)
        return value
    }
}
