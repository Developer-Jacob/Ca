//
//  BaseAPI.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

protocol BaseAPI {
    var baseURL: String { get }
    var path: String { get }
    var method: Method { get }
    var parameters: [String: String]? { get }
}

extension BaseAPI {
    private var requestURL: URL? {
        guard let base = URL(string: baseURL) else { return nil }

        var components = URLComponents(
            url: base.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        if let parameters, !parameters.isEmpty {
            components?.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        return components?.url
    }
    
    var urlRequest: URLRequest? {
        guard let url = requestURL else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue   // GET, POST 등
        request.timeoutInterval = 20
        return request
    }
}

enum Method: String {
    case get = "GET"
}
