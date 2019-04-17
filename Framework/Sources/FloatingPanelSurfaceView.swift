//
//  Created by Shin Yamamoto on 2018/09/26.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

class FloatingPanelSurfaceContentView: UIView {}

/// A view that presents a surface interface in a floating panel.
public class FloatingPanelSurfaceView: UIView {

    /// A GrabberHandleView object displayed at the top of the surface view.
    ///
    /// To use a custom grabber handle, hide this and then add the custom one
    /// to the surface view at appropriate coordinates.
    public var grabberHandle: GrabberHandleView!

    /// The height of the grabber bar area
    public static var topGrabberBarHeight: CGFloat {
        return Default.grabberTopPadding * 2 + GrabberHandleView.Default.height // 17.0
    }

    /// A root view of a content view controller
    public weak var contentView: UIView!

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
    public var cornerRadius: CGFloat = 0.0 { didSet { setNeedsLayout() } }

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


    /// The view presents an actual surface shape.
    ///
    /// It renders the background color, border line and top rounded corners,
    /// specified by other properties. The reason why they're not be applied to
    /// a content view directly is because it avoids any side-effects to the
    /// content view.
    public var containerView: UIView!

    @available(*, unavailable, renamed: "containerView")
    public var backgroundView: UIView!

    private var containerViewHeightConstraint: NSLayoutConstraint!

    private struct Default {
        public static let grabberTopPadding: CGFloat = 6.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        render()
    }

    private func render() {
        super.backgroundColor = .clear
        self.clipsToBounds = false

        let containerView = UIView()
        addSubview(containerView)
        self.containerView = containerView

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
            containerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0),
            containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0),
            containerViewHeightConstraint,
            ])

        let grabberHandle = GrabberHandleView()
        addSubview(grabberHandle)
        self.grabberHandle = grabberHandle

        grabberHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabberHandle.topAnchor.constraint(equalTo: topAnchor, constant: Default.grabberTopPadding),
            grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandle.frame.width),
            grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandle.frame.height),
            grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
    }

    public override func updateConstraints() {
        super.updateConstraints()
        containerViewHeightConstraint.constant = bottomOverflow
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        log.debug("surface view frame = \(frame)")

        updateLayers()
        updateContentViewMask()
        updateBorder()

        contentView?.frame = bounds
    }

    private func updateLayers() {
        containerView.backgroundColor = color

        if cornerRadius != 0.0, containerView.layer.cornerRadius != cornerRadius {
            containerView.layer.masksToBounds = true
            containerView.layer.cornerRadius = cornerRadius
        }

        if shadowHidden == false {
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
        }
    }

    private func updateContentViewMask() {
        guard
            cornerRadius != 0.0,
            containerView.layer.cornerRadius != cornerRadius
            else { return }

        if #available(iOS 11, *) {
            // Don't use `contentView.clipToBounds` because it prevents content view from expanding the height of a subview of it
            // for the bottom overflow like Auto Layout settings of UIVisualEffectView in Main.storyboard of Example/Maps.
            // Because the bottom of contentView must be fit to the bottom of a screen to work the `safeLayoutGuide` of a content VC.
            containerView.layer.masksToBounds = true
            containerView.layer.cornerRadius = cornerRadius
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Don't use `contentView.layer.mask` because of a UIVisualEffectView issue in iOS 10, https://forums.developer.apple.com/thread/50854
            // Instead, a user can mask the content view manually in an application.
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
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
            contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0),
            contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0),
            contentView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
            ])
    }
}
