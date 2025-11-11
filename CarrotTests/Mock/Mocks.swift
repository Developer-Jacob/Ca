//
//  Mocks.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import XCTest
@testable import Carrot

final class MockBookRepository: BookRepository {
    var searchResult: SearchPage?
    var detailResult: BookDetail?
    var searchError: Error?
    var detailError: Error?
    private(set) var lastSearch: (query: String, page: Int)?
    private(set) var lastDetailISBN: String?

    func searchBooks(query: String, page: Int) async throws -> SearchPage {
        lastSearch = (query, page)
        if let error = searchError { throw error }
        guard let searchResult else { throw APIError.server("검색결과 없음") }
        return searchResult
    }

    func fetchDetail(id: String) async throws -> BookDetail {
        lastDetailISBN = id
        if let error = detailError { throw error }
        guard let detailResult else { throw APIError.server("상세결과 없음") }
        return detailResult
    }
}

final class MockBookDataSource: BookDataSource {
    private var responses: [String: Data] = [:]
    private(set) var lastEndpointPath: String?

    func enqueue(json: Data, endpoint: ItBookAPI) {
        let key = endpoint.requestURL?.absoluteString ?? UUID().uuidString
        responses[key] = json
    }

    func perform<T: Decodable>(_ endpoint: ItBookAPI) async throws -> T {
        guard let url = endpoint.requestURL else { throw APIError.invalidResponse }
        lastEndpointPath = url.path
        print(url.absoluteString)
        print(responses)
        guard let data = responses[url.absoluteString] else {
            throw APIError.server("에러")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

func sampleSearchJSONData() -> Data {
    let json: [String: Any] = [
        "error": "0",
        "total": "1",
        "page": "1",
        "books": [[
            "title": "Swift Handbook",
            "subtitle": "Best Practices",
            "isbn13": "9781234567890",
            "price": "$0",
            "image": "https://example.com/cover.png",
            "url": "https://example.com/book"
        ]]
    ]
    return try! JSONSerialization.data(withJSONObject: json)
}

func sampleDetailJSONData() -> Data {
    let json: [String: Any] = [
        "error": "0",
        "title": "Swift Handbook",
        "subtitle": "Best Practices",
        "authors": "Apple",
        "publisher": "Apple Books",
        "language": "en",
        "isbn10": "1234567890",
        "isbn13": "9781234567890",
        "pages": "250",
        "year": "2024",
        "rating": "5",
        "desc": "Guide",
        "price": "$0",
        "image": "https://example.com/cover.png",
        "url": "https://example.com/book",
        "pdf": ["Preview": "https://example.com/sample.pdf"]
    ]
    return try! JSONSerialization.data(withJSONObject: json)
}
