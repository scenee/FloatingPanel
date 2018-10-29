//
//  Created by Shin Yamamoto on 2018/09/18.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelControllerDelegate: class {
    // if it returns nil, FloatingPanelController uses the default layout
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout?

    // if it returns nil, FloatingPanelController uses the default behavior
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior?

    func floatingPanelDidMove(_ vc: FloatingPanelController) // any offset changes

    // called on start of dragging (may require some time and or distance to move)
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController)
    // called on finger up if the user dragged. velocity is in points/second.
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition)
    func floatingPanelWillBeginDecelerating(_ vc: FloatingPanelController) // called on finger up as we are moving
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) // called when scroll view grinds to a halt
}

public extension FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return nil
    }
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return nil
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {}
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {}
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {}
    func floatingPanelWillBeginDecelerating(_ vc: FloatingPanelController) {}
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {}
}

public enum FloatingPanelPosition: Int, CaseIterable {
    case full
    case half
    case tip
}

///
/// A container view controller to display a floating panel to present contents in parallel as a user wants.
///
public class FloatingPanelController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    /// Constants indicating how safe area insets are added to the adjusted content inset.
    public enum ContentInsetAdjustmentBehavior: Int {
        case always
        case never
    }

    /// The delegate of the floating panel controller object.
    public weak var delegate: FloatingPanelControllerDelegate?

    /// Returns the surface view managed by the controller object. It's the same as `self.view`.
    public var surfaceView: FloatingPanelSurfaceView! {
        return view as? FloatingPanelSurfaceView
    }

    /// Returns the backdrop view managed by the controller object.
    public var backdropView: FloatingPanelBackdropView! {
        return floatingPanel.backdropView
    }

    /// Returns the scroll view that the controller tracks.
    public weak var scrollView: UIScrollView? {
        return floatingPanel.scrollView
    }

    // The underlying gesture recognizer for pan gestures
    public var panGestureRecognizer: UIPanGestureRecognizer {
        return floatingPanel.panGesture
    }

    /// The current position of the floating panel controller's contents.
    public var position: FloatingPanelPosition {
        return floatingPanel.state
    }

    /// The content insets of the tracking scroll view derived from the safe area of the parent view
    public var adjustedContentInsets: UIEdgeInsets {
        return floatingPanel.layoutAdapter.adjustedContentInsets
    }

    /// The behavior for determining the adjusted content offsets.
    ///
    /// This property specifies how the content area of the tracking scroll view is modified using `adjustedContentInsets`. The default value of this property is FloatingPanelController.ContentInsetAdjustmentBehavior.always.
    public var contentInsetAdjustmentBehavior: ContentInsetAdjustmentBehavior = .always

    /// A Boolean value that determines whether the removal interaction is enabled.
    public var isRemovalInteractionEnabled: Bool {
        set { floatingPanel.isRemovalInteractionEnabled = newValue }
        get { return floatingPanel.isRemovalInteractionEnabled }
    }

    private var floatingPanel: FloatingPanel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        floatingPanel = FloatingPanel(self,
                                      layout: fetchLayout(for: self.traitCollection),
                                      behavior: fetchBehavior(for: self.traitCollection))
    }

    /// Initialize a newly created floating panel controller.
    public init() {
        super.init(nibName: nil, bundle: nil)

        floatingPanel = FloatingPanel(self,
                                      layout: fetchLayout(for: self.traitCollection),
                                      behavior: fetchBehavior(for: self.traitCollection))
    }

    /// Creates the view that the controller manages.
    override public func loadView() {
        assert(self.storyboard == nil, "Storyboard isn't supported")

        let view = FloatingPanelSurfaceView()
        view.backgroundColor = .white

        self.view = view as UIView
    }

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        // Change layout for a new trait collection
        floatingPanel.layoutAdapter.layout = fetchLayout(for: newCollection)
        floatingPanel.behavior = fetchBehavior(for: newCollection)

        guard let parent = parent else { fatalError() }

        floatingPanel.layoutAdapter.prepareLayout(toParent: parent)
        floatingPanel.layoutAdapter.activateLayout(of: floatingPanel.state)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection != traitCollection else { return }

        if let parent = parent {
            self.update(safeAreaInsets: parent.layoutInsets)
        }
        floatingPanel.backdropView.isHidden = (traitCollection.verticalSizeClass == .compact)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Need to update safeAreaInsets here to ensure that the `adjustedContentInsets` has a correct value.
        // Because the parent VC does not call viewSafeAreaInsetsDidChange() expectedly and
        // `view.safeAreaInsets` has a correct value of the bottom inset here.
        if let parent = parent {
            self.update(safeAreaInsets: parent.layoutInsets)
        }
    }

    private func fetchLayout(for traitCollection: UITraitCollection) -> FloatingPanelLayout {
        switch traitCollection.verticalSizeClass {
        case .compact:
            return self.delegate?.floatingPanel(self, layoutFor: traitCollection) ?? FloatingPanelDefaultLandscapeLayout()
        default:
            return self.delegate?.floatingPanel(self, layoutFor: traitCollection) ?? FloatingPanelDefaultLayout()
        }
    }

    private func fetchBehavior(for traitCollection: UITraitCollection) -> FloatingPanelBehavior {
        return self.delegate?.floatingPanel(self, behaviorFor: traitCollection) ?? FloatingPanelDefaultBehavior()
    }

    private func update(safeAreaInsets: UIEdgeInsets) {
        floatingPanel.safeAreaInsets = safeAreaInsets
        switch contentInsetAdjustmentBehavior {
        case .always:
            scrollView?.contentInset = adjustedContentInsets
            scrollView?.scrollIndicatorInsets = adjustedContentInsets
        default:
            break
        }
    }

    // MARK: - Container view controller interface

    /// Adds the view managed by the controller as a child of the specified view controller.
    /// - Parameters:
    ///     - parent: A parent view controller object that displays FloatingPanelController's view. A container view controller object isn't applicable.
    ///     - belowView: Insert the surface view managed by the controller below the specified view. By default, the surface view will be added to the end of the parent list of subviews.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    public func addPanel(toParent parent: UIViewController, belowView: UIView? = nil, animated: Bool = false) {
        guard self.parent == nil else {
            log.warning("Already added to a parent(\(parent))")
            return
        }
        precondition((parent is UINavigationController) == false, "UINavigationController displays only one child view controller at a time.")
        precondition((parent is UITabBarController) == false, "UITabBarController displays child view controllers with a radio-style selection interface")
        precondition((parent is UISplitViewController) == false, "UISplitViewController manages two child view controllers in a master-detail interface")
        precondition((parent is UITableViewController) == false, "UITableViewController should not be the parent because the view is a table view so that a floating panel doens't work well")
        precondition((parent is UICollectionViewController) == false, "UICollectionViewController should not be the parent because the view is a collection view so that a floating panel doens't work well")

        view.frame = parent.view.bounds
        if let belowView = belowView {
            parent.view.insertSubview(self.view, belowSubview: belowView)
        } else {
            parent.view.addSubview(self.view)
        }

        parent.addChild(self)

        // Must set a layout again here because `self.traitCollection` is applied correctly once it's added to a parent VC
        floatingPanel.layoutAdapter.layout = fetchLayout(for: traitCollection)
        floatingPanel.layoutViews(in: parent)

        floatingPanel.behavior = fetchBehavior(for: traitCollection)

        floatingPanel.present(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.didMove(toParent: parent)
        }
    }

    /// Removes the controller and the managed view from its parent view controller
    /// - Parameters:
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
    public func removePanelFromParent(animated: Bool, completion: (() -> Void)? = nil) {
        guard self.parent != nil else {
            completion?()
            return
        }

        floatingPanel.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }

            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?()
        }
    }

    /// Moves the position to the specified position.
    /// - Parameters:
    ///     - to: Pass a FloatingPanelPosition value to move the surface view to the position.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller has finished moving. This block has no return value and takes no parameters. You may specify nil for this parameter.
    public func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        floatingPanel.move(to: to, animated: animated, completion: completion)
    }

    /// Presents the specified view controller as the content view controller in the surface view interface.
    public override func show(_ vc: UIViewController, sender: Any?) {
        let surfaceView = self.view as! FloatingPanelSurfaceView
        surfaceView.contentView.addSubview(vc.view)
        vc.view.frame = surfaceView.contentView.bounds
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: surfaceView.contentView.topAnchor, constant: 0.0),
            vc.view.leftAnchor.constraint(equalTo: surfaceView.contentView.leftAnchor, constant: 0.0),
            vc.view.rightAnchor.constraint(equalTo: surfaceView.contentView.rightAnchor, constant: 0.0),
            vc.view.bottomAnchor.constraint(equalTo: surfaceView.contentView.bottomAnchor, constant: 0.0),
            ])
        addChild(vc)
        vc.didMove(toParent: self)
    }

    // MARK: - Scroll view tracking

    /// Tracks the specified scroll view to correspond with the scroll.
    ///
    /// - Attention:
    ///     The specified scroll view must be already assigned to the delegate property because the controller intermediates between the various delegate methods.
    ///
    public func track(scrollView: UIScrollView) {
        floatingPanel.scrollView = scrollView
        floatingPanel.userScrollViewDelegate = scrollView.delegate
        scrollView.delegate = floatingPanel
        switch contentInsetAdjustmentBehavior {
        case .always:
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            } else {
                children.forEach { (vc) in
                    vc.automaticallyAdjustsScrollViewInsets = false
                }
            }
        default:
            break
        }
    }

    // MARK: - Helpers

    /// Returns the y-coordinate of the point at the origin of the surface view
    public func originYOfSurface(for pos: FloatingPanelPosition) -> CGFloat {
        switch pos {
        case .full:
            return floatingPanel.layoutAdapter.topY
        case .half:
            return floatingPanel.layoutAdapter.middleY
        case .tip:
            return floatingPanel.layoutAdapter.bottomY
        }
    }
}
