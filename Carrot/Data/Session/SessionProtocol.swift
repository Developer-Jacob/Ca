//
//  SessionProtocol.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

protocol SessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: SessionProtocol {}
