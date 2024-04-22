//
//  AppDependency.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 4/26/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

public struct AppDependency {
    let colorRepo: ColorRepo
    let cartRepo: CartRepo
    let customizationRepo: CustomizationRepo?
    let storeId: String?

    private init(
        colorRepo: ColorRepo,
        cartRepo: CartRepo,
        customizationRepo: CustomizationRepo?,
        storeId: String?
    ) {
        self.colorRepo = colorRepo
        self.cartRepo = cartRepo
        self.customizationRepo = customizationRepo
        self.storeId = storeId
    }
    
    static func createDependencies(
        progress: ((Float) -> Void)? = nil,
        done: (() -> Void)? = nil
    ) -> AppDependency {
        let storeId = StoreRepo.storeId
        let colorAPI = ColorAPIMock()
        let colorRepo = ColorRepoImpl(colorAPI: colorAPI)
        let optionsAPI = OptionsAPIMock()
        let cartRepo = CartRepoImpl()
        var customizationRepo: CustomizationRepo?
        
        if let storeId = storeId {
            let storeExists = optionsAPI.storeExists(storeId: storeId)
            if !storeExists {
                StoreRepo.removeStoreID()
            }
            customizationRepo = CustomizationRepoImpl(
                optionsAPI: optionsAPI,
                storeId: storeId
            )
            customizationRepo?.prefetchImages { progressPercent in
                progress?(progressPercent)
            } done: {
                done?()
            }
        }
        
        return AppDependency(
            colorRepo: colorRepo,
            cartRepo: cartRepo,
            customizationRepo: customizationRepo,
            storeId: storeId
        )
    }
}
