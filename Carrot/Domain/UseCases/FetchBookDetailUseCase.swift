//
//  FetchBookDetailUseCase.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

protocol FetchBookDetailUseCase {
    func execute(id: String) async throws -> BookDetail
}

struct DefaultFetchBookDetailUseCase: FetchBookDetailUseCase {
    private let bookRepository: BookRepository

    init(bookRepository: BookRepository) {
        self.bookRepository = bookRepository
    }

    func execute(id: String) async throws -> BookDetail {
        try await bookRepository.fetchDetail(id: id)
    }
}
