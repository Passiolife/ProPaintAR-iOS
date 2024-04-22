//
//  StoreRepo.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 25/07/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import Kingfisher

enum StoreRepo {
    static var storeId: String? {
        get {
            guard let data = try? JSONSerialization.loadJSON(withFilename: "config"),
                  let config = data as? [String: Any],
                  let storeId = config["storeId"] as? String
            else { return nil }
            
            return storeId
        }
        set {
            let data = ["storeId": newValue]
            _ = try? JSONSerialization.saveJSON(jsonObject: data, toFilename: "config")

            ImageCache.default.clearMemoryCache()
            ImageCache.default.clearDiskCache()
        }
    }

    static func removeStoreID(callback: (() -> Void)? = nil) {
        JSONSerialization.deleteJSON(filename: "config")
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache {
            callback?()
        }
    }

    enum Stores: String, CaseIterable {
        case demoStore1 = "000000"
        case demoStore2 = "111111"
        case demoStore3 = "222222"
    }
}
