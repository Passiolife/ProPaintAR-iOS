//
//  MLMethod.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/2/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

enum MLMethod {
    case environment
    case surface
    case abnormality
    
    var modelType: ModelType {
        switch self {
        case .environment:
            return .environments
            
        case .surface:
            return .surfaces
            
        case .abnormality:
            return .abnormalities
        }
    }
}
