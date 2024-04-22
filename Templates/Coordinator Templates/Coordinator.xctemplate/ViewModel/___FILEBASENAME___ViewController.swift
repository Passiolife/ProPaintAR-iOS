//___FILEHEADER___

import UIKit

protocol ___FILEBASENAMEASIDENTIFIER___Delegate: AnyObject {
    func myCallback(_ controller: ___FILEBASENAMEASIDENTIFIER___)
}

class ___FILEBASENAMEASIDENTIFIER___: UIViewController {
    
    weak var delegate: ___FILEBASENAMEASIDENTIFIER___Delegate?
    var viewModel: ViewModel!
    
    internal static func instantiate(viewModel: ViewModel) -> Self {
        let vc = Self.instantiate()
        vc.viewModel = viewModel
        return vc
    }
}