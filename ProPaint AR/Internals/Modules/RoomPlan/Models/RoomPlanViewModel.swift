//
//  RoomPlanViewModel.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 3/1/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import UIKit

@available(iOS 16, *)
extension RoomPlanViewController {
    struct ViewModel {
        var occlusionViewModel: OcclusionStateInfo
        var lidarOcclusionThreshold: Float
        
        init() {
            occlusionViewModel = OcclusionStateInfoImpl()
            lidarOcclusionThreshold = 0.05
        }
    }
}

extension RoomPlanStateMachine.State {
    var tutorialVisible: Bool {
        switch self {
        case .tutorial: return true
        default: return false
        }
    }
    
    var doneScanningButtonVisible: Bool {
        switch self {
        case let .scanning(numWalls, totalLength):
            return numWalls >= 3 || totalLength >= 2.5
        default: return false
        }
    }
    
    var reviewingScan: Bool {
        switch self {
        case .reviewing: return true
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
    
    var userInstructionsVisible: Bool {
        switch self {
        case .scanning: return true
        default: return false
        }
    }
    
    var userInstructions: String {
        switch self {
        case let .scanning(numWalls, totalLength):
            if numWalls <= 0 {
                return "Move your camera back and forth from the top of your wall to the bottom."
            }
            if !(numWalls >= 3 || totalLength >= 2.5) {
                let line1 = "Move your camera around the room to capture from one edge to the other "
                let line2 = "of a wall you want to paint. A small 3D model will appear to show your progress."
                return [line1, line2].joined()
            }
            let line1 = "Continue to move your camera around the room until all the walls "
            let line2 = "you want to paint are outlined in white."
            return [line1, line2].joined()
            
        case .reviewing:
            return "When you are finished reviewing your floor plan, tap `DONE`."
        default: return ""
        }
    }
    
    var userHint: PaddedTextView.QueuableMessage? {
        switch self {
        case .pickingColor:
            return .string(message: "Select a color", duration: nil)
            
        case .paintingFirstWall:
            return .string(message: "Tap on walls to paint them", duration: nil)
            
        case .fullUI:
            return .string(message: "To set brightness, tap on the wall or tap and drag up/down.",
                           duration: 4)
        default: return nil
        }
    }
    
    var editingOcclusions: Bool {
        switch self {
        case .editingOcclusions:
            return true
        default: return false
        }
    }
}
