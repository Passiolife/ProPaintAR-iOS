//
//  LegacyViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//
// swiftlint:disable line_length

import UIKit

extension LegacyViewController {
    struct ViewModel {
        var occlusionViewModel: OcclusionStateInfo
        var lidarOcclusionThreshold: Float
        
        init() {
            occlusionViewModel = OcclusionStateInfoImpl()
            lidarOcclusionThreshold = 0.05
        }
    }
}

extension LegacyStateMachine.State {
    var tutorialVisible: Bool {
        switch self {
        case .tutorial: return true
        default: return false
        }
    }
    
    var addButtonVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var isWizardVisible: Bool {
        switch self {
        case .occlusionWizard, .lidarOcclusionWizard: return true
        default: return false
        }
    }
    
    var uiControlsVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var cartButtonVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var colorPickerVisible: Bool {
        switch self {
        case .pickingColor, .colorPicked, .fullUI: return true
        default: return false
        }
    }
    
    var userInstructionsVisible: Bool {
        switch self {
        case .readyToPlaceWall, .placingFirstCorner, .placingSecondCorner: return true
        default: return false
        }
    }
    
    var userInstructions: String {
        switch self {
        case .readyToPlaceWall:
            return "Place the top of your device against the wall with the screen facing the ceiling then tap `Place Wall`."
            
        case .placingWall:
            return "Place the top of your device against the wall with the screen facing the ceiling then tap `Place Wall`."
            
        case .placingFirstCorner:
            return "Step back from the wall and aim the dot at one of the corners of the wall, then tap on the screen."
            
        case .placingSecondCorner:
            return "Aim your device at the wall point that is kitty corner to the first point, then tap on the screen."
            
        default: return ""
        }
    }
    
    var userHint: [PaddedTextView.QueuableMessage]? {
        switch self {
        case .pickingColor:
            return [.string(message: "Select a color", duration: nil)]
            
        case .colorPicked:
            return [.string(message: "Tap `Done` when ready", duration: nil)]
        
        case let .fullUI(isInitialShow, _, _):
            if isInitialShow {
                return [.string(message: "To set brightness, tap on the wall or tap and drag up/down",
                                duration: 4)]
            } else {
                return []
            }
        default: return nil
        }
    }
    
    var userHintVisible: Bool {
        switch self {
        case .pickingColor, .colorPicked, .fullUI: return true
        default: return false
        }
    }
    
    var scanOverlayVisible: Bool {
        switch self {
        case .scanning: return true
        default: return false
        }
    }
    
    var placeWallButtonVisible: Bool {
        switch self {
        case .readyToPlaceWall:
            return true
            
        default: return false
        }
    }
    
    var donePickingColorButtonVisible: Bool {
        switch self {
        case .colorPicked: return true
        default: return false
        }
    }
    
    var placingWallViewVisible: Bool {
        switch self {
        case .placingWall: return true
        default: return false
        }
    }
    
    var placingWallActivityVisible: Bool {
        switch self {
        case let .placingWall(steadyCount: _, angle: angle):
            if abs(angle) <= 8 {
                return true
            } else {
                return false
            }
        default: return false
        }
    }
    
    var placingWallProgress: CGFloat {
        switch self {
        case let .placingWall(steadyCount: steadyCount, angle: _):
            return CGFloat(steadyCount) / 120
        default: return 0
        }
    }
    
    var placingWallActivityMessage: String? {
        switch self {
        case let .placingWall(steadyCount: _, angle: angle):
            if abs(angle) <= 8 {
                return "placing wall\nhold device still"
            } else {
                return "please place the device\nperpendicular to the wall"
            }
        default: return nil
        }
    }
    
    var secondaryHintVisible: Bool {
        func shouldShow(distance: Float?, angle: Float?) -> Bool {
            guard let distance = distance,
                  let angle = angle
            else { return false }

            switch distance {
            case 0..<1:
                return angle > 110
                
            case 1..<1.5:
                return angle > 130
                
            default:
                return false
            }
        }
        
        switch self {
        case let .placingFirstCorner(distance, angle):
            return shouldShow(distance: distance, angle: angle)
            
        case let .placingSecondCorner(distance, angle):
            return shouldShow(distance: distance, angle: angle)
            
        case let .fullUI(_, distance, angle):
            return shouldShow(distance: distance, angle: angle)
            
        default:
            return false
        }
    }
}
