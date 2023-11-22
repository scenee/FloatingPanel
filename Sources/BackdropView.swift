// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// A view that presents a backdrop interface behind a panel.
@objc(FloatingPanelBackdropView)
open class BackdropView: UIView {

    /// The gesture recognizer for tap gestures to dismiss a panel.
    ///
    /// By default, this gesture recognizer is disabled as following the default behavior of iOS modalities.
    /// To dismiss a panel by tap gestures on the backdrop, `dismissalTapGestureRecognizer.isEnabled` is set to true.
    @objc public var dismissalTapGestureRecognizer: UITapGestureRecognizer

    public init() {
        dismissalTapGestureRecognizer = UITapGestureRecognizer()
        dismissalTapGestureRecognizer.isEnabled = false
        super.init(frame: .zero)
        addGestureRecognizer(dismissalTapGestureRecognizer)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
