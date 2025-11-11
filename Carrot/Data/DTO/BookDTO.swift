//
//  BookDTO.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

struct SearchResponseDTO: Decodable {
    let error: String
    let total: String
    let page: String
    let books: [BookSummaryDTO]
}

struct BookSummaryDTO: Decodable {
    let title: String
    let subtitle: String
    let isbn13: String
    let price: String
    let image: String
    let url: String
}

struct BookDetailDTO: Decodable {
    let error: String
    let title: String
    let subtitle: String
    let authors: String
    let publisher: String
    let language: String
    let isbn10: String
    let isbn13: String
    let pages: String
    let year: String
    let rating: String
    let desc: String
    let price: String
    let image: String
    let url: String
    let pdf: [String: String]?
}

extension BookSummaryDTO {
    func toDomain() -> BookSummary {
        BookSummary(
            title: title,
            subtitle: subtitle,
            isbn13: isbn13,
            price: price,
            imageURL: URL(string: image),
            storeURL: URL(string: url)
        )
    }
}

extension SearchResponseDTO {
    func toDomain() -> SearchPage {
        let totalResults = Int(total) ?? 0
        let currentPage = Int(page) ?? 1
        let pageSize = books.isEmpty ? 1 : books.count
        let totalPages: Int
        if totalResults == 0 {
            totalPages = currentPage
        } else {
            let derived = Double(totalResults) / Double(pageSize)
            totalPages = max(Int(ceil(derived)), currentPage)
        }
        return SearchPage(
            books: books.map { $0.toDomain() },
            totalResults: totalResults,
            currentPage: currentPage,
            totalPages: max(totalPages, currentPage)
        )
    }
}

extension BookDetailDTO {
    func toDomain() -> BookDetail {
        let pdfResources = (pdf ?? [:])
            .compactMap { (title, value) -> BookDetail.PDFResource? in
                guard let url = URL(string: value) else { return nil }
                return .init(title: title, url: url)
            }
            .sorted { $0.title < $1.title }

        return BookDetail(
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            language: language,
            isbn10: isbn10,
            isbn13: isbn13,
            pages: pages,
            year: year,
            rating: rating,
            description: desc,
            price: price,
            imageURL: URL(string: image),
            storeURL: URL(string: url),
            pdfs: pdfResources
        )
    }
}
