//
//  DetailInfoRowView.swift
//  Carrot
//
//  Created by Jacob on 11/12/25.
//

import UIKit

final class DetailInfoRowView: UIStackView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 2
        titleLabel.text = title
        addArrangedSubview(titleLabel)
        addArrangedSubview(valueLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(value: String) {
        valueLabel.text = value.isEmpty ? "-" : value
    }
}
