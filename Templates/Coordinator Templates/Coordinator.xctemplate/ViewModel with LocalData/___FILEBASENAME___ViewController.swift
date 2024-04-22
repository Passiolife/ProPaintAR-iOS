//___FILEHEADER___

import Combine
import UIKit

protocol ___FILEBASENAMEASIDENTIFIER___Delegate: AnyObject {
    func myCallback(_ controller: ___FILEBASENAMEASIDENTIFIER___)
}

class ___FILEBASENAMEASIDENTIFIER___: UIViewController {
    
    weak var delegate: ___FILEBASENAMEASIDENTIFIER___Delegate?
    var viewModel: ViewModel!
    
    var localData: LocalData!
    var cancellables = Set<AnyCancellable>()
    
    internal static func instantiate(localData: LocalData) -> Self {
        let vc = Self.instantiate()
        vc.localData = localData
        return vc
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        localData.$data.sink { data in
            print("Local Data Updated: \(data.myData)")
        }.store(in: &cancellables)
    }
}