// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

/// This extension makes sure SwiftUI views are not affected by iOS keyboard.
///
/// Credits to https://steipete.me/posts/disabling-keyboard-avoidance-in-swiftui-uihostingcontroller/
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
