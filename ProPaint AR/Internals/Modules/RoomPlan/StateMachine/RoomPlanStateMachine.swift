//
//  RoomPlanStateMachine.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 3/1/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class RoomPlanStateMachine {
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
    public var startedRoomPlanScan: (() -> Void)?
    public var finishedRoomPlanScan: (() -> Void)?
    public var finishedReviewing: (() -> Void)?
    public var selectedSecondaryColor: ((Paint) -> Void)?
    public var sceneReset: (() -> Void)?
    public var showOcclusionWizardAction: (() -> Void)?
    public var showLidarOcclusionWizardAction: (() -> Void)?
    public var updateEditingOcclusions: ((Bool) -> Void)?
    
    init() {
        self.stateMachine = RoomPlanStateMachine.createStateMachine()
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
    
    public func scanUpdated(numWalls: Int, totalLength: Float) {
        Self.debugLog(message: "\(description): event:scanUpdated(\(numWalls), \(totalLength)")
        fire(event: .scanUpdated(numWalls, totalLength))
    }
    
    public func doneScanning() {
        Self.debugLog(message: "\(description): event:doneScanning")
        fire(event: .doneScanning)
    }
    
    public func finishReviewing() {
        Self.debugLog(message: "\(description): event:finishedReviewing")
        fire(event: .finishedReviewing)
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
    
    public func toggleEditingOcclusions() {
        Self.debugLog(message: "\(description): event:toggleEditingOcclusions")
        fire(event: .toggleEditingOcclusions)
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
            
        case .startRoomPlanScan:
            startedRoomPlanScan?()
            
        case .finishRoomPlanScan:
            finishedRoomPlanScan?()
            
        case .finishReviewing:
            finishedReviewing?()
            
        case .selectSecondaryColor(let color):
            selectedSecondaryColor?(color)
            
        case .sceneReset:
            sceneReset?()
            
        case .showOcclusionWizard:
            showOcclusionWizardAction?()
            
        case .showLidarOcclusionWizard:
            showLidarOcclusionWizardAction?()
            
        case .setEditingOcclusions(let editing):
            updateEditingOcclusions?(editing)
        }
    }

    // This creates the state machine and also defines all the behaviors
    // for the different state/event combinations of the state machine.
    private static func createStateMachine() -> PureStateMachine<State, Event, Command> {
        PureStateMachine(initialState: .tutorial) { state, event in
            Self.debugLog(message: "\(Self.description): state: \(state.description), event: \(event.description)")
            switch (state, event) {
            case (.tutorial, .tutorialDone):
                return .StateAndCommands(.scanning(0, 0), [.startRoomPlanScan])
                
            case let (.scanning, .scanUpdated(newWalls, totalLength)):
                return .State(.scanning(newWalls, totalLength))
                
            case (.scanning, .doneScanning):
                return .StateAndCommands(.reviewing, [.finishRoomPlanScan])
                
            case (.reviewing, .finishedReviewing):
                return .StateAndCommands(.pickingColor, [.finishReviewing])
                
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
            
            case (.fullUI, .toggleEditingOcclusions):
                return .StateAndCommands(.editingOcclusions, [.setEditingOcclusions(true)])
                
            case (.editingOcclusions, .toggleEditingOcclusions):
                return .StateAndCommands(.fullUI, [.setEditingOcclusions(false)])
                
            case (.occlusionWizard, .hideOcclusionWizard):
                return .State(.fullUI)
                
            case (.lidarOcclusionWizard, .hideLidarOcclusionWizard):
                return .State(.fullUI)
                
            case (_, .reset):
                return .StateAndCommands(.scanning(0, 0), [.sceneReset])
                
            default:
                return .NoUpdate
            }
        }
    }
}

extension RoomPlanStateMachine {
    // This contains all possible states for the system.
    enum State: Equatable {
        case tutorial
        case scanning(Int, Float)
        case reviewing
        case pickingColor
        case paintingFirstWall
        case fullUI
        case occlusionWizard
        case lidarOcclusionWizard
        case editingOcclusions
        
        var description: String {
            switch self {
            case .tutorial: return "tutorial"
            case .scanning: return "scanning"
            case .reviewing: return "reviewing"
            case .pickingColor: return "pickingColor"
            case .paintingFirstWall: return "paintingFirstWall"
            case .fullUI: return "fullUI"
            case .occlusionWizard: return "occlusionWizard"
            case .lidarOcclusionWizard: return "lidarOcclusionWizard"
            case .editingOcclusions: return "editingOcclusions"
            }
        }
    }
    
    // These are events that allow the system to interact
    // with the state machine.
    private enum Event {
        case tutorialDone
        case scanUpdated(Int, Float)
        case doneScanning
        case finishedReviewing
        case selectPrimaryColor(Paint)
        case selectSecondaryColor(Paint)
        case paintFirstWall
        case reset
        case showOcclusionWizard
        case showLidarOcclusionWizard
        case hideOcclusionWizard
        case hideLidarOcclusionWizard
        case toggleEditingOcclusions
        
        var description: String {
            switch self {
            case .tutorialDone: return "tutorialDone"
            case .scanUpdated: return "scanUpdated"
            case .doneScanning: return "doneScanning"
            case .finishedReviewing: return "finishedReviewing"
            case .selectPrimaryColor: return "selectPrimaryColor"
            case .selectSecondaryColor: return "selectSecondaryColor"
            case .paintFirstWall: return "paintFirstWall"
            case .reset: return "reset"
            case .showOcclusionWizard: return "showOcclusionWizard"
            case .showLidarOcclusionWizard: return "showLidarOcclusionWizard"
            case .hideOcclusionWizard: return "hideOcclusionWizard"
            case .hideLidarOcclusionWizard: return "hideLidarOcclusionWizard"
            case .toggleEditingOcclusions: return "toggleEditingOcclusions"
            }
        }
    }
    
    // Command contains all of the commands for the state machine to
    // interact with the system.
    private enum Command {
        case noOp
        case startRoomPlanScan
        case finishRoomPlanScan
        case finishReviewing
        case selectSecondaryColor(Paint)
        case sceneReset
        case showOcclusionWizard
        case showLidarOcclusionWizard
        case setEditingOcclusions(Bool)
    }
}
