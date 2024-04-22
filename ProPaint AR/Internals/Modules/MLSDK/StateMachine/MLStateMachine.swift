//
//  MLStateMachine.swift
//  Remodel-AR WL
//
//  Created by Davido Hyer on 8/25/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Combine
import Foundation
import UIKit

class MLStateMachine {
    @Published var statePublisher: State
    private var state: State {
        stateMachine.currentState
    }

    private static let debugEnabled = false
    private let stateMachine: PureStateMachine<State, Event, Command>
    private var cancellables = Set<AnyCancellable>()
    private static var description: String { String(describing: Self.self) }
    private var description: String { String(describing: Self.self) }
    
    init() {
        self.stateMachine = MLStateMachine.createStateMachine()
        statePublisher = self.stateMachine.publicState

        self.stateMachine.$publicState
            .sink { [weak self] newState in
                self?.statePublisher = newState
            }
            .store(in: &cancellables)
    }

    // These public functions are how the system
    // interacts with the state machine

    public func phoneStilled() {
        Self.debugLog(message: "\(description): event:phoneStilled")
        fire(event: .phoneStilled)
    }
    
    public func phoneMoving() {
        Self.debugLog(message: "\(description): event:phoneMoving")
        fire(event: .phoneMoving)
    }
    
    public func scanSuccess(result: MLDisplayModel) {
        Self.debugLog(message: "\(description): event:scanSuccess")
        fire(event: .scanSuccess(result, Date()))
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
        }
    }

    // This creates the state machine and also defines all the behaviors
    // for the different state/event combinations of the state machine.
    private static func createStateMachine() -> PureStateMachine<State, Event, Command> {
        PureStateMachine(initialState: .scanningNoResult) { state, event in
            Self.debugLog(message: "\(Self.description): state: \(state), event: \(event.description)")
            switch (state, event) {
            case (.scanningNoResult, .phoneMoving):
                return .State(.phoneMoving(nil, nil))
                
            case let (.phoneMoving(model, date), .phoneMoving):
                return .State(.phoneMoving(model, date))
                
            case let (.phoneMoving(model, date), .phoneStilled):
                if let model = model,
                   let date = date,
                   Date().timeIntervalSince(date) < 2 {
                    return .State(.scanningResult(model, date))
                } else {
                    return .State(.scanningNoResult)
                }
                
            case let (.scanningNoResult, .scanSuccess(model, date)):
                return .State(.scanningResult(model, date))
                
            case let (.scanningResult(model, date), .phoneMoving):
                return .State(.phoneMoving(model, date))
                
            case let (.scanningResult, .scanSuccess(model, date)):
                return .State(.scanningResult(model, date))
                
            default:
                return .NoUpdate
            }
        }
    }
}

extension MLStateMachine {
    // This contains all possible states for the system.
    enum State {
        case scanningNoResult
        case scanningResult(MLDisplayModel, Date)
        case phoneMoving(MLDisplayModel?, Date?)
        
        var description: String {
            switch self {
            case .scanningNoResult:
                return "scanningNoResult"
            case .scanningResult:
                return "scanningResult"
            case .phoneMoving:
                return "phoneMoving"
            }
        }
    }
    
    // These are events that allow the system to interact
    // with the state machine.
    private enum Event {
        case phoneStilled
        case phoneMoving
        case scanSuccess(MLDisplayModel, Date)
        
        var description: String {
            switch self {
            case .phoneStilled: return "phoneStilled"
            case .phoneMoving: return "phoneMoving"
            case .scanSuccess: return "scanSuccess"
            }
        }
    }
    
    // Command contains all of the commands for the state machine to
    // interact with the system.
    private enum Command {
        case noOp
    }
}
