//___FILEHEADER___

import Combine
import Foundation

extension ___VARIABLE_productName:identifier___ViewController {
    class LocalData {
        
        @Published final private(set) var data: ViewModel
        
        init(myData: Int) {
            data = ViewModel(myData: myData)
        }
        
        // Make a copy of the data before modifying so we only get one update event if we modify multiple variables.
        func incrementDataCount() {
            var dataCopy = data
            dataCopy.myData += 1
            data = dataCopy
        }
    }
}
