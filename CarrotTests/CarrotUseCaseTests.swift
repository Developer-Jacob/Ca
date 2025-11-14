//
//  CarrotUseCaseTests.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import XCTest
@testable import Carrot

final class UseCaseTests: XCTestCase {
    func test_searchBookUseCase() async throws {
        let repository = MockBookRepository()
        repository.searchResult = SearchPage(
            books: [
                BookSummary(
                    title: "Swift",
                    subtitle: "Guide",
                    isbn13: "1",
                    price: "$0",
                    imageURL: nil,
                    storeURL: nil
                )
            ],
            totalResults: 1,
            currentPage: 1,
            totalPages: 1
        )
        let useCase = DefaultSearchBooksUseCase(bookRepository: repository)

        let page = try await useCase.execute(query: "swift", page: 2)

        XCTAssertEqual(page.books.count, 1)
        XCTAssertEqual(repository.lastSearch?.query, "swift")
        XCTAssertEqual(repository.lastSearch?.page, 2)
    }
    
    func test_fetchBookDetailUseCase() async throws {
        let repository = MockBookRepository()
        repository.detailResult = BookDetail(
            title: "Swift",
            subtitle: "Guide",
            authors: "Apple",
            publisher: "Apple",
            language: "en",
            isbn10: "123",
            isbn13: "456",
            pages: "200",
            year: "2024",
            rating: "5",
            description: "Desc",
            price: "$0",
            imageURL: nil,
            storeURL: nil,
            pdfs: []
        )
        let useCase = DefaultFetchBookDetailUseCase(bookRepository: repository)

        let detail = try await useCase.execute(id: "456")

        XCTAssertEqual(detail.isbn13, "456")
        XCTAssertEqual(repository.lastDetailISBN, "456")
    }
}
