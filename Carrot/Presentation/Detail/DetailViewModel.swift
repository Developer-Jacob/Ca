//
//  DetailViewModel.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import Foundation

@MainActor
final class BookDetailViewModel {
    struct PDFItem: Hashable {
        let title: String
        let url: URL
    }

    struct State: Equatable {
        var isLoading: Bool = false
        var errorMessage: String?
        var title: String = ""
        var subtitle: String = ""
        var authors: String = ""
        var publisher: String = ""
        var language: String = ""
        var isbn10: String = ""
        var isbn13: String = ""
        var pages: String = ""
        var year: String = ""
        var rating: String = ""
        var description: String = ""
        var price: String = ""
        var storeURL: URL?
        var imageURL: URL?
        var pdfItems: [PDFItem] = []
    }

    private let isbn13: String
    private let fetchUseCase: FetchBookDetailUseCase
    private var state = State() {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?
    var onOpenPDF: ((URL) -> Void)?
    var currentState: State { state }

    init(isbn13: String, fetchUseCase: FetchBookDetailUseCase) {
        self.isbn13 = isbn13
        self.fetchUseCase = fetchUseCase
    }

    func load() {
        state.isLoading = true
        state.errorMessage = nil
        Task {
            do {
                let detail = try await fetchUseCase.execute(id: isbn13)
                apply(detail: detail)
            } catch {
                state.isLoading = false
                state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func tapPDF(at index: Int) {
        guard state.pdfItems.indices.contains(index) else { return }
        onOpenPDF?(state.pdfItems[index].url)
    }

    private func apply(detail: BookDetail) {
        state.isLoading = false
        state.errorMessage = nil
        state.title = detail.title
        state.subtitle = detail.subtitle
        state.authors = detail.authors
        state.publisher = detail.publisher
        state.language = detail.language
        state.isbn10 = detail.isbn10
        state.isbn13 = detail.isbn13
        state.pages = detail.pages
        state.year = detail.year
        state.rating = detail.rating
        state.description = detail.description
        state.price = detail.price
        state.storeURL = detail.storeURL
        state.imageURL = detail.imageURL
        state.pdfItems = detail.pdfs.map { PDFItem(title: $0.title, url: $0.url) }
    }
}
