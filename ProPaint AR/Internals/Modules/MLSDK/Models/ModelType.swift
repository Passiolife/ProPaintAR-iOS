//
//  ModelType.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 1/26/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Foundation
import UIKit

enum ModelType {
    case abnormalities, abnormalitiesSSD, environments, surfaces
    
    var name: String {
        switch self {
        case .abnormalities:
            return "passio_remodel_abnormality_Class"
        case .abnormalitiesSSD:
            return "passio_remodel_abnormality_SSD"
        case .environments:
            return "passio_remodel_environment_Class"
        case .surfaces:
            return "passio_remodel_surface_Class"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .abnormalities, .abnormalitiesSSD:
            return UIImage(named: "abnormalityIcon")
            
        case .environments:
            return UIImage(named: "envIcon")
            
        case .surfaces:
            return UIImage(named: "surfaceIcon")
        }
    }
}
