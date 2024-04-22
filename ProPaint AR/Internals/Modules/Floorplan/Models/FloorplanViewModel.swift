//
//  FloorplanViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//
// swiftlint:disable line_length

import UIKit

extension FloorplanViewController {
    struct ViewModel {
        var occlusionViewModel: OcclusionStateInfo
        var lidarOcclusionThreshold: Float
        
        init() {
            occlusionViewModel = OcclusionStateInfoImpl()
            lidarOcclusionThreshold = 0.05
        }
    }
}

extension FloorplanStateMachine.State {
    var tutorialVisible: Bool {
        switch self {
        case .tutorial: return true
        default: return false
        }
    }
    
    var uiControlsVisible: Bool {
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
    
    var cartButtonVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var colorPickerVisible: Bool {
        switch self {
        case .pickingColor, .paintingFirstWall, .fullUI: return true
        default: return false
        }
    }
    
    var hideUnpaintedWallsButtonVisible: Bool {
        switch self {
        case .fullUI: return true
        default: return false
        }
    }
    
    var userInstructionsVisible: Bool {
        switch self {
        case .placingCorners, .settingHeight:
            return true
        default: return false
        }
    }
    
    var userInstructions: String {
        switch self {
        case let .placingCorners(cornerCount: cornerCount):
            if cornerCount == 0 {
                return "Aim the dot at the first corner of the room that you want to paint and tap on the screen"
            } else if cornerCount == 1 {
                return "Aim the dot at the next corner of the wall(s) you want to paint then tap on the screen"
            }
            return "Continue to add corners by tapping on the screen. Finish by tapping `Finish`, this will create a wall from only the points you have placed. To create a whole room, place another point on top of the first point. To delete the last placed point, swipe left."
            
        case .settingHeight:
            return "Drag on the wall to set the ceiling height, then tap on `Done`"
        default: return ""
        }
    }
    
    var userHint: [PaddedTextView.QueuableMessage]? {
        switch self {
        case .pickingColor:
            return [.string(message: "Select a color", duration: nil)]
            
        case .paintingFirstWall:
            return [.string(message: "Tap on walls to paint them", duration: nil)]
            
        case .fullUI:
            return [
                .string(message: "To set brightness, tap on the wall or tap and drag up/down",
                        duration: 4),
                .string(message: "Tap on the eye icon to hide unpainted walls",
                        duration: 4)
            ]
        default: return nil
        }
    }
    
    var userHintVisible: Bool {
        switch self {
        case .pickingColor, .paintingFirstWall, .fullUI: return true
        default: return false
        }
    }
    
    var scanOverlayVisible: Bool {
        switch self {
        case .scanning: return true
        default: return false
        }
    }
    
    var finishButtonVisible: Bool {
        switch self {
        case let .placingCorners(cornerCount: cornerCount):
            return cornerCount > 1
            
        default: return false
        }
    }
    
    var setHeightButtonVisible: Bool {
        switch self {
        case .settingHeight: return true
        default: return false
        }
    }
}
