//
//  RequestsProtocol.swift
//
//
//  Created by Fabian Mücke on 21.07.23.
//

import Combine
import ComposableArchitecture
import Foundation

public protocol RequestsProtocol where Request: Equatable {
    associatedtype Request: Identifiable
    var requestsByIDs: [Request.ID: Request] { get }
}

public extension DeclarativeEffectsReducer where State: RequestsProtocol, State.Request == Request {
    convenience init(
        reduce: @escaping (inout State, Action) -> Void,
        effectHandler: @escaping (Request, AnyPublisher<Request, Never>) -> EffectTask<Action>
    ) {
        self.init(
            reduce: reduce,
            effects: { $0.requestsByIDs },
            effectHandler: effectHandler
        )
    }
}

public protocol SimpleRequestsProtocol: RequestsProtocol where Request.ID == Request {
    var requests: Set<Request> { get }
}

public extension SimpleRequestsProtocol {
    var requestsByIDs: [Request.ID: Request] { requests.elementsByIDs }
}

public extension SimpleDeclarativeEffectsReducerProtocol where State: SimpleRequestsProtocol, State.Request == Request {
    static func effects(for state: State) -> Set<Request> {
        state.requests
    }
}

public extension DeclarativeEffectsReducer where State: SimpleRequestsProtocol, State.Request == Request {
    convenience init(
        reduce: @escaping (inout State, Action) -> Void,
        effectHandler: @escaping (Request) -> EffectTask<Action>
    ) {
        self.init(
            reduce: reduce,
            effects: { $0.requestsByIDs },
            effectHandler: { request, _ in effectHandler(request) }
        )
    }
}

public protocol SingleRequestProtocol: RequestsProtocol where Request.ID == Request {
    var request: Request? { get }
}

public extension SingleRequestProtocol {
    var requestsByIDs: [Request.ID: Request] {
        request.dictionary
    }
}

public extension DeclarativeEffectsReducer where State: SingleRequestProtocol, State.Request == Request {
    convenience init(
        reduce: @escaping (inout State, Action) -> Void,
        effectHandler: @escaping (Request) -> EffectTask<Action>
    ) {
        self.init(
            reduce: reduce,
            effects: { $0.requestsByIDs },
            effectHandler: { request, _ in effectHandler(request) }
        )
    }
}

extension Set where Element: Identifiable {
    var elementsByIDs: [Element.ID: Element] {
        Dictionary(uniqueKeysWithValues: map { (key: $0.id, value: $0) })
    }
}

extension Optional where Wrapped: Identifiable {
    var dictionary: [Wrapped.ID: Wrapped] {
        map { [$0.id: $0] } ?? [:]
    }
}
