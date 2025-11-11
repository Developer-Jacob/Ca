//
//  BookDataSource.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

protocol BookDataSource {
    func perform<T: Decodable>(_ endpoint: ItBookAPI) async throws -> T
}

struct DefaultBookDataSource: BookDataSource {
    private let urlSession: SessionProtocol
    private let cache: URLCache
    private let cachePolicy: CachePolicy
    private let decoder: JSONDecoder = JSONDecoder()
    
    init(urlSession: SessionProtocol, cache: URLCache = .shared, cachePolicy: CachePolicy = .serverDriven) {
        self.urlSession = urlSession
        self.cache = cache
        self.cachePolicy = cachePolicy
    }
    
    func perform<T: Decodable>(_ endpoint: ItBookAPI) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIError.invalidRequest
        }
        
        let performer: CacheRequestPerforming = switch cachePolicy {
        case .serverDriven: ServerDrivenRequestPerformer()
        case let .clientDriven(clientPolicy):
            switch clientPolicy {
            case .cacheFirst: CacheFirstRequestPerformer()
            case .networkFirst: NetworkFirstRequestPerformer()
            }
        }
        let data = try await performer
            .request(request, session: urlSession, cache: cache)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
