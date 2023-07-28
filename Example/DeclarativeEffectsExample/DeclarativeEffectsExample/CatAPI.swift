//
//  CatAPI.swift
//  DeclarativeEffectsExample
//
//  Created by Fabian Mücke on 27.07.23.
//

import Foundation

protocol CatAPIProtocol {
    func searchImages(parameters: CatAPI.SearchParameters) async throws -> [CatImage]?
}

struct MockCatAPI: CatAPIProtocol {
    func searchImages(parameters: CatAPI.SearchParameters) async throws -> [CatImage]? {
        []
    }
}

struct CatAPI: CatAPIProtocol {
    enum Error: Swift.Error {
        case invalidResponse
        case decodingError(Swift.Error)
        case networkError(Swift.Error)
        case badStatus(Int)
    }

    private static let baseURL = URL(string: "https://api.thecatapi.com")!
    private static let v1URL = baseURL.appending(path: "v1")

    struct SearchParameters: Hashable {
        var breeds: [Breed.Id]?
        var size: CatImage.Size?
        var mimeTypes: Set<CatImage.MimeType>?
        var limit = 10

        var queryItems: [URLQueryItem] {
            var result: [URLQueryItem] = [
                .init(name: "limit", value: "\(limit)"),
                .init(name: "has_breeds", value: "1")
            ]
            if let breeds {
                result.append(.init(name: "breed_ids", value: breeds.map(\.rawValue).joined(separator: ",")))
            }
            if let size {
                result.append(.init(name: "size", value: size.rawValue))
            }
            if let mimeTypes {
                result.append(.init(name: "mime_types", value: mimeTypes.map(\.rawValue).joined(separator: ",")))
            }
            return result
        }
    }

    func searchImages(parameters: SearchParameters) async throws -> [CatImage]? {
        var url = Self.v1URL.appending(path: "images/search")
        url.append(queryItems: parameters.queryItems)
        var request = URLRequest(url: url)
        request.setValue(DeclarativeEffectsExampleKeys.CatAPIKey, forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        switch response.statusCode {
        case 200 ..< 300:
            break
        case 404:
            return nil
        default:
            throw Error.badStatus(response.statusCode)
        }

        do {
            return try JSONDecoder().decode([CatImage].self, from: data)
        } catch {
            throw Error.decodingError(error)
        }
    }
}
