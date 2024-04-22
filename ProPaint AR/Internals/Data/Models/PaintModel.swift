//
//  PaintModel.swift
//  Remodel-AR WL
//
//  Created by Parth Gohel on 5/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import RemodelAR
import UIKit

struct PaintModel: Paint {
    var id: String
    var name: String
    var color: UIColor
    var texture: UIImage?
    var code: String?
    var thumbnail: Thumbnail?
    var sizes: [ContainerSize]
    var colorSample: String?
    var secondaryColors: [Paint]
}

extension Paint {
    var wallPaint: WallPaint {
        WallPaint(id: id, name: name, color: color)
    }
}

struct PaintShadow: PaintItemShadow {
    var shadowColor: CGColor?
    var shadowOpacity: Float
    var shadowRadius: CGFloat
    var shadowOffset: CGSize
}
