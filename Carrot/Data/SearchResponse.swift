//
//  SearchResponse.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import Foundation

struct SearchResponse: Decodable {
    let error: String
    let total: String
    let page: String
    let books: [BookResponse]
}

struct BookResponse: Decodable {
    let title: String
    let subtitle: String
    let isbn13: String
    let price: String
    let image: String
    let url: String
    
    func toEntity() -> Book {
        Book(
            title: title,
            subtitle: subtitle,
            isbn13: isbn13,
            price: price,
            image: image,
            url: url
        )
    }
}
