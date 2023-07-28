//
//  ContentComponent.swift
//  DeclarativeEffectsExample
//
//  Created by Fabian Mücke on 27.07.23.
//

import ComposableArchitecture
import DeclarativeEffects
import Foundation

enum CatsFeature {
    struct State: Equatable, SimpleRequestsProtocol {
        typealias Request = CatsFeature.Request

        var parameters: CatAPI.SearchParameters = .init()
        var images: Images?
        var error: Error?

        struct Images: Equatable {
            var images: [CatImage]?
            var parameters: CatAPI.SearchParameters
        }

        var requests: Set<Request> {
            guard parameters != images?.parameters else {
                return []
            }
            return [.searchImages(parameters)]
        }

        var isLoading: Bool {
            !requests.isEmpty
        }

        struct Error: Equatable {
            let message: String
            let parameters: CatAPI.SearchParameters
        }
    }

    enum Action {
        case start
        case didLoadImages(Result<[CatImage]?, Error>, for: CatAPI.SearchParameters)
        case filter(by: Breed.Id?)
    }

    enum Request: Hashable, Identifiable {
        var id: Self { self }

        case searchImages(CatAPI.SearchParameters)
    }

    static func reduce(state: inout State, action: Action) {
        switch action {
        case .start:
            break // only exists to get initial effects running
        case let .didLoadImages(.success(images), for: parameters):
            state.images = .init(images: images, parameters: parameters)
        case let .didLoadImages(.failure(error), for: parameters):
            state.error = .init(message: "\(error.localizedDescription)", parameters: parameters)
        case let .filter(by: .some(breedId)):
            state.parameters.breeds = [breedId]
        case .filter(by: .none):
            state.parameters.breeds = nil
        }
    }
}

extension CatsFeature {
    struct EffectHandler {
        let api: CatAPIProtocol

        func handleEffect(for request: Request) -> EffectTask<Action> {
            switch request {
            case let .searchImages(parameters):
                return .run { send in
                    do {
                        print("searching: \(parameters)")
                        let result = try await api.searchImages(parameters: parameters)
                        print("found: \(result ?? [])\nfor: \(parameters)")
                        await send.callAsFunction(.didLoadImages(.success(result), for: parameters))
                    } catch {
                        print("got error: \(error)\nfor: \(parameters)")
                        await send.callAsFunction(.didLoadImages(.failure(error), for: parameters))
                    }
                }
            }
        }
    }
}
