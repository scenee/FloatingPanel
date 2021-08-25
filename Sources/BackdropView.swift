// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// A view that presents a backdrop interface behind a panel.
@objc(FloatingPanelBackdropView)
public class BackdropView: UIView {

    /// The gesture recognizer for tap gestures to dismiss a panel.
    @objc public var dismissalTapGestureRecognizer: UITapGestureRecognizer!
}
