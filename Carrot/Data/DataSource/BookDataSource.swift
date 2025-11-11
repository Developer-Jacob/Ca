//
//  BookDataSource.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

protocol BookDataSource {
    func perform<T: Decodable>(_ endpoint: ItBookAPI) async throws -> T
}

struct DefaultBookDataSource: BookDataSource {
    private let urlSession: SessionProtocol
    
    init(urlSession: SessionProtocol) {
        self.urlSession = urlSession
    }
    
    func perform<T: Decodable>(_ endpoint: ItBookAPI) async throws -> T {
        return 0 as! T
    }
}
