//
//  ImageRemoteProvider.swift
//  Carrot
//
//  Created by Jacob on 11/11/25.
//

import Foundation

protocol ImageRemoteProvider {
    func fetchData(from url: URL) async throws -> Data
}

struct DefaultImageRemoteProvider: ImageRemoteProvider {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        return data
    }
}
