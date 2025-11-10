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
        guard let searchResult else { throw APIError.server("missing") }
        return searchResult
    }

    func fetchDetail(id: String) async throws -> BookDetail {
        lastDetailISBN = id
        if let error = detailError { throw error }
        guard let detailResult else { throw APIError.server("missing") }
        return detailResult
    }
}
