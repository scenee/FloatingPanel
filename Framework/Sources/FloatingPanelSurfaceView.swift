//
//  Created by Shin Yamamoto on 2018/09/26.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

/// A view that presents a surface interface in a floating panel.
public class FloatingPanelSurfaceView: UIView {

    /// A GrabberHandleView object displayed at the top of the surface view.
    ///
    /// To use a custom grabber handle, hide this and then add the custom one
    /// to the surface view at appropriate coordinates.
    public let grabberHandle: GrabberHandleView = GrabberHandleView()

    /// Offset of the grabber handle from the top
    public var grabberTopPadding: CGFloat = 6.0 { didSet {
        setNeedsUpdateConstraints()
    } }

    /// The height of the grabber bar area
    public var topGrabberBarHeight: CGFloat {
        return grabberTopPadding * 2 + grabberHandleHeight
    }

    /// Grabber view width and height
    public var grabberHandleWidth: CGFloat = 36.0 { didSet {
        setNeedsUpdateConstraints()
    } }
    public var grabberHandleHeight: CGFloat = 5.0 { didSet {
        setNeedsUpdateConstraints()
    } }

    /// A root view of a content view controller
    public weak var contentView: UIView!

    /// The content insets specifying the insets around the content view.
    public var contentInsets: UIEdgeInsets = .zero {
        didSet {
            // Needs update constraints
            self.setNeedsUpdateConstraints()
        }
    }

    private var color: UIColor? = .white { didSet { setNeedsLayout() } }
    var bottomOverflow: CGFloat = 0.0 // Must not call setNeedsLayout()

    public override var backgroundColor: UIColor? {
        get { return color }
        set { color = newValue }
    }

    /// The radius to use when drawing top rounded corners.
    ///
    /// `self.contentView` is masked with the top rounded corners automatically on iOS 11 and later.
    /// On iOS 10, they are not automatically masked because of a UIVisualEffectView issue. See https://forums.developer.apple.com/thread/50854
    public var cornerRadius: CGFloat {
        set { containerView.layer.cornerRadius = newValue; setNeedsLayout() }
        get { return containerView.layer.cornerRadius }
    }

    /// A Boolean indicating whether the surface shadow is displayed.
    public var shadowHidden: Bool = false  { didSet { setNeedsLayout() } }

    /// The color of the surface shadow.
    public var shadowColor: UIColor = .black  { didSet { setNeedsLayout() } }

    /// The offset (in points) of the surface shadow.
    public var shadowOffset: CGSize = CGSize(width: 0.0, height: 1.0)  { didSet { setNeedsLayout() } }

    /// The opacity of the surface shadow.
    public var shadowOpacity: Float = 0.2 { didSet { setNeedsLayout() } }

    /// The blur radius (in points) used to render the surface shadow.
    public var shadowRadius: CGFloat = 3  { didSet { setNeedsLayout() } }

    /// The width of the surface border.
    public var borderColor: UIColor?  { didSet { setNeedsLayout() } }

    /// The color of the surface border.
    public var borderWidth: CGFloat = 0.0  { didSet { setNeedsLayout() } }

    /// The margins to use when laying out the container view wrapping content.
    public var containerMargins: UIEdgeInsets = .zero { didSet {
        setNeedsUpdateConstraints()
    } }

    /// The view presents an actual surface shape.
    ///
    /// It renders the background color, border line and top rounded corners,
    /// specified by other properties. The reason why they're not be applied to
    /// a content view directly is because it avoids any side-effects to the
    /// content view.
    public let containerView: UIView = UIView()

    @available(*, unavailable, renamed: "containerView")
    public var backgroundView: UIView!

    private lazy var containerViewTopConstraint = containerView.topAnchor.constraint(equalTo: topAnchor, constant: containerMargins.top)
    private lazy var containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
    private lazy var containerViewLeftConstraint = containerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0)
    private lazy var containerViewRightConstraint = containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0)

    /// The content view top constraint
    private var contentViewTopConstraint: NSLayoutConstraint?
    /// The content view left constraint
    private var contentViewLeftConstraint: NSLayoutConstraint?
    /// The content right constraint
    private var contentViewRightConstraint: NSLayoutConstraint?
    /// The content height constraint
    private var contentViewHeightConstraint: NSLayoutConstraint?

    private lazy var grabberHandleWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandleWidth)
    private lazy var grabberHandleHeightConstraint = grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandleHeight)
    private lazy var grabberHandleTopConstraint = grabberHandle.topAnchor.constraint(equalTo: topAnchor, constant: grabberTopPadding)

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
            containerViewRightConstraint,
            containerViewHeightConstraint,
            ])

        addSubview(grabberHandle)
        grabberHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabberHandleWidthConstraint,
            grabberHandleHeightConstraint,
            grabberHandleTopConstraint,
            grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
    }

    public override func updateConstraints() {
        containerViewTopConstraint.constant = containerMargins.top
        containerViewLeftConstraint.constant = containerMargins.left
        containerViewRightConstraint.constant = -containerMargins.right
        containerViewHeightConstraint.constant = (containerMargins.bottom == 0) ? bottomOverflow : -(containerMargins.top + containerMargins.bottom)

        contentViewTopConstraint?.constant = containerMargins.top + contentInsets.top
        contentViewLeftConstraint?.constant = containerMargins.left + contentInsets.left
        contentViewRightConstraint?.constant = containerMargins.right + contentInsets.right
        contentViewHeightConstraint?.constant = -(containerMargins.top + containerMargins.bottom + contentInsets.top + contentInsets.bottom)

        grabberHandleTopConstraint.constant = grabberTopPadding
        grabberHandleWidthConstraint.constant = grabberHandleWidth
        grabberHandleHeightConstraint.constant = grabberHandleHeight

        super.updateConstraints()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        log.debug("surface view frame = \(frame)")

        containerView.backgroundColor = color

        updateShadow()
        updateCornerRadius()
        updateBorder()
    }

    private func updateShadow() {
        if shadowHidden == false {
            if #available(iOS 11, *) {
                // For clear background. See also, https://github.com/SCENEE/FloatingPanel/pull/51.
                layer.shadowColor = shadowColor.cgColor
                layer.shadowOffset = shadowOffset
                layer.shadowOpacity = shadowOpacity
                layer.shadowRadius = shadowRadius
            } else {
                // Can't update `layer.shadow*` directly because of a UIVisualEffectView issue in iOS 10, https://forums.developer.apple.com/thread/50854
                // Instead, a user should display shadow appropriately.
            }
        }
    }

    private func updateCornerRadius() {
        guard containerView.layer.cornerRadius != 0.0 else {
            containerView.layer.masksToBounds = false
            return
        }
        containerView.layer.masksToBounds = true
        guard containerMargins.bottom == 0 else { return }
        if #available(iOS 11, *) {
            // Don't use `contentView.clipToBounds` because it prevents content view from expanding the height of a subview of it
            // for the bottom overflow like Auto Layout settings of UIVisualEffectView in Main.storyboard of Example/Maps.
            // Because the bottom of contentView must be fit to the bottom of a screen to work the `safeLayoutGuide` of a content VC.
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Can't use `containerView.layer.mask` because of a UIVisualEffectView issue in iOS 10, https://forums.developer.apple.com/thread/50854
            // Instead, a user should display rounding corners appropriately.
        }
    }

    private func updateBorder() {
        containerView.layer.borderColor = borderColor?.cgColor
        containerView.layer.borderWidth = borderWidth
    }

    func add(contentView: UIView) {
        containerView.addSubview(contentView)
        self.contentView = contentView
        /* contentView.frame = bounds */ // MUST NOT: Because the top safe area inset of a content VC will be incorrect.
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor, constant: containerMargins.top + contentInsets.top)
        let leftConstraint = contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: containerMargins.left + contentInsets.left)
        let rightConstraint = rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: containerMargins.right + contentInsets.right)
        let heightPadding = containerMargins.top + containerMargins.bottom + contentInsets.top + contentInsets.bottom
        let heightConstraint = contentView.heightAnchor.constraint(equalTo: heightAnchor, constant: -heightPadding)
        NSLayoutConstraint.activate([
            topConstraint,
            leftConstraint,
            rightConstraint,
            heightConstraint,
            ])
        self.contentViewTopConstraint = topConstraint
        self.contentViewLeftConstraint = leftConstraint
        self.contentViewRightConstraint = rightConstraint
        self.contentViewHeightConstraint = heightConstraint
    }
}
