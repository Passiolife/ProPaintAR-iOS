//
//  CartViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 7/4/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import RemodelAR

extension CartViewController {
    class ViewModel {
        public var cartData = CartDataModel()
        
        init(
            paintInfo: PaintInfo,
            colorRepo: ColorRepo,
            cartRepo: CartRepo
        ) {
            cartRepo.clearCart()
            
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
                    let data = CartItem(paintData: info, quantity: 1)
                    cartData.add(item: data)
                    cartRepo.addItem(item: data)
                }
            }
        }
    }
}
