//
//  BookDetail.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

struct BookSummary: Equatable, Hashable {
    let title: String
    let subtitle: String
    let isbn13: String
    let price: String
    let imageURL: URL?
    let storeURL: URL?
}

struct SearchPage: Equatable {
    let books: [BookSummary]
    let totalResults: Int
    let currentPage: Int
    let totalPages: Int

    var canLoadMore: Bool {
        currentPage < totalPages
    }
}

struct BookDetail: Equatable {
    struct PDFResource: Equatable, Hashable {
        let title: String
        let url: URL
    }

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
    let description: String
    let price: String
    let imageURL: URL?
    let storeURL: URL?
    let pdfs: [PDFResource]
}
