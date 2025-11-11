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
    var requestURL: URL? {
        guard let parameters else {
            return URL(string: "\(baseURL)/\(path)")
        }
        
        var components = URLComponents(string: baseURL)
        components?.path = path
        
        components?.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        return components?.url
    }
}

enum Method {
    case get
}
