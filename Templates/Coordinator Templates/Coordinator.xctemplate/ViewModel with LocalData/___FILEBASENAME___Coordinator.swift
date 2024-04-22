//___FILEHEADER___

import UIKit

class ___FILEBASENAMEASIDENTIFIER___: Coordinator<<#T##CoordinationResult#>> {
    
    lazy var viewController: ___VARIABLE_productName:identifier___ViewController = {
        let localData = ___VARIABLE_productName:identifier___ViewController.LocalData(myData: 0)
        let controller = ___VARIABLE_productName:identifier___ViewController.instantiate(localData: localData)
        controller.delegate = self
        return controller
    }()
    
    override func toPresentable() -> UIViewController {
        viewController
    }
}

extension ___FILEBASENAMEASIDENTIFIER___: ___VARIABLE_productName:identifier___ViewControllerDelegate {
    func myCallback(_ controller: ___VARIABLE_productName:identifier___ViewController) {
        print("Callback received")
    }
}