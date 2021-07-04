// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

public final class HostingCell<Content: View>: UITableViewCell {
  private let hostingController = UIHostingController<Content?>(
    rootView: nil,
    ignoresKeyboard: true
  )

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    hostingController.view.backgroundColor = .clear
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
      contentView.addConstraints(
        hostingController.view.constraintsEqualTo(view: contentView)
      )
    }

    if requiresControllerMove {
      hostingController.didMove(toParent: parentController)
    }
  }
}

public extension UIView {
  func constraintsEqualTo(view: UIView) -> [NSLayoutConstraint] {
    translatesAutoresizingMaskIntoConstraints = false
    return [
      leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topAnchor.constraint(equalTo: view.topAnchor),
      trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ]
  }
}

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
