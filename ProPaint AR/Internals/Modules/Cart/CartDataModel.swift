//
//  CartDataModel.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/14/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
class CartDataModel {
    private (set) var items = [CartItem]()
    var didUpdate: (() -> Void)?
    
    var total: Double {
        var total: Double = 0
        for item in items {
            total += item.cost * Double(item.quantity)
        }
        return total
    }
    
    func add(item: CartItem) {
        items.append(item)
        didUpdate?()
    }
    
    func add(items: [CartItem]) {
        for item in items {
            self.items.append(item)
        }
        didUpdate?()
    }
    
    func delete(index: Int) {
        items.remove(at: index)
        didUpdate?()
    }
}
