//
//  SearchBooksUseCase.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

protocol SearchBooksUseCase {
    func execute(query: String, page: Int) async throws -> SearchPage
}

struct DefaultSearchBooksUseCase: SearchBooksUseCase {
    private let bookRepository: BookRepository
    
    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }
    
    func execute(query: String, page: Int) async throws -> SearchPage {
        try await bookRepository.searchBooks(query: query, page: page)
    }
}
