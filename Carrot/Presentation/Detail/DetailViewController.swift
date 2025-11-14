//
//  DetailViewController.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import UIKit

final class BookDetailViewController: UIViewController {
    private let viewModel: BookDetailViewModel
    private let imageLoader: ImageLoading

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "설명"
        return label
    }()
    private let descriptionLabel = UILabel()
    private let pdfStack = UIStackView()
    private let pdfHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "PDF 미리보기"
        return label
    }()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let storeButton = UIButton(type: .system)
    private var imageTask: Task<Void, Never>?

    private let infoRows: [(title: String, view: DetailInfoRowView)] = [
        ("저자", DetailInfoRowView(title: "저자")),
        ("출판사", DetailInfoRowView(title: "출판사")),
        ("언어", DetailInfoRowView(title: "언어")),
        ("ISBN10", DetailInfoRowView(title: "ISBN10")),
        ("ISBN13", DetailInfoRowView(title: "ISBN13")),
        ("페이지", DetailInfoRowView(title: "페이지")),
        ("출간연도", DetailInfoRowView(title: "출간연도")),
        ("평점", DetailInfoRowView(title: "평점"))
    ]

    init(viewModel: BookDetailViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        title = "상세화면"
    }

    deinit {
        imageTask?.cancel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        titleLabel.numberOfLines = 0

        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        priceLabel.textColor = .systemBlue

        descriptionLabel.numberOfLines = 0

        pdfStack.axis = .vertical
        pdfStack.spacing = 8

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        storeButton.setTitle("스토어에서 보기", for: .normal)
        storeButton.addTarget(self, action: #selector(didTapStore), for: .touchUpInside)
        storeButton.isHidden = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        contentStack.addArrangedSubview(coverImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(priceLabel)
        infoRows.forEach { contentStack.addArrangedSubview($0.view) }
        contentStack.addArrangedSubview(descriptionTitleLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(storeButton)
        contentStack.addArrangedSubview(pdfHeaderLabel)
        contentStack.addArrangedSubview(pdfStack)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state: state)
        }
        viewModel.onOpenPDF = { url in
            UIApplication.shared.open(url)
        }
    }

    private func apply(state: BookDetailViewModel.State) {
        state.isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        if let message = state.errorMessage {
            errorLabel.text = message
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }

        titleLabel.text = state.title
        subtitleLabel.text = state.subtitle
        priceLabel.text = state.price
        descriptionLabel.text = state.description
        storeButton.isHidden = state.storeURL == nil

        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self else { return }
            if let image = await imageLoader.loadImage(from: state.imageURL) {
                await MainActor.run {
                    self.coverImageView.image = image
                }
            } else {
                coverImageView.image = UIImage(systemName: "book")
            }
        }

        infoRows.forEach { row in
            switch row.title {
            case "저자": row.view.update(value: state.authors)
            case "출판사": row.view.update(value: state.publisher)
            case "언어": row.view.update(value: state.language)
            case "ISBN10": row.view.update(value: state.isbn10)
            case "ISBN13": row.view.update(value: state.isbn13)
            case "페이지": row.view.update(value: state.pages)
            case "출간연도": row.view.update(value: state.year)
            case "평점": row.view.update(value: state.rating)
            default: break
            }
        }

        pdfStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if state.pdfItems.isEmpty {
            let label = UILabel()
            label.text = "PDF 링크 없음"
            label.textColor = .secondaryLabel
            pdfStack.addArrangedSubview(label)
        } else {
            for (index, item) in state.pdfItems.enumerated() {
                let button = UIButton(type: .system)
                button.setTitle("PDF #\(index + 1): \(item.title)", for: .normal)
                button.contentHorizontalAlignment = .leading
                button.tag = index
                button.addTarget(self, action: #selector(didTapPDFButton(_:)), for: .touchUpInside)
                pdfStack.addArrangedSubview(button)
            }
        }
    }

    @objc private func didTapStore() {
        guard let url = viewModel.currentState.storeURL else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapPDFButton(_ sender: UIButton) {
        viewModel.tapPDF(at: sender.tag)
    }
}
