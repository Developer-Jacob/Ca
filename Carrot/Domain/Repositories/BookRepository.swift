//
//  BookRepository.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

protocol BookRepository {
    func searchBooks(query: String, page: Int) async throws -> SearchPage
    func fetchDetail(id: String) async throws -> BookDetail
}
