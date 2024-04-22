//
// PureStateMachine.swift
//
// Copyright (c) 2018 Robert Brown
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Combine
import Foundation

// Based on Elm architecture and https://gist.github.com/andymatuschak/d5f0a8730ad601bcccae97e8398e25b2

internal final class PureStateMachine<State, Event, Command> {
    public typealias EventHandler = (State, Event) -> StateUpdate<State, Command>

    public var currentState: State {
        state.fetch { $0 }
    }

    @Published var publicState: State
    private let state: Agent<State>
    private let handler: EventHandler
    private var cancellables = Set<AnyCancellable>()

    public convenience init(
        initialState: State,
        label: String = "pro.tricksofthetrade.PureStateMachine",
        handler: @escaping EventHandler
    ) {
        let state = Agent(state: initialState, label: label)
        self.init(state: state, handler: handler)
    }

    public convenience init(initialState: State, queue: DispatchQueue, handler: @escaping EventHandler) {
        let state = Agent(state: initialState, queue: queue)
        self.init(state: state, handler: handler)
    }

    private init(state: Agent<State>, handler: @escaping EventHandler) {
        self.state = state
        self.publicState = state.publicState
        self.handler = handler

        state.$publicState
            .sink { [weak self] newState in
                self?.publicState = newState
            }
            .store(in: &cancellables)
    }

    public func handleEvent(_ event: Event) -> [Command] {
        let commands: [Command] = state.fetchAndUpdate { currentState in
            let stateUpdate = self.handler(currentState, event)
            switch stateUpdate {
            case .NoUpdate:
                return ([], currentState)

            case let .State(updatedState):
                return ([], updatedState)

            case let .Commands(commands):
                return (commands, currentState)

            case let .StateAndCommands(updatedState, commands):
                return (commands, updatedState)
            }
        }
        return commands
    }
}

internal enum StateUpdate<State, Command> {
    case NoUpdate
    case State(State)
    case Commands([Command])
    case StateAndCommands(State, [Command])

    public var state: State? {
        switch self {
        case .NoUpdate, .Commands:            return nil
        case let .State(state):               return state
        case let .StateAndCommands(state, _): return state
        }
    }

    public var commands: [Command] {
        switch self {
        case .NoUpdate, .State:                  return []
        case let .Commands(commands):            return commands
        case let .StateAndCommands(_, commands): return commands
        }
    }

    public func mapState<T>(_ closure: (State) -> T) -> StateUpdate<T, Command> {
        switch self {
        case .NoUpdate:
            return .NoUpdate

        case let .Commands(commands):
            return .Commands(commands)

        case let .State(state):
            return .State(closure(state))

        case let .StateAndCommands(state, commands):
            return .StateAndCommands(closure(state), commands)
        }
    }

    public func mapCommands<T>(_ closure: (Command) -> T) -> StateUpdate<State, T> {
        switch self {
        case .NoUpdate:
            return .NoUpdate

        case let .Commands(commands):
            return .Commands(commands.map(closure))

        case let .State(state):
            return .State(state)

        case let .StateAndCommands(state, commands):
            return .StateAndCommands(state, commands.map(closure))
        }
    }
}
