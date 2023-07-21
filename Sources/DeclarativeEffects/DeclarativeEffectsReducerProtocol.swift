//
//  DeclarativeEffectsReducerProtocol.swift
//
//
//  Created by Fabian Mücke on 21.07.23.
//

import Combine
import ComposableArchitecture
import Foundation

public protocol DeclarativeEffectsReducerProtocol where Request: Equatable {
    associatedtype State: Equatable
    associatedtype Action
    associatedtype Request: Identifiable

    static func reduce(state: inout State, action: Action)
    static func effects(for state: State) -> [Request.ID: Request]
    static func handleEffect(for initialRequest: Request, updates: AnyPublisher<Request, Never>) -> EffectTask<Action>
}

public extension DeclarativeEffectsReducer {
    convenience init<Declaration: DeclarativeEffectsReducerProtocol>(_ declaration: Declaration.Type)
        where Declaration.State == State,
        Declaration.Action == Action,
        Declaration.Request == Request {
        self.init(
            reduce: declaration.reduce(state:action:),
            effects: declaration.effects(for:),
            effectHandler: declaration.handleEffect(for:updates:)
        )
    }
}

public protocol SimpleDeclarativeEffectsReducerProtocol: DeclarativeEffectsReducerProtocol where Request.ID == Request {
    static func effects(for state: State) -> Set<Request>
    static func handleEffect(for request: Request) -> EffectTask<Action>
}

public extension SimpleDeclarativeEffectsReducerProtocol {
    static func effects(for state: State) -> [Request.ID: Request] {
        effects(for: state).elementsByIDs
    }

    static func handleEffect(for initialRequest: Request, updates: AnyPublisher<Request, Never>) -> EffectTask<Action> {
        handleEffect(for: initialRequest)
    }
}

public protocol SingleDeclarativeEffectReducerProtocol: DeclarativeEffectsReducerProtocol where Request.ID == Request {
    static func effect(for state: State) -> Request?
    static func handleEffect(for request: Request) -> EffectTask<Action>
}

public extension SingleDeclarativeEffectReducerProtocol {
    static func effects(for state: State) -> [Request.ID: Request] {
        effect(for: state).dictionary
    }

    static func handleEffect(for initialRequest: Request, updates: AnyPublisher<Request, Never>) -> EffectTask<Action> {
        handleEffect(for: initialRequest)
    }
}
