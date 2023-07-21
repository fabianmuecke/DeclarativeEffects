//
//  DeclarativeEffectsReducer.swift
//
//
//  Created by Fabian Mücke on 21.07.23.
//

import Combine
import ComposableArchitecture

/// A ``ReducerProtocol`` type to declare effects using ``State`` rather than ``Action``.
///
/// Provide a closure from ``State`` to ``[Request.ID: Request]`` to declare which effects should be running.
///
/// On each state change the closure will be called and new effects started and existing requests updated or stopped, if necessary.
public final class DeclarativeEffectsReducer<State: Equatable, Action, Request: Identifiable>: ReducerProtocol where Request: Equatable {
    private var currentRequests: [Request.ID: CurrentValueSubject<Request, Never>] = [:]

    private let reducer: (inout State, Action) -> Void
    private let effects: (State) -> [Request.ID: Request]
    private let effectHandler: (Request, AnyPublisher<Request, Never>) -> EffectTask<Action>

    /// Initializes a new ``DeclarativeEffectsReducer`` instance.
    ///
    /// - Parameters:
    ///   - reduce: A closure to apply changes to ``State``, each time an ``Action`` is received.
    ///   - effects: A closure to declare which effects should be running. Will be called after each ``reduce`` call.
    ///   - effectHandler: A closure to handle ``Request``s and start or update according ``EffectTask``s.
    public init(
        reduce: @escaping (inout State, Action) -> Void,
        effects: @escaping (State) -> [Request.ID: Request],
        effectHandler: @escaping (Request, AnyPublisher<Request, Never>) -> EffectTask<Action>
    ) {
        self.reducer = reduce
        self.effects = effects
        self.effectHandler = effectHandler
    }

    private enum RequestAction {
        case cancel(Request.ID)
        case start(CurrentValueSubject<Request, Never>)
        case update(CurrentValueSubject<Request, Never>, with: Request)
        case keepAlive(CurrentValueSubject<Request, Never>)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        reducer(&state, action)
        let requests = effects(state)

        let currentRequestsKeys = Set(currentRequests.keys)
        let requestsKeys = Set(requests.keys)
        var requestActions = currentRequestsKeys.subtracting(requestsKeys).map(RequestAction.cancel)
        requestActions += requests.map { key, request -> RequestAction in
            guard let currentRequest = currentRequests[key] else {
                return .start(CurrentValueSubject(request))
            }
            return currentRequest.value == request ? .keepAlive(currentRequest) : .update(currentRequest, with: request)
        }

        currentRequests = Dictionary(
            uniqueKeysWithValues: requestActions.compactMap { action -> (Request.ID, CurrentValueSubject<Request, Never>)? in
                switch action {
                case .cancel:
                    return nil
                case let .start(subject),
                     let .update(subject, with: _),
                     let .keepAlive(subject):
                    return (subject.value.id, subject)
                }
            }
        )

        return requestActions.reduce(EffectTask<Action>.none) { effects, action in
            switch action {
            case let .cancel(id):
                return effects.merge(with: .cancel(id: id))
            case let .start(subject):
                return effects.merge(with: effectHandler(subject.value, subject.eraseToAnyPublisher()).cancellable(id: subject.value.id))
            case let .update(subject, with: request):
                return effects.merge(with: .run { _ in subject.send(request) })
            case .keepAlive:
                return effects
            }
        }
    }
}

public extension DeclarativeEffectsReducer where Request.ID == Request {
    /// Convenience initializer for ease of use, if the ``Request`` does not need to be updated using an `ID`.
    convenience init(
        reduce: @escaping (inout State, Action) -> Void,
        effects: @escaping (State) -> Set<Request>,
        effectHandler: @escaping (Request) -> EffectTask<Action>
    ) {
        self.init(
            reduce: reduce,
            effects: { state in effects(state).elementsByIDs },
            effectHandler: { request, _ in effectHandler(request) }
        )
    }
}

public extension DeclarativeEffectsReducer where Request.ID == Request {
    /// Convenience initializer for ease of use, if the ``Request`` does not need to be updated using an `ID`.
    convenience init(
        reduce: @escaping (inout State, Action) -> Void,
        effects: @escaping (State) -> Request?,
        effectHandler: @escaping (Request) -> EffectTask<Action>
    ) {
        self.init(
            reduce: reduce,
            effects: { state in effects(state).dictionary },
            effectHandler: { request, _ in effectHandler(request) }
        )
    }
}
