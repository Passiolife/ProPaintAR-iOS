//
//  CartItem.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

class CartItem {
    var paint: ProWallInfo
    var quantity: Int
    var cost: Double {
        switch selectedSize {
        case .gallon: return 55
        case .sample: return 5
        default: return 0
        }
    }
    var totalCost: Double {
        cost * Double(quantity)
    }
    var id: String {
        paint.id
    }
    var sizes: [ContainerSize]
    var selectedSize: ContainerSize? {
        didSet {
            selectedSheen = selectedSize?.sheens.first
        }
    }
    var selectedSheen: SheenType?
    var asin: String? {
        selectedSheen?.asin
    }
    
    init(paintData: ProWallInfo, quantity: Int) {
        self.paint = paintData
        self.quantity = quantity
        sizes = paintData.paint.sizes
        selectedSize = sizes.first
        selectedSheen = selectedSize?.sheens.first
    }
}

enum CartSize {
    case gallon([SheenType])
    case sample([SheenType])
}
