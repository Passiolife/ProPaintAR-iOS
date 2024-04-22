//
//  OcclusionWizardViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/17/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

extension OcclusionWizardViewController {
    enum OcclusionCellType {
        case startCell
        case addColorsCell
        case thresholdCell
        
        init(rawValue: Int) {
            switch rawValue {
            case 0: self = .startCell
            case 1: self = .addColorsCell
            case 2: self = .thresholdCell
            default: self = .startCell
            }
        }
    }
    
    struct ViewModel: OcclusionStateInfo {
        var state: OcclusionState = .start
        var colors: [UIColor] = []
        var threshold: Float = 10
        
        init(data: OcclusionStateInfo) {
            self.state = data.state
            self.colors = data.colors
            self.threshold = data.threshold
        }
    }
}
