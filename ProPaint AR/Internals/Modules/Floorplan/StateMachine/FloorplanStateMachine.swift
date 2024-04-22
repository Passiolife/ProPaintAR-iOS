//
//  FloorplanStateMachine.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 5/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class FloorplanStateMachine {
    @Published var statePublisher: State
    private var state: State {
        stateMachine.currentState
    }

    private static let debugEnabled = false
    private let stateMachine: PureStateMachine<State, Event, Command>
    private var cancellables = Set<AnyCancellable>()
    private static var description: String { String(describing: Self.self) }
    private var description: String { String(describing: Self.self) }

    // These methods are how the state machine sends commands to the external system.
    public var startScan: (() -> Void)?
    public var finishedPlacingCorners: ((Bool) -> Void)?
    public var finishedCeilingHeight: (() -> Void)?
    public var selectedSecondaryColor: ((Paint) -> Void)?
    public var sceneReset: (() -> Void)?
    public var showOcclusionWizardAction: (() -> Void)?
    public var showLidarOcclusionWizardAction: (() -> Void)?
    
    init() {
        self.stateMachine = FloorplanStateMachine.createStateMachine()
        statePublisher = self.stateMachine.publicState

        self.stateMachine.$publicState
            .sink { [weak self] newState in
                guard let self = self,
                      newState != self.statePublisher
                else { return }
                self.statePublisher = newState
            }
            .store(in: &cancellables)
    }

    // These public functions are how the system
    // interacts with the state machine
    
    public func tutorialFinished() {
        Self.debugLog(message: "\(description): event:tutorialDone")
        fire(event: .tutorialDone)
    }
    
    public func scanFinished() {
        Self.debugLog(message: "\(description): event:scanFinished")
        fire(event: .scanFinished)
    }
    
    public func updateCornerCount(cornerCount: Int) {
        Self.debugLog(message: "\(description): event:cornerCountUpdated(\(cornerCount))")
        fire(event: .cornerCountUpdated(cornerCount: cornerCount))
    }
    
    public func finishPlacingCorners(closedShape: Bool) {
        Self.debugLog(message: "\(description): event:finishedPlacingCorners")
        fire(event: .finishedPlacingCorners(closedShape: closedShape))
    }
    
    public func setHeight() {
        Self.debugLog(message: "\(description): event:setHeight")
        fire(event: .setHeight)
    }
    
    public func selectPrimaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectPrimaryColor")
        fire(event: .selectPrimaryColor(color))
    }
    
    public func selectSecondaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectSecondaryColor")
        fire(event: .selectSecondaryColor(color))
    }
    
    public func paintFirstWall() {
        Self.debugLog(message: "\(description): event:paintFirstWall")
        fire(event: .paintFirstWall)
    }
    
    public func reset() {
        Self.debugLog(message: "\(description): event:reset")
        fire(event: .reset)
    }
    
    public func showOcclusionWizard() {
        Self.debugLog(message: "\(description): event:showOcclusionWizard")
        fire(event: .showOcclusionWizard)
    }
    
    public func hideOcclusionWizard() {
        Self.debugLog(message: "\(description): event:hideOcclusionWizard")
        fire(event: .hideOcclusionWizard)
    }
    
    public func showLidarOcclusionWizard() {
        Self.debugLog(message: "\(description): event:showLidarOcclusionWizard")
        fire(event: .showLidarOcclusionWizard)
    }
    
    public func hideLidarOcclusionWizard() {
        Self.debugLog(message: "\(description): event:hideLidarOcclusionWizard")
        fire(event: .hideLidarOcclusionWizard)
    }

    private static func debugLog(message: String) {
        guard debugEnabled else { return }
        print(message)
    }

    // This method handles the fired events and emitted commands.
    private func fire(event: Event) {
        let commands = stateMachine.handleEvent(event)
        for command in commands {
            handleCommand(command)
        }
    }

    // This is where the commands emitted by the state machine
    // are handled to interact with the system.
    private func handleCommand(_ command: Command) {
        switch command {
        case .noOp:
            break
        
        case .startScan:
            startScan?()
            
        case .finishPlacingCorners(let closedShape):
            finishedPlacingCorners?(closedShape)
            
        case .finishCeilingHeight:
            finishedCeilingHeight?()
            
        case .selectSecondaryColor(let color):
            selectedSecondaryColor?(color)
            
        case .sceneReset:
            sceneReset?()
            
        case .showOcclusionWizard:
            showOcclusionWizardAction?()
            
        case .showLidarOcclusionWizard:
            showLidarOcclusionWizardAction?()
        }
    }

    // This creates the state machine and also defines all the behaviors
    // for the different state/event combinations of the state machine.
    private static func createStateMachine() -> PureStateMachine<State, Event, Command> {
        PureStateMachine(initialState: .tutorial) { state, event in
            Self.debugLog(message: "\(Self.description): state: \(state.description), event: \(event.description)")
            switch (state, event) {
            case (.tutorial, .tutorialDone):
                return .StateAndCommands(.scanning, [.startScan])
                
            case (.scanning, .scanFinished):
                return .State(.placingCorners(0))
                
            case let (.placingCorners, .cornerCountUpdated(cornerCount: cornerCount)):
                return .State(.placingCorners(cornerCount))
                
            case let (.placingCorners(cornerCount), .finishedPlacingCorners(closedShape)):
                if cornerCount < 2 { return .NoUpdate }
                return .StateAndCommands(.settingHeight, [.finishPlacingCorners(closedShape: closedShape)])
                
            case (.settingHeight, .setHeight):
                return .StateAndCommands(.pickingColor, [.finishCeilingHeight])
                
            case (.pickingColor, .selectSecondaryColor(let color)):
                return .StateAndCommands(.paintingFirstWall, [.selectSecondaryColor(color)])
                
            case (.paintingFirstWall, .paintFirstWall):
                return .State(.fullUI)
                
            case (.paintingFirstWall, .selectSecondaryColor(let color)):
                return .Commands([.selectSecondaryColor(color)])
                
            case (.fullUI, .selectSecondaryColor(let color)):
                return .Commands([.selectSecondaryColor(color)])
                
            case (.fullUI, .showOcclusionWizard):
                return .StateAndCommands(.occlusionWizard, [.showOcclusionWizard])
                
            case (.fullUI, .showLidarOcclusionWizard):
                return .StateAndCommands(.lidarOcclusionWizard, [.showLidarOcclusionWizard])
                
            case (.occlusionWizard, .hideOcclusionWizard):
                return .State(.fullUI)
                
            case (.lidarOcclusionWizard, .hideLidarOcclusionWizard):
                return .State(.fullUI)
                
            case (_, .reset):
                return .StateAndCommands(.tutorial, [.sceneReset])
                
            default:
                return .NoUpdate
            }
        }
    }
}

extension FloorplanStateMachine {
    // This contains all possible states for the system.
    enum State: Equatable {
        case tutorial
        case scanning
        case placingCorners(Int)
        case settingHeight
        case pickingColor
        case paintingFirstWall
        case fullUI
        case occlusionWizard
        case lidarOcclusionWizard
        
        var description: String {
            switch self {
            case .tutorial: return "tutorial"
            case .scanning: return "scanning"
            case .placingCorners: return "placingCorners"
            case .settingHeight: return "settingHeight"
            case .pickingColor: return "pickingColor"
            case .paintingFirstWall: return "paintingFirstWall"
            case .fullUI: return "fullUI"
            case .occlusionWizard: return "occlusionWizard"
            case .lidarOcclusionWizard: return "lidarOcclusionWizard"
            }
        }
    }
    
    // These are events that allow the system to interact
    // with the state machine.
    private enum Event {
        case tutorialDone
        case scanFinished
        case cornerCountUpdated(cornerCount: Int)
        case finishedPlacingCorners(closedShape: Bool)
        case setHeight
        case selectPrimaryColor(Paint)
        case selectSecondaryColor(Paint)
        case paintFirstWall
        case reset
        case showOcclusionWizard
        case showLidarOcclusionWizard
        case hideOcclusionWizard
        case hideLidarOcclusionWizard
        
        var description: String {
            switch self {
            case .tutorialDone: return "tutorialDone"
            case .scanFinished: return "scanFinished"
            case .cornerCountUpdated: return "cornerCountUpdated"
            case .finishedPlacingCorners: return "finishedPlacingCorners"
            case .setHeight: return "setHeight"
            case .selectPrimaryColor: return "selectPrimaryColor"
            case .selectSecondaryColor: return "selectSecondaryColor"
            case .paintFirstWall: return "paintFirstWall"
            case .reset: return "reset"
            case .showOcclusionWizard: return "showOcclusionWizard"
            case .showLidarOcclusionWizard: return "showLidarOcclusionWizard"
            case .hideOcclusionWizard: return "hideOcclusionWizard"
            case .hideLidarOcclusionWizard: return "hideLidarOcclusionWizard"
            }
        }
    }
    
    // Command contains all of the commands for the state machine to
    // interact with the system.
    private enum Command {
        case noOp
        case startScan
        case finishPlacingCorners(closedShape: Bool)
        case finishCeilingHeight
        case selectSecondaryColor(Paint)
        case sceneReset
        case showOcclusionWizard
        case showLidarOcclusionWizard
    }
}
