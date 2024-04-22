//
//  SCNVector3+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import SceneKit

extension SCNVector3 {
    func length() -> Float {
        sqrtf(x * x + y * y + z * z)
    }
}
