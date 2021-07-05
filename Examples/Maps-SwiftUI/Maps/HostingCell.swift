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

/// This extension fixes a safe area issue happening with `HostingCell` when a
/// keyboard is shown.
///
/// The bug is present only in iOS 14.0-14.2 and only if a keyboard is shown.
///
/// Credits to https://steipete.me/posts/disabling-keyboard-avoidance-in-swiftui-uihostingcontroller/
@available(iOS, introduced: 13, deprecated: 14.2, message: "No longer necessary after iOS 14.2.")
extension UIHostingController {
    public convenience init(rootView: Content, ignoresKeyboard: Bool) {
        self.init(rootView: rootView)

        if ignoresKeyboard {
            guard let viewClass = object_getClass(view) else { return }

            let viewSubclassName = String(
                cString: class_getName(viewClass)
            ).appending("_IgnoresKeyboard")

            if let viewSubclass = NSClassFromString(viewSubclassName) {
                object_setClass(view, viewSubclass)
            } else {
                guard
                    let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String,
                    let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0)
                else { return }

                if let method = class_getInstanceMethod(
                    viewClass,
                    NSSelectorFromString("keyboardWillShowWithNotification:")
                ) {
                    let keyboardWillShow: @convention(block) (AnyObject, AnyObject) -> Void = { _, _ in }
                    class_addMethod(
                        viewSubclass,
                        NSSelectorFromString("keyboardWillShowWithNotification:"),
                        imp_implementationWithBlock(keyboardWillShow),
                        method_getTypeEncoding(method)
                    )
                }
                objc_registerClassPair(viewSubclass)
                object_setClass(view, viewSubclass)
            }
        }
    }
}
