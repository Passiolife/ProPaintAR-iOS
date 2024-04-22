//
//  AppConfiguration.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/30/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

class AppConfiguration: NSCoding, NSSecureCoding {
    let storeId: String?
    
    public static var supportsSecureCoding = true
    
    public init(storeId: String) {
        self.storeId = storeId
    }
    
    public required convenience init?(coder: NSCoder) {
        guard let storeId = coder.decodeObject(forKey: "storeId") as? String
        else { return nil }
        
        self.init(storeId: storeId)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(storeId, forKey: "storeId")
    }
}
