// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

/// A content whose top is a horizontally scrolling row of chips, like a list of categories.
/// A vertical drag that starts on the row should move the panel (#693).
final class HorizontalScrollRowViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let chips = UIStackView(arrangedSubviews: (1...12).map { number in
            var configuration = UIButton.Configuration.gray()
            configuration.title = "Category \(number)"
            configuration.cornerStyle = .capsule
            return UIButton(configuration: configuration)
        })
        chips.spacing = 8
        chips.translatesAutoresizingMaskIntoConstraints = false

        let row = UIScrollView()
        row.showsHorizontalScrollIndicator = false
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(chips)
        view.addSubview(row)

        let label = UILabel()
        label.text = "Drag vertically on the chips above, then on this empty area, and compare how the panel follows."
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
            row.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            row.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 44),
            chips.topAnchor.constraint(equalTo: row.contentLayoutGuide.topAnchor),
            chips.bottomAnchor.constraint(equalTo: row.contentLayoutGuide.bottomAnchor),
            chips.leadingAnchor.constraint(equalTo: row.contentLayoutGuide.leadingAnchor, constant: 16),
            chips.trailingAnchor.constraint(equalTo: row.contentLayoutGuide.trailingAnchor, constant: -16),
            chips.heightAnchor.constraint(equalTo: row.frameLayoutGuide.heightAnchor),
            label.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
}
