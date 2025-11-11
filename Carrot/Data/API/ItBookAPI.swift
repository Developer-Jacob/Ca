//
//  ItBookAPI.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

enum ItBookAPI: BaseAPI {
    case search(query: String, page: Int)
    case detail(id: String)
    
    var baseURL: String { "https://api.itbook.store/1.0" }
    var parameters: [String: String]? { nil }
    
    var method: Method { .get }
    
    var path: String {
        switch self {
        case .search(query: let query, page: let page):
            return "search/\(query)/\(page)"
        case .detail(id: let id):
            return "books/\(id)"
        }
    }
}
