//
//  FetchBookDetailUseCase.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

protocol FetchBookDetailUseCase {
    func execute(id: String) async throws -> BookDetail
}

struct DefaultFetchBookDetailUseCase {
    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    func execute(id: String) async throws -> BookDetail {
        try await repository.fetchDetail(id: id)
    }
}
