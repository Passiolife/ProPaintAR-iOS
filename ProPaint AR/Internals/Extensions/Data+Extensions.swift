//
//  Data+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/8/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

extension Data {
    func printFormattedJSON() {
        if let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            printJSONData(jsonData)
        } else {
            assertionFailure("Malformed JSON")
        }
    }
    
    func printJSON() {
        printJSONData(self)
    }
    
    private func printJSONData(_ data: Data) {
        print(String(decoding: data, as: UTF8.self))
    }
}
