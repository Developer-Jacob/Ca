//
//  CarrotRepositoryTests.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import XCTest
@testable import Carrot

final class RepositoryTests: XCTestCase {
    func test_레포지토리_검색_페이지_데이터() async throws {
        let dataSource = MockBookDataSource()
        let json = sampleSearchJSONData()
        dataSource.enqueue(json: json, endpoint: .search(query: "swift", page: 1))
        
        let repository = DefaultBookRepository(dataSource: dataSource)
        let page = try await repository.searchBooks(query: "swift", page: 1)
        
        XCTAssertEqual(page.totalPages, 1)
        
        XCTAssertEqual(page.books.first?.title, "Swift Handbook")
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertEqual(dataSource.lastEndpointPath, "/1.0/search/swift/1")
    }
    
    func test_레포지토리_검색_페이지_페이징() async throws {
        let dataSource = MockBookDataSource()
        let json = sampleSearchJSONData()
        dataSource.enqueue(json: json, endpoint: .search(query: "swift", page: 2))
        
        let repository = DefaultBookRepository(dataSource: dataSource)
        
        let page2 = try await repository.searchBooks(query: "swift", page: 2)
        XCTAssertEqual(page2.totalPages, 1)
        XCTAssertEqual(page2.totalResults, 1)
        XCTAssertEqual(page2.canLoadMore, false)
        XCTAssertEqual(page2.currentPage, 1)
    }
}
