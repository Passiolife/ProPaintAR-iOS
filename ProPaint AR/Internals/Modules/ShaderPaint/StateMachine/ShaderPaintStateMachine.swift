//
//  ShaderPaintStateMachine.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/29/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class ShaderPaintStateMachine {
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
    public var selectedSecondaryColor: ((Paint) -> Void)?
    public var sceneReset: (() -> Void)?

    init() {
        self.stateMachine = ShaderPaintStateMachine.createStateMachine()
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
    
    public func selectPrimaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectPrimaryColor")
        fire(event: .selectPrimaryColor(color))
    }
    
    public func selectSecondaryColor(color: Paint) {
        Self.debugLog(message: "\(description): event:selectSecondaryColor")
        fire(event: .selectSecondaryColor(color))
    }
    
    public func reset() {
        Self.debugLog(message: "\(description): event:reset")
        fire(event: .reset)
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
            
        case .selectSecondaryColor(let color):
            selectedSecondaryColor?(color)
            
        case .sceneReset:
            sceneReset?()
        }
    }

    // This creates the state machine and also defines all the behaviors
    // for the different state/event combinations of the state machine.
    private static func createStateMachine() -> PureStateMachine<State, Event, Command> {
        PureStateMachine(initialState: .tutorial) { state, event in
            Self.debugLog(message: "\(Self.description): state: \(state.description), event: \(event.description)")
            switch (state, event) {
            case (.tutorial, .tutorialDone):
                return .State(.pickingColor)
                
            case (.pickingColor, .selectSecondaryColor(let color)):
                return .StateAndCommands(.fullUI, [.selectSecondaryColor(color)])
                
            case (.fullUI, .selectSecondaryColor(let color)):
                return .Commands([.selectSecondaryColor(color)])
                
            case (_, .reset):
                return .StateAndCommands(.pickingColor, [.sceneReset])
                
            default:
                return .NoUpdate
            }
        }
    }
}

extension ShaderPaintStateMachine {
    // This contains all possible states for the system.
    enum State: Equatable {
        case tutorial
        case pickingColor
        case fullUI
        
        var description: String {
            switch self {
            case .tutorial: return "tutorial"
            case .pickingColor: return "pickingColor"
            case .fullUI: return "fullUI"
            }
        }
    }
    
    // These are events that allow the system to interact
    // with the state machine.
    private enum Event {
        case tutorialDone
        case selectPrimaryColor(Paint)
        case selectSecondaryColor(Paint)
        case reset
        
        var description: String {
            switch self {
            case .tutorialDone: return "tutorialDone"
            case .selectPrimaryColor: return "selectPrimaryColor"
            case .selectSecondaryColor: return "selectSecondaryColor"
            case .reset: return "reset"
            }
        }
    }
    
    // Command contains all of the commands for the state machine to
    // interact with the system.
    private enum Command {
        case noOp
        case selectSecondaryColor(Paint)
        case sceneReset
    }
}
