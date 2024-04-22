//
//  LidarViewModel.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/9/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import UIKit

extension LidarViewController {
    struct ViewModel {
        var occlusionViewModel: OcclusionStateInfo
        
        init() {
            occlusionViewModel = OcclusionStateInfoImpl()
        }
    }
}

extension LidarStateMachine.State {
    var tutorialVisible: Bool {
        switch self {
        case .tutorial: return true
        default: return false
        }
    }
    
    var scanButtonVisible: Bool {
        switch self {
        case .ready, .scanning: return true
        default: return false
        }
    }
    
    var scanButtonAnimating: Bool {
        switch self {
        case .scanning: return true
        default: return false
        }
    }
    
    var scanButtonTitle: String {
        switch self {
        case .ready: return "START"
        case .scanning: return "DONE"
        default: return ""
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
        case .pickingColor, .paintingFirstWall, .fullUI: return true
        default: return false
        }
    }
    
    var userInstructionsVisible: Bool {
        switch self {
        case .ready, .scanning: return true
        default: return false
        }
    }
    
    var userInstructions: String {
        switch self {
        case .ready:
            return "Tap `\(scanButtonTitle)`, then move your camera around the room to capture all the walls you want to paint."
        case .scanning:
            return "When you are finished capturing all the walls you want to paint, (they will be normally colored when they are ready to paint.), tap `\(scanButtonTitle)`."
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
}
