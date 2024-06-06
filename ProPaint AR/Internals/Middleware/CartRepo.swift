//
//  CartRepo.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import RemodelAR
import UIKit

protocol CartRepo {
    var items: [CartItem] { get }
    var itemsPublished: Published<[CartItem]> { get }
    var itemsPublisher: Published<[CartItem]>.Publisher { get }
    var total: Double { get }
    
    func addItems(from paintInfo: PaintInfo, colorRepo: ColorRepo)
    func addItem(item: CartItem)
    func removeItem(id: String)
    func clearCart()
    func performCheckout()
}

final class CartRepoImpl: CartRepo {
    @Published var items = [CartItem]()
    var itemsPublished: Published<[CartItem]> { _items }
    var itemsPublisher: Published<[CartItem]>.Publisher { $items }
    
    var total: Double {
        getTotal()
    }
    
    init() {
    }
    
    func addItems(from paintInfo: PaintInfo, colorRepo: ColorRepo) {
        clearCart()
        
        var colors = [String: WallAreaInfo]()
        for wall in paintInfo.paintedWalls {
            if var info = colors[wall.paint.id] {
                info.width += wall.area.width
                info.area += wall.area.area
                colors[wall.paint.id] = info
            } else {
                let info = WallAreaInfo(width: wall.area.width,
                                        area: wall.area.area,
                                        info: wall)
                colors[wall.paint.id] = info
            }
        }
        for (_, value) in colors {
            let area = AreaInfo(width: value.width, height: value.area / value.width, area: value.area)
            let id = value.info.paint.id
            if let sizes = colorRepo.sizes(id: id) {
                let paint = ProPaint(wallPaint: value.info.paint,
                                     sizes: sizes)
                let info = ProWallInfo(id: value.info.id,
                                       area: area,
                                       paint: paint,
                                       surfaceType: value.info.surfaceType)
                let coverage = 37.16 // coverage in square meters
                let quantity = Int(max(1, Double(area.area / coverage).rounded(.up)))
                let data = CartItem(paintData: info, quantity: quantity)
                addItem(item: data)
            }
        }
    }
    
    func addItem(item: CartItem) {
        items.append(item)
    }
    
    func removeItem(id: String) {
        items.removeAll(where: { $0.id == id })
    }
    
    func clearCart() {
        items.removeAll()
    }
    
    func performCheckout() {
        let deepUrl = "com.amazon.mobile.shopping.web://"
        let webUrl = "https://"
        let cartPath = "amazon.com/gp/aws/cart/add.html"
//        let accessKey = "AKIAIYP2RRPGS6ECGJYQ"
        
        var url = cartPath
//        url += "?AWSAccessKeyId=\(accessKey)"
        url += "?AssociateTag=passio0c6-20"
        
        for (index, item) in items.enumerated() {
            if let asin = item.asin,
               item.quantity > 0 {
                url += "&ASIN.\(index)=\(asin)"
                url += "&Quantity.\(index)=\(item.quantity)"
            }
        }
        
        guard let appUrl = URL(string: deepUrl + url),
              let browserUrl = URL(string: webUrl + url)
        else { return }
        
        if UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else {
            UIApplication.shared.open(browserUrl)
        }
    }
    
    private func getTotal() -> Double {
        items.reduce(0) { $0 + $1.totalCost }
    }
}

public struct WallAreaInfo {
    var width: Double
    var area: Double
    let info: WallInfo
}
