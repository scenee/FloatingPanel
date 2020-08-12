// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// An object for customizing the appearance of a surface view
@objc(FloatingPanelSurfaceAppearance)
@objcMembers
public class SurfaceAppearance: NSObject {

    /// An object that represents information to render a shadow
    @objc(FloatingPanelSurfaceAppearanceShadow)
    public class Shadow: NSObject {
        /// A Boolean indicating whether a shadow is displayed.
        @objc
        public var hidden: Bool = false

        /// The color of a shadow.
        @objc
        public var color: UIColor = .black

        /// The offset (in points) of a shadow.
        @objc
        public var offset: CGSize = CGSize(width: 0.0, height: 1.0)

        /// The opacity of a shadow.
        @objc
        public var opacity: Float = 0.2

        /// The blur radius (in points) used to render a shadow.
        @objc
        public var radius: CGFloat = 3

        /// The inflated amount of a shadow prior to applying the blur.
        @objc
        public var spread: CGFloat = 0

    }
    /// The background color of a surface view
    public var backgroundColor: UIColor? = {
        if #available(iOS 13, *) {
            return UIColor.systemBackground
        } else {
            return UIColor.white
        }
    }()

    /// The radius to use when drawing the top rounded corners.
    ///
    /// `self.contentView` is masked with the top rounded corners automatically on iOS 11 and later.
    /// On iOS 10, they are not automatically masked because of a UIVisualEffectView issue. See https://forums.developer.apple.com/thread/50854
    public var cornerRadius: CGFloat = 0.0

    /// An array of shadows used to create drop shadows underneath a surface view.
    public var shadows: [Shadow] = [Shadow()]

    /// The border width of a surface view.
    public var borderColor: UIColor?

    /// The border color of a surface view.
    public var borderWidth: CGFloat = 0.0
}

/// A view that presents a surface interface in a panel.
@objc(FloatingPanelSurfaceView)
@objcMembers
public class SurfaceView: UIView {
    /// A `FloatingPanelGrabberView` object displayed at the top of the surface view.
    ///
    /// To use a custom grabber, hide this and then add it to the surface view at appropriate point.
    public let grabberHandle = GrabberView()

    /// Offset of the grabber handle from the interactive edge.
    public var grabberHandlePadding: CGFloat = 6.0 { didSet {
        setNeedsUpdateConstraints()
    } }

    /// The offset from the move edge to prevent the content scroll
    public var grabberAreaOffset: CGFloat = 36.0

    /// The grabber handle size
    ///
    /// On left/right positioned panel the width dimension is used as the height of `grabberHandle`, and vice versa.
    public var grabberHandleSize: CGSize = CGSize(width: 36.0, height: 5.0) { didSet {
        setNeedsUpdateConstraints()
    } }

    /// The content view to be assigned a view of the content view controller of `FloatingPanelController`
    public weak var contentView: UIView!

    /// The content insets specifying the insets around the content view.
    public var contentPadding: UIEdgeInsets = .zero {
        didSet {
            // Needs update constraints
            self.setNeedsUpdateConstraints()
        }
    }

    public override var backgroundColor: UIColor? {
        get { return appearance.backgroundColor }
        set { appearance.backgroundColor = newValue; setNeedsLayout() }
    }

    /// The appearance settings for a surface view.
    public var appearance = SurfaceAppearance() { didSet {
        shadowLayers = appearance.shadows.map { _ in CAShapeLayer() }
        setNeedsLayout()
    }}

    /// The margins to use when laying out the container view wrapping content.
    public var containerMargins: UIEdgeInsets = .zero { didSet {
        setNeedsUpdateConstraints()
    } }

    /// The view that displays an actual surface shape.
    ///
    /// It renders the background color, border line and top rounded corners,
    /// specified by other properties. The reason why they're not be applied to
    /// a content view directly is because it avoids any side-effects to the
    /// content view.
    public let containerView: UIView = UIView()

    var containerOverflow: CGFloat = 0.0 { // Must not call setNeedsLayout()
        didSet {
            // Calling setNeedsUpdateConstraints() is necessary to fix a layout break
            // when the contentMode is changed after laying out a panel, for instance,
            // after calling viewDidAppear(_:) of the parent view controller.
            setNeedsUpdateConstraints()
        }
    }

    var position: FloatingPanelPosition = .bottom {
        didSet {
            guard position != oldValue else { return }
            NSLayoutConstraint.deactivate([grabberHandleEdgePaddingConstraint,
                                           grabberHandleCenterConstraint,
                                           grabberHandleWidthConstraint,
                                           grabberHandleHeightConstraint])
            switch position {
            case .top:
                grabberHandleEdgePaddingConstraint = grabberHandle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -grabberHandlePadding)
                grabberHandleCenterConstraint = grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor)
                grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleSize.width)
                grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleSize.height)
            case .left:
                grabberHandleEdgePaddingConstraint = grabberHandle.rightAnchor.constraint(equalTo: rightAnchor, constant: -grabberHandlePadding)
                grabberHandleCenterConstraint = grabberHandle.centerYAnchor.constraint(equalTo: centerYAnchor)
                grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleSize.height)
                grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleSize.width)
            case .bottom:
                grabberHandleEdgePaddingConstraint = grabberHandle.topAnchor.constraint(equalTo: topAnchor, constant: grabberHandlePadding)
                grabberHandleCenterConstraint = grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor)
                grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleSize.width)
                grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleSize.height)
            case .right:
                grabberHandleEdgePaddingConstraint = grabberHandle.leftAnchor.constraint(equalTo: leftAnchor, constant: grabberHandlePadding)
                grabberHandleCenterConstraint = grabberHandle.centerYAnchor.constraint(equalTo: centerYAnchor)
                grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleSize.height)
                grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleSize.width)
            }
            NSLayoutConstraint.activate([grabberHandleEdgePaddingConstraint,
                                         grabberHandleCenterConstraint,
                                         grabberHandleWidthConstraint,
                                         grabberHandleHeightConstraint])
            setNeedsUpdateConstraints()
        }
    }

    var grabberAreaFrame: CGRect {
        switch position {
        case .top:
            return CGRect(origin: .init(x: bounds.minX, y: bounds.maxY - grabberAreaOffset),
                          size: .init(width: bounds.width, height: grabberAreaOffset))
        case .left:
            return CGRect(origin: .init(x: bounds.maxX - grabberAreaOffset, y: bounds.minY),
                          size: .init(width: grabberAreaOffset, height: bounds.height))
        case .bottom:
            return CGRect(origin: CGPoint(x: bounds.minX, y: bounds.minY),
                          size: CGSize(width: bounds.width, height: grabberAreaOffset))
        case .right:
            return CGRect(origin: .init(x: bounds.minX, y: bounds.minY),
                          size: .init(width: grabberAreaOffset, height: bounds.height))
        }
    }

    private lazy var containerViewTopConstraint = containerView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0)
    private lazy var containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0)
    private lazy var containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0)
    private lazy var containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0)

    /// The content view's top constraint
    private var contentViewTopConstraint: NSLayoutConstraint?
    /// The content view's left constraint
    private var contentViewLeftConstraint: NSLayoutConstraint?
    /// The content view's right constraint
    private var contentViewRightConstraint: NSLayoutConstraint?
    /// The content view's bottom constraint
    private var contentViewBottomConstraint: NSLayoutConstraint?

    private lazy var grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleSize.width)
    private lazy var grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleSize.height)
    private lazy var grabberHandleCenterConstraint =  grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor)
    private lazy var grabberHandleEdgePaddingConstraint = grabberHandle.topAnchor.constraint(equalTo: topAnchor, constant: grabberHandlePadding)

    private var shadowLayers: [CALayer] = [] {
        willSet {
            for shadowLayer in shadowLayers {
                shadowLayer.removeFromSuperlayer()
            }
        }
        didSet {
            for shadowLayer in shadowLayers {
                layer.insertSublayer(shadowLayer, at: 0)
            }
        }
    }

    public override class var requiresConstraintBasedLayout: Bool { return true }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubViews()
    }

    private func addSubViews() {
        super.backgroundColor = .clear
        self.clipsToBounds = false

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerViewTopConstraint,
            containerViewLeftConstraint,
            containerViewBottomConstraint,
            containerViewRightConstraint,
        ].map {
            $0.identifier = "FloatingPanel-surface-container"
            return $0;
        })

        addSubview(grabberHandle)
        grabberHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabberHandleEdgePaddingConstraint,
            grabberHandleCenterConstraint,
            grabberHandleWidthConstraint,
            grabberHandleHeightConstraint,
        ].map {
            $0.identifier = "FloatingPanel-surface-grabber"
            return $0;
        })

        shadowLayers = appearance.shadows.map { _ in CALayer() }
    }

    public override func updateConstraints() {
        switch position {
        case .top:
            containerViewTopConstraint.constant = (containerMargins.top == 0) ? -containerOverflow : containerMargins.top
            containerViewLeftConstraint.constant = containerMargins.left
            containerViewRightConstraint.constant = -containerMargins.right
            containerViewBottomConstraint.constant = -containerMargins.bottom
        case .left:
            containerViewTopConstraint.constant = containerMargins.top
            containerViewLeftConstraint.constant = (containerMargins.left == 0) ? -containerOverflow : containerMargins.left
            containerViewRightConstraint.constant = -containerMargins.right
            containerViewBottomConstraint.constant = -containerMargins.bottom
        case .bottom:
            containerViewTopConstraint.constant = containerMargins.top
            containerViewLeftConstraint.constant = containerMargins.left
            containerViewRightConstraint.constant = -containerMargins.right
            containerViewBottomConstraint.constant = (containerMargins.bottom == 0) ? containerOverflow : -containerMargins.bottom
        case .right:
            containerViewTopConstraint.constant = containerMargins.top
            containerViewLeftConstraint.constant = containerMargins.left
            containerViewRightConstraint.constant = (containerMargins.right == 0) ? containerOverflow : -containerMargins.right
            containerViewBottomConstraint.constant = -containerMargins.bottom
        }

        contentViewTopConstraint?.constant = containerMargins.top + contentPadding.top
        contentViewLeftConstraint?.constant = containerMargins.left + contentPadding.left
        contentViewRightConstraint?.constant = containerMargins.right + contentPadding.right
        contentViewBottomConstraint?.constant = containerMargins.bottom + contentPadding.bottom

        switch position {
        case .top, .left:
            grabberHandleEdgePaddingConstraint.constant = -grabberHandlePadding
        case .bottom, .right:
            grabberHandleEdgePaddingConstraint.constant = grabberHandlePadding
        }

        switch position {
        case .top, .bottom:
            grabberHandleWidthConstraint.constant = grabberHandleSize.width
            grabberHandleHeightConstraint.constant = grabberHandleSize.height
        case .left, .right:
            grabberHandleWidthConstraint.constant = grabberHandleSize.height
            grabberHandleHeightConstraint.constant = grabberHandleSize.width
       }

        super.updateConstraints()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        log.debug("surface view frame = \(frame)")

        containerView.backgroundColor = appearance.backgroundColor

        updateShadow()
        updateCornerRadius()
        updateBorder()

        grabberHandle.layer.cornerRadius = grabberHandleSize.height / 2
    }

    public override var intrinsicContentSize: CGSize {
        let fittingSize = UIView.layoutFittingCompressedSize
        let contentSize = contentView?.systemLayoutSizeFitting(fittingSize) ?? .zero
        return CGSize(width: containerMargins.horizontalInset + contentPadding.horizontalInset + contentSize.width,
                      height: containerMargins.verticalInset + contentPadding.verticalInset + contentSize.height)
    }

    private func updateShadow() {
        // Disable shadow animation when the surface's frame jumps to a new value.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (i, shadow) in appearance.shadows.enumerated() {
            let shadowLayer = shadowLayers[i]

            shadowLayer.backgroundColor = UIColor.clear.cgColor
            shadowLayer.frame = layer.bounds

            let spread = shadow.spread
            let shadowPath = UIBezierPath(roundedRect: containerView.frame.insetBy(dx: -spread,
                                                                                   dy: -spread),
                                          byRoundingCorners: [.allCorners],
                                          cornerRadii: CGSize(width: appearance.cornerRadius, height: 0))
            shadowLayer.shadowPath = shadowPath.cgPath
            shadowLayer.shadowColor = shadow.color.cgColor
            shadowLayer.shadowOffset = shadow.offset
            // A shadow.radius value isn't manipulated by a scale(i.e. the display scale). It should be applied to the value by itself.
            shadowLayer.shadowRadius = shadow.radius
            shadowLayer.shadowOpacity = shadow.opacity

            let mask = CAShapeLayer()
            let path = UIBezierPath(roundedRect: containerView.frame,
                                    byRoundingCorners: [.allCorners],
                                    cornerRadii: CGSize(width: appearance.cornerRadius, height: 0))
            let size = window?.bounds.size ?? CGSize(width: 1000.0, height: 1000.0)
            path.append(UIBezierPath(rect: layer.bounds.insetBy(dx: -size.width,
                                                                dy: -size.height)))
            mask.fillRule = .evenOdd
            mask.path = path.cgPath
            if #available(iOS 13.0, *) {
                mask.cornerCurve = containerView.layer.cornerCurve
            }
            shadowLayer.mask = mask
        }
        CATransaction.commit()
    }

    private func updateCornerRadius() {
        containerView.layer.cornerRadius = appearance.cornerRadius
        guard containerView.layer.cornerRadius != 0.0 else {
            containerView.layer.masksToBounds = false
            return
        }
        containerView.layer.masksToBounds = true
        if position.inset(containerMargins) != 0 {
            if #available(iOS 11, *) {
                containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                                     .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            }
            return
        }
        if #available(iOS 11, *) {
            // Don't use `contentView.clipToBounds` because it prevents content view from expanding the height of a subview of it
            // for the bottom overflow like Auto Layout settings of UIVisualEffectView in Main.storyboard of Example/Maps.
            // Because the bottom of contentView must be fit to the bottom of a screen to work the `safeLayoutGuide` of a content VC.
            switch position {
            case .top:
                containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            case .left:
                containerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            case .bottom:
                containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .right:
                containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            }
        } else {
            // Can't use `containerView.layer.mask` because of a UIVisualEffectView issue in iOS 10, https://forums.developer.apple.com/thread/50854
            // Instead, a user should display rounding corners appropriately.
        }
    }

    private func updateBorder() {
        containerView.layer.borderColor = appearance.borderColor?.cgColor
        containerView.layer.borderWidth = appearance.borderWidth
    }

    func set(contentView: UIView) {
        containerView.addSubview(contentView)
        self.contentView = contentView
        /* contentView.frame = bounds */ // MUST NOT: Because the top safe area inset of a content VC will be incorrect.
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor, constant: containerMargins.top + contentPadding.top)
        let leftConstraint = contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: containerMargins.left + contentPadding.left)
        let rightConstraint = rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: containerMargins.right + contentPadding.right)
        let bottomConstraint = bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: containerMargins.bottom + contentPadding.bottom)
        NSLayoutConstraint.activate([
            topConstraint,
            leftConstraint,
            rightConstraint,
            bottomConstraint,
        ].map {
            $0.priority = .defaultHigh;
            $0.identifier = "FloatingPanel-surface-content"
            return $0;
        })
        self.contentViewTopConstraint = topConstraint
        self.contentViewLeftConstraint = leftConstraint
        self.contentViewRightConstraint = rightConstraint
        self.contentViewBottomConstraint = bottomConstraint
    }
}
