// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

/// A `UITableViewCell` that accepts a SwiftUI view as its content.
///
/// Credits to https://noahgilmore.com/blog/swiftui-self-sizing-cells/ .
public final class HostingCell<Content: View>: UITableViewCell {
    private let hostingController = UIHostingController<Content?>(
        rootView: nil,
        ignoresKeyboard: true
    )

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        hostingController.view.backgroundColor = nil
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(rootView: Content, parentController: UIViewController) {
        hostingController.rootView = rootView
        hostingController.view.invalidateIntrinsicContentSize()

        let requiresControllerMove = hostingController.parent != parentController
        if requiresControllerMove {
            parentController.addChild(hostingController)
        }

        if !contentView.subviews.contains(hostingController.view) {
            contentView.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraints([
                hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        if requiresControllerMove {
            hostingController.didMove(toParent: parentController)
        }
    }
}
