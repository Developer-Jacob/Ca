//
//  SearchResultCell.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import UIKit

final class SearchResultCell: UITableViewCell {
    static let reuseIdentifier = "SearchResultCell"

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.gray
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let isbnLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var imageTask: Task<Void, Never>?
    private var currentItemID: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        accessibilityTraits = [.button]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        coverImageView.image = nil
        currentItemID = nil
    }

    func configure(with item: SearchViewModel.Item, imageLoader: ImageLoading) {
        currentItemID = item.id
        titleLabel.text = item.title.withEmpty
        subtitleLabel.text = item.subtitle.withEmpty
        priceLabel.text = item.price.withEmpty
        isbnLabel.text = "ISBN13: \(item.isbn13)"

        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self else { return }
            if let image = await imageLoader.loadImage(from: item.imageURL) {
                guard self.currentItemID == item.id else { return }
                self.coverImageView.image = image
            } else {
                guard self.currentItemID == item.id else { return }
                self.coverImageView.image = UIImage(systemName: "book")
            }
        }
    }

    private func setupLayout() {
        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, priceLabel, isbnLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 3
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(coverImageView)
        contentView.addSubview(labelsStack)

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            coverImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            coverImageView.widthAnchor.constraint(equalToConstant: 72),
            coverImageView.heightAnchor.constraint(equalToConstant: 96),

            labelsStack.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            labelsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            labelsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            labelsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

extension String {
    var withEmpty: Self {
        isEmpty ? "-" : self
    }
}
