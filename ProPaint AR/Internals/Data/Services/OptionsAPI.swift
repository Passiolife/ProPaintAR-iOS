//
//  OptionsAPI.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/21/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

protocol OptionsAPI {
    func fetchOptions(storeId: String?, callback: @escaping (CustomizationOptions, Error?) -> Void)
}

class OptionsAPIMock: OptionsAPI {
    func storeExists(storeId: String) -> Bool {
        guard let optionsPath = Bundle.main.path(forResource: storeId, ofType: "json"),
              FileManager.default.fileExists(atPath: optionsPath)
        else { return false }
        
        return true
    }
    
    func fetchOptions(storeId: String?, callback: @escaping (CustomizationOptions, Error?) -> Void) {
        let options = fetchOptions(storeId: storeId)
        callback(options, nil)
    }
    
    func fetchOptions(storeId: String?) -> CustomizationOptions {
        guard let storeId = storeId,
              let optionsPath = Bundle.main.path(forResource: storeId, ofType: "json")
        else { return .empty() }

        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: optionsPath),
                                    options: .uncached)
            let model = try jsonDecoder.decode(CustomizationOptions.self, from: jsonData)
            return model
        } catch {
            debugPrint("error: \(error)")
        }

        return .empty()
    }
}
