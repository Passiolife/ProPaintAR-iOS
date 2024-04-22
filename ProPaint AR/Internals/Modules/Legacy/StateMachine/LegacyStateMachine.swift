//
//  LegacyStateMachine.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 6/1/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class LegacyStateMachine {
    @Published var statePublisher: State
    private var state: State {
        stateMachine.currentState
    }

    private static let debugEnabled = false
    private let stateMachine: PureStateMachine<State, Event, Command>
    private var cancellables = Set<AnyCancellable>()
    private static var description: String { String(describing: Self.self) }
    private var description: String { String(describing: Self.self) }
    private var scanningDone = false

    // These methods are how the state machine sends commands to the external system.
    public var placeWallCommand: (() -> Void)?
    public var deleteWallCommand: (() -> Void)?
    public var selectedSecondaryColor: ((Paint) -> Void)?
    public var sceneReset: (() -> Void)?
    public var showOcclusionWizardAction: (() -> Void)?
    public var showLidarOcclusionWizardAction: (() -> Void)?

    init() {
        self.stateMachine = LegacyStateMachine.createStateMachine()
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

    public func addNewWall() {
        Self.debugLog(message: "\(description): event:addNewWall")
        fire(event: .addNewWall)
    }
    
    public func deleteWall() {
        Self.debugLog(message: "\(description): event:deleteWall")
        fire(event: .deleteWall)
    }
    
    public func tutorialFinished() {
        Self.debugLog(message: "\(description): event:tutorialDone")
        fire(event: .tutorialDone(scanningDone))
    }
    
    public func scanFinished() {
        Self.debugLog(message: "\(description): event:scanFinished")
        scanningDone = true
        fire(event: .scanFinished)
    }
    
    public func placeWall() {
        Self.debugLog(message: "\(description): event:placeWall")
        fire(event: .placeWall)
    }
    
    public func deviceAngleUpdated(angle: Float) {
        Self.debugLog(message: "\(description): event:deviceAngleUpdated")
        fire(event: .deviceAngleUpdated(angle))
    }
    
    public func wallAimInfoUpdated(distance: Float?, angle: Float?) {
        Self.debugLog(message: "\(description): event:wallAimInfoUpdated")
        fire(event: .wallAimInfoUpdated(distance, angle))
    }
    
    public func firstCornerSet() {
        Self.debugLog(message: "\(description): event:firstCornerSet")
        fire(event: .firstCornerSet)
    }
    
    public func secondCornerSet() {
        Self.debugLog(message: "\(description): event:secondCornerSet")
        fire(event: .secondCornerSet)
    }
    
    public func selectPrimaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectPrimaryColor")
        fire(event: .selectPrimaryColor(color))
    }
    
    public func selectSecondaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectSecondaryColor")
        fire(event: .selectSecondaryColor(color))
    }
    
    public func donePickingColor() {
        Self.debugLog(message: "\(description): event:donePickingColor")
        fire(event: .donePickingColor)
    }
    
    public func paintFirstWall() {
        Self.debugLog(message: "\(description): event:paintFirstWall")
        fire(event: .paintFirstWall)
    }
    
    public func reset() {
        Self.debugLog(message: "\(description): event:reset")
        scanningDone = false
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
            
        case .placeWall:
            placeWallCommand?()
            
        case .deleteWall:
            deleteWallCommand?()
            
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
            case let (.tutorial, .tutorialDone(scanningDone)):
                if scanningDone {
                    return .State(.pickingColor)
                } else {
                    return .State(.scanning)
                }
                
            case (.scanning, .scanFinished):
                return .State(.pickingColor)
                
            case (.pickingColor, .selectSecondaryColor(let color)):
                return .StateAndCommands(.colorPicked, [.selectSecondaryColor(color)])
                
            case (.colorPicked, .donePickingColor):
                return .State(.readyToPlaceWall)
                
            case (.readyToPlaceWall, .placeWall):
                return .State(.placingWall(steadyCount: 0, angle: 0))
                
            case let (.placingWall(steadyCount: steadyCount, angle: _), .deviceAngleUpdated(angle)):
                if steadyCount > 120 {
                    return .StateAndCommands(.placingFirstCorner(distance: nil, angle: nil), [.placeWall])
                }
                
                if abs(angle) > 8 {
                    return .State(.placingWall(steadyCount: 0, angle: angle))
                } else {
                    return .State(.placingWall(steadyCount: steadyCount + 1, angle: angle))
                }
                
            case let (.placingFirstCorner, .wallAimInfoUpdated(distance, angle)):
                return .State(.placingFirstCorner(distance: distance, angle: angle))
                
            case let (.placingSecondCorner, .wallAimInfoUpdated(distance, angle)):
                return .State(.placingSecondCorner(distance: distance, angle: angle))
                
            case let (.fullUI, .wallAimInfoUpdated(distance, angle)):
                return .State(.fullUI(isInitialShow: false, distance: distance, angle: angle))
                
            case let (.placingFirstCorner(distance, angle), .firstCornerSet):
                return .State(.placingSecondCorner(distance: distance, angle: angle))
                
            case let (.placingSecondCorner(distance, angle), .secondCornerSet):
                return .State(.fullUI(isInitialShow: true, distance: distance, angle: angle))
                
            case (.fullUI, .selectSecondaryColor(let color)):
                return .Commands([.selectSecondaryColor(color)])
                
            case (.fullUI, .addNewWall):
                return .State(.readyToPlaceWall)
                
            case (.fullUI, .deleteWall):
                return .Commands([.deleteWall])
                
            case (.fullUI, .showOcclusionWizard):
                return .StateAndCommands(.occlusionWizard, [.showOcclusionWizard])
                
            case (.fullUI, .showLidarOcclusionWizard):
                return .StateAndCommands(.lidarOcclusionWizard, [.showLidarOcclusionWizard])
                
            case (.occlusionWizard, .hideOcclusionWizard):
                return .State(.fullUI(isInitialShow: false, distance: nil, angle: nil))
                
            case (.lidarOcclusionWizard, .hideLidarOcclusionWizard):
                return .State(.fullUI(isInitialShow: false, distance: nil, angle: nil))
                
            case (_, .reset):
                return .StateAndCommands(.tutorial, [.sceneReset])
                
            default:
                return .NoUpdate
            }
        }
    }
}

extension LegacyStateMachine {
    // This contains all possible states for the system.
    enum State: Equatable {
        case tutorial
        case scanning
        case pickingColor
        case colorPicked
        case readyToPlaceWall
        case placingWall(steadyCount: Int, angle: Float)
        case placingFirstCorner(distance: Float?, angle: Float?)
        case placingSecondCorner(distance: Float?, angle: Float?)
        case fullUI(isInitialShow: Bool, distance: Float?, angle: Float?)
        case occlusionWizard
        case lidarOcclusionWizard
        
        var description: String {
            switch self {
            case .tutorial: return "tutorial"
            case .scanning: return "scanning"
            case .pickingColor: return "pickingColor"
            case .colorPicked: return "colorPicked"
            case .readyToPlaceWall: return "readyToPlaceWall"
            case .placingWall: return "placingWall"
            case .placingFirstCorner: return "placingFirstCorner"
            case .placingSecondCorner: return "placingSecondCorner"
            case .fullUI: return "fullUI"
            case .occlusionWizard: return "occlusionWizard"
            case .lidarOcclusionWizard: return "lidarOcclusionWizard"
            }
        }
    }
    
    // These are events that allow the system to interact
    // with the state machine.
    private enum Event {
        case tutorialDone(Bool)
        case scanFinished
        case placeWall
        case deviceAngleUpdated(Float)
        case wallAimInfoUpdated(Float?, Float?)
        case firstCornerSet
        case secondCornerSet
        case selectPrimaryColor(Paint)
        case selectSecondaryColor(Paint)
        case donePickingColor
        case paintFirstWall
        case addNewWall
        case deleteWall
        case reset
        case showOcclusionWizard
        case showLidarOcclusionWizard
        case hideOcclusionWizard
        case hideLidarOcclusionWizard
        
        var description: String {
            switch self {
            case .tutorialDone: return "tutorialDone"
            case .scanFinished: return "scanFinished"
            case .placeWall: return "placeWall"
            case .deviceAngleUpdated: return "deviceAngleUpdated"
            case .wallAimInfoUpdated: return "wallAimInfoUpdated"
            case .firstCornerSet: return "firstCornerSet"
            case .secondCornerSet: return "secondCornerSet"
            case .selectPrimaryColor: return "selectPrimaryColor"
            case .selectSecondaryColor: return "selectSecondaryColor"
            case .donePickingColor: return "donePickingColor"
            case .paintFirstWall: return "paintFirstWall"
            case .addNewWall: return "addNewWall"
            case .deleteWall: return "deleteWall"
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
        case placeWall
        case deleteWall
        case selectSecondaryColor(Paint)
        case sceneReset
        case showOcclusionWizard
        case showLidarOcclusionWizard
    }
}
