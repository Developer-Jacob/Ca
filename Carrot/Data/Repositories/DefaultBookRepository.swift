//
//  DefaultBookRepository.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

final class DefaultBookRepository: BookRepository {
    private let dataSource: BookDataSource
    
    init(dataSource: BookDataSource) {
        self.dataSource = dataSource
    }
    
    func searchBooks(query: String, page: Int) async throws -> SearchPage {
        let dto: SearchResponseDTO = try await dataSource.perform(.search(query: query, page: page))
        guard dto.error == "0" else {
            throw APIError.server("검색 API 에러, ErrorCode: \(dto.error)")
        }
        return dto.toDomain()
    }
    
    func fetchDetail(id: String) async throws -> BookDetail {
        let dto: BookDetailDTO = try await dataSource.perform(.detail(id: id))
        
        guard dto.error == "0" else {
            throw APIError.server("검색 API 에러, ErrorCode: \(dto.error)")
        }
        return dto.toDomain()
    }
}
