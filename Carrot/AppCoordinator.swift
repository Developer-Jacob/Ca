//
//  AppCoordinator.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import UIKit
struct AppEnvironment {
    let searchUseCase: SearchBooksUseCase
    let detailUseCase: FetchBookDetailUseCase
    let imageLoader: ImageLoading

    static func makeDefault() -> AppEnvironment {
        let dataSource = DefaultBookDataSource(urlSession: URLSession.shared)
        let repository = DefaultBookRepository(dataSource: dataSource)
        return AppEnvironment(
            searchUseCase: DefaultSearchBooksUseCase(bookRepository: repository),
            detailUseCase: DefaultFetchBookDetailUseCase(bookRepository: repository),
            imageLoader: ImageService()
        )
    }
}

final class AppCoordinator {
    private let navigationController: UINavigationController
    private let environment: AppEnvironment

    init(navigationController: UINavigationController, environment: AppEnvironment = .makeDefault()) {
        self.navigationController = navigationController
        self.environment = environment
    }

    @MainActor
    func start() {
        let viewModel = SearchViewModel(searchUseCase: environment.searchUseCase)
        let searchVC = SearchViewController(viewModel: viewModel, imageLoader: environment.imageLoader)
        viewModel.onNavigateToDetail = { [weak self] isbn13 in
            self?.showDetail(isbn13: isbn13)
        }
        navigationController.setViewControllers([searchVC], animated: false)
    }
    
    @MainActor
    private func showDetail(isbn13: String) {
        let detailViewModel = BookDetailViewModel(isbn13: isbn13, fetchUseCase: environment.detailUseCase)
        let detailVC = BookDetailViewController(viewModel: detailViewModel, imageLoader: environment.imageLoader)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
