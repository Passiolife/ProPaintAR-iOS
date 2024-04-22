//
//  Float+Extensions.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

public extension ExpressibleByIntegerLiteral where Self: FloatingPoint {
    func rollingAverage(value: Self, averageCount: Int) -> Self {
        (self - self / Self(averageCount)) + value / Self(averageCount)
    }
}

public extension Float {
    func truncated(decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", self)
    }
}

extension FloatingPoint {
    func interpolate(
        from: (min: Self, max: Self),
        to: (min: Self, max: Self)
    ) -> Self {
        let outDiff = to.max - to.min
        let inDiff = from.max - from.min
        let valDiff = self - from.min
        return (outDiff / inDiff) * valDiff + to.min
    }
}
