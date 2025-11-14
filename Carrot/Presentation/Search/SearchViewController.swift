//
//  SearchViewController.swift
//  Carrot
//
//  Created by Jacob on 11/10/25.
//

import UIKit

final class SearchViewController: UIViewController, UITableViewDelegate {
    private enum Section { case main }

    private let viewModel: SearchViewModel
    private let imageLoader: ImageLoading
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 120
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseIdentifier)
        return tableView
    }()

    private lazy var dataSource = UITableViewDiffableDataSource<Section, SearchViewModel.Item>(tableView: tableView) { [weak self] tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.reuseIdentifier, for: indexPath)
        guard let cell = cell as? SearchResultCell else { return UITableViewCell() }
        guard let self else { return UITableViewCell() }
        cell.onTapStoreURL = { [weak self] url in
            UIApplication.shared.open(url)
        }
        cell.configure(with: item, imageLoader: self.imageLoader)
        return cell
    }

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.isHidden = true
        return label
    }()

    private let paginationSpinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let searchController = UISearchController(searchResultsController: nil)
    private var debounceWorkItem: DispatchWorkItem?

    init(viewModel: SearchViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        self.title = "도서 검색"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureSearchController()
        bindViewModel()
    }

    private func configureLayout() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        tableView.dataSource = dataSource

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        tableView.tableFooterView = paginationSpinner
    }

    private func configureSearchController() {
        searchController.searchBar.placeholder = "검색어를 입력하세요."
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.apply(state: state)
            }
        }
    }

    private func apply(state: SearchViewModel.State) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchViewModel.Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state.items)
        dataSource.apply(snapshot, animatingDifferences: false)

        state.isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        paginationSpinner.isHidden = !state.isPaginating
        state.isPaginating ? paginationSpinner.startAnimating() : paginationSpinner.stopAnimating()

        if let message = state.errorMessage {
            errorLabel.text = message
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }
    }

    private func scheduleSearch() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.viewModel.performSearch()
        }
        debounceWorkItem = workItem
        // 1초뒤 검색예약
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectItem(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.row)
    }
}

extension SearchViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        viewModel.setQuery(text)
        scheduleSearch()
    }
}
