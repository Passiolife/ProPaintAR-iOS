//
//  StoreViewController.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 25/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Bugsnag
import UIKit

protocol StoreViewControllerDelegate: AnyObject {
    func showDashboard(_ controller: StoreViewController, storeId: String)
    func showDemoApp(_ controller: StoreViewController)
}

class StoreViewController: UIViewController {
    @IBOutlet weak var storeTextField: UITextField!
    @IBOutlet private weak var oneTextField: ProviderCodeTextField!
    @IBOutlet private weak var secondTextField: ProviderCodeTextField!
    @IBOutlet private weak var thirdTextField: ProviderCodeTextField!
    @IBOutlet private weak var fourthTextField: ProviderCodeTextField!
    @IBOutlet private weak var fiveTextField: ProviderCodeTextField!
    @IBOutlet private weak var sixTextField: ProviderCodeTextField!

    @IBOutlet weak var stars: UIImageView!
    @IBOutlet weak var middlegroundImage: UIImageView!
    @IBOutlet weak var foregroundImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var invalidCodeLabel: UILabel!
    
    @IBOutlet private weak var verifyCodeButton: UIButton!

    @IBOutlet weak var loadingView: RoundedView?
    @IBOutlet weak var progressSpinner: ProgressCircle!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var delegate: StoreViewControllerDelegate?
    var triggerTextField = ProviderCodeTextField()
    
    private var currentPin = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNotifications()
        loadStore(storeId: .empty)
        storeTextField.becomeFirstResponder()
        loadingView?.isHidden = true
        progressSpinner.update(progress: 0, animated: false)
        Bugsnag.leaveBreadcrumb(withMessage: "Store: Started")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        storeTextField.resignFirstResponder()
    }
    
    private func configureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    @objc
    private func handleKeyboardShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardRectangle = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            UIView.animate(withDuration: 0.25,
                           animations: { [weak self] () -> Void in
                self?.bottomConstraint.constant = keyboardRectangle.height
                self?.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    public func loadStore(storeId: String) {
        currentPin = storeId
        storeTextField.text = currentPin
        updatePinUI(pin: currentPin)
        validatePin(pin: currentPin)
    }
    
    public func updateProgress(progress: Float) {
        progressSpinner.update(progress: CGFloat(progress), animated: true)
    }
    
    private func updatePinUI(pin: String) {
        for i in 1...6 {
            if let view = self.view.viewWithTag(i) as? UITextField {
                if pin.count >= i {
                    let number = String(pin[i - 1])
                    view.text = number
                } else {
                    view.text = nil
                }
            }
        }
    }
    
    private func validatePin(pin: String) {
        if pin.count == 6 {
            if storeIdValid(id: pin) {
                toggleContinueButton(enabled: true)
                configureErrorTextField(isError: false)
            } else {
                configureErrorTextField(isError: true)
            }
        } else {
            toggleContinueButton(enabled: false)
            configureErrorTextField(isError: false)
        }
    }
    
    private func storeIdValid(id: String) -> Bool {
        guard Bundle.main.path(forResource: id, ofType: "json") != nil
        else { return false }
        return true
    }
}

private typealias Configuration = StoreViewController
extension Configuration {
    private func configureUI() {
        configureTextField()
        toggleContinueButton(enabled: false)
        
        foregroundImage.addParallax(amount: 150)
        middlegroundImage.addParallax(amount: 100)
        stars.addParallax(amount: 65)
        backgroundImage.addParallax(amount: 50)
        logoImage.addParallax(amount: 25)
    }
    
    private func toggleContinueButton(enabled: Bool) {
        verifyCodeButton.alpha = enabled ? 1 : 0.5
        verifyCodeButton.isEnabled = enabled
    }
    
    private func configureTextField() {
        oneTextField.codeDelegate = self
        secondTextField.codeDelegate = self
        thirdTextField.codeDelegate = self
        fourthTextField.codeDelegate = self
        fiveTextField.codeDelegate = self
        sixTextField.codeDelegate = self
        triggerTextField.codeDelegate = self
    }

    private func configureErrorTextField(isError: Bool) {
        oneTextField.isError = isError
        secondTextField.isError = isError
        thirdTextField.isError = isError
        fourthTextField.isError = isError
        fiveTextField.isError = isError
        sixTextField.isError = isError
        invalidCodeLabel.isHidden = !isError
    }
    
    private func checkIsValidCode() -> (isValid: Bool, code: String) {
        guard let firstText = oneTextField.text,
              let secondText = secondTextField.text,
              let thirdText = thirdTextField.text,
              let fourthText = fourthTextField.text,
              let fifthText = fiveTextField.text,
              let sixthText = sixTextField.text
        else { return (isValid: false, code: "") }
        
        let code = firstText + secondText + thirdText + fourthText + fifthText + sixthText

        return (isValid: StoreRepo.Stores.allCases.contains(where: { $0.rawValue == code }), code: code)
    }
}

private typealias IBAction = StoreViewController
extension IBAction {
    @IBAction func storePinTapped(_ sender: Any) {
        storeTextField.becomeFirstResponder()
    }
    
    @IBAction func onVerifyButtonTapped(_ sender: UIButton) {
        let code = checkIsValidCode()
        guard code.isValid else {
            configureErrorTextField(isError: true)
            return
        }
        loadingView?.isHidden = false
        storeTextField.resignFirstResponder()
        Bugsnag.leaveBreadcrumb(withMessage: "Store: show store code: \(code.code)")
        delegate?.showDashboard(self, storeId: code.code)
    }

    @IBAction func onDemoModeButtonTapped(_ sender: UIButton) {
        Bugsnag.leaveBreadcrumb(withMessage: "Store: show demo")
        delegate?.showDemoApp(self)
    }
}

private typealias TextViewDelegate = StoreViewController
extension TextViewDelegate: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        debugPrint("URL: \(URL)")
        return true
    }
}

private typealias TextFieldDelegate = StoreViewController
extension TextFieldDelegate: ProviderCodeDelegate {
    func textFieldDidChange(_ textField: UITextField) {
        if textField != triggerTextField {
            configureErrorTextField(isError: false)
        }
        guard !oneTextField.isEmpty,
              !secondTextField.isEmpty,
              !thirdTextField.isEmpty,
              !fourthTextField.isEmpty,
              !fiveTextField.isEmpty,
              !sixTextField.isEmpty
        else {
            toggleContinueButton(enabled: false)
            return
        }
        toggleContinueButton(enabled: true)
    }
}

extension StoreViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let text = textField.text,
           let range = Range(range, in: text) {
            if currentPin.count == 6,
               !string.isEmpty {
                return false
            }
            currentPin = text.replacingCharacters(in: range, with: string)
        }
        updatePinUI(pin: currentPin)
        validatePin(pin: currentPin)
        return currentPin.count <= 6
    }
}
