//
//  SearchViewModel.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import Foundation

@MainActor
final class SearchViewModel {
    struct Item: Hashable {
        let id: String
        let title: String
        let subtitle: String
        let price: String
        let isbn13: String
        let imageURL: URL?
        let storeURL: URL?
    }

    struct State: Equatable {
        var items: [Item] = []
        var isLoading: Bool = false
        var isPaginating: Bool = false
        var errorMessage: String?
        var query: String = ""
    }

    private let searchUseCase: SearchBooksUseCase

    var onStateChange: ((State) -> Void)?
    var onNavigateToDetail: ((String) -> Void)?

    private var state = State() {
        didSet { onStateChange?(state) }
    }

    private var currentPage = 1
    private var totalPages = 1
    private var books: [BookSummary] = []
    private var searchTask: Task<Void, Never>?
    private var activeQuery: String = ""

    init(searchUseCase: SearchBooksUseCase) {
        self.searchUseCase = searchUseCase
    }

    func setQuery(_ query: String) {
        state.query = query
    }

    func performSearch() {
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reset()
            return
        }
        if trimmed == activeQuery, !books.isEmpty {
            return
        }
        searchTask?.cancel()
        currentPage = 1
        totalPages = 1
        books = []
        state.items = []
        state.isLoading = true
        state.errorMessage = nil
        activeQuery = trimmed

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let page = try await searchUseCase.execute(query: trimmed, page: currentPage)
                apply(page: page, append: false)
            } catch {
                handle(error: error)
            }
        }
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        //pagination check
        guard currentIndex >= state.items.count - Const.paginationThreshold else { return }
        guard !state.isPaginating, currentPage < totalPages else { return }
        state.isPaginating = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let nextPage = currentPage + 1
                let page = try await searchUseCase.execute(query: activeQuery, page: nextPage)
                apply(page: page, append: true)
            } catch {
                handle(error: error)
            }
        }
    }

    func selectItem(at index: Int) {
        guard books.indices.contains(index) else { return }
        onNavigateToDetail?(books[index].isbn13)
    }

    private func apply(page: SearchPage, append: Bool) {
        currentPage = page.currentPage
        totalPages = page.totalPages
        if append {
            books.append(contentsOf: page.books)
        } else {
            books = page.books
        }
        state.items = books.map { summary in
            Item(
                id: summary.isbn13,
                title: summary.title,
                subtitle: summary.subtitle,
                price: summary.price,
                isbn13: summary.isbn13,
                imageURL: summary.imageURL,
                storeURL: summary.storeURL
            )
        }
        state.isLoading = false
        state.isPaginating = false
        state.errorMessage = nil
    }

    private func handle(error: Error) {
        state.isLoading = false
        state.isPaginating = false
        if (error as NSError).code == NSURLErrorCancelled { return }
        state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func reset() {
        searchTask?.cancel()
        books = []
        state = State(query: "")
        currentPage = 1
        totalPages = 1
        activeQuery = ""
    }
    
    enum Const {
        static let paginationThreshold: Int = 3

    }
}
