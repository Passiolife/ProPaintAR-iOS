//
//  OcclusionInfo.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/18/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol OcclusionStateInfo {
    var state: OcclusionState { get set }
    var colors: [UIColor] { get set }
    var threshold: Float { get set }
}

public enum OcclusionState: Int {
    case start
    case pickingColors
    case adjustingThreshold
}

struct OcclusionStateInfoImpl: OcclusionStateInfo {
    var state: OcclusionState
    var colors: [UIColor]
    var threshold: Float
    
    init(data: OcclusionStateInfo? = nil) {
        self.state = data?.state ?? .start
        self.colors = data?.colors ?? []
        self.threshold = data?.threshold ?? 10
    }
    
    mutating func setState(state: OcclusionState) {
        self.state = state
    }
    
    mutating func addColor(color: UIColor) {
        guard colors.count < 3
        else { return }
        
        colors.append(color)
    }
    
    mutating func setThreshold(threshold: Float) {
        self.threshold = threshold
    }
    
    mutating func internalReset() {
        state = .start
        colors.removeAll()
        threshold = 10
    }
}
