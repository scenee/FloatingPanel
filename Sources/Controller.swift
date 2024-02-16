// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import os.log

/// A set of methods implemented by the delegate of a panel controller allows the adopting delegate to respond to
/// messages from the FloatingPanelController class and thus respond to, and in some affect, operations such as
/// dragging, attracting a panel, layout of a panel and the content, and transition animations.
@objc public protocol FloatingPanelControllerDelegate {
    /// Returns a FloatingPanelLayout object. If you use the default one, you can use a `FloatingPanelBottomLayout` object.
    @objc(floatingPanel:layoutForTraitCollection:) optional
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout

    /// Returns a FloatingPanelLayout object. If you use the default one, you can use a `FloatingPanelBottomLayout` object.
    @objc(floatingPanel:layoutForSize:) optional
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor size: CGSize) -> FloatingPanelLayout

    /// Returns a UIViewPropertyAnimator object to add/present the  panel to a position.
    ///
    /// Default is the spring animation with 0.25 secs.
    @objc(floatingPanel:animatorForPresentingToState:) optional
    func floatingPanel(_ fpc: FloatingPanelController, animatorForPresentingTo state: FloatingPanelState) -> UIViewPropertyAnimator

    /// Returns a UIViewPropertyAnimator object to remove/dismiss a panel from a position.
    ///
    /// Default is the spring animator with 0.25 secs.
    @objc(floatingPanel:animatorForDismissingWithVelocity:) optional
    func floatingPanel(_ fpc: FloatingPanelController, animatorForDismissingWith velocity: CGVector) -> UIViewPropertyAnimator

    /// Called when a panel has changed to a new state.
    ///
    /// This can be called inside an animation block for presenting, dismissing a panel or moving a panel with your
    /// animation. So any view properties set inside this function will be automatically animated alongside a panel.
    @objc optional
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController)

    /// Asks the delegate if dragging should begin by the pan gesture recognizer.
    @objc optional
    func floatingPanelShouldBeginDragging(_ fpc: FloatingPanelController) -> Bool

    /// Called while the user drags the surface or the surface moves to a state anchor.
    @objc optional
    func floatingPanelDidMove(_ fpc: FloatingPanelController)

    /// Called on start of dragging (may require some time and or distance to move)
    @objc optional
    func floatingPanelWillBeginDragging(_ fpc: FloatingPanelController)

    /// Called on finger up if the user dragged. velocity is in points/second.
    @objc optional
    func floatingPanelWillEndDragging(_ fpc: FloatingPanelController, withVelocity velocity: CGPoint, targetState: UnsafeMutablePointer<FloatingPanelState>)

    /// Called on finger up if the user dragged.
    ///
    /// If `attract` is true, the panel continues moving towards the nearby state
    /// anchor. Otherwise, it stops at the closest state anchor.
    ///
    /// - Note: If `attract` is false, ``FloatingPanelController.state`` property has
    ///   already changed to the closest anchor's state by the time this delegate method
    ///   is called.
    @objc optional
    func floatingPanelDidEndDragging(_ fpc: FloatingPanelController, willAttract attract: Bool)

    /// Called when it is about to be attracted to a state anchor.
    @objc optional
    func floatingPanelWillBeginAttracting(_ fpc: FloatingPanelController, to state: FloatingPanelState) // called on finger up as a panel are moving

    /// Called when attracting it is completed.
    @objc optional
    func floatingPanelDidEndAttracting(_ fpc: FloatingPanelController) // called when a panel stops

    /// Asks the delegate whether a panel should be removed when dragging ended at the specified location
    ///
    /// This delegate method is called only where ``FloatingPanel/FloatingPanelController/isRemovalInteractionEnabled``  is `true`.
    /// The velocity vector is calculated from the distance to a point of the hidden state and the pan gesture's velocity.
    @objc(floatingPanel:shouldRemoveAtLocation:withVelocity:)
    optional
    func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool

    /// Called on start to remove its view controller from the parent view controller.
    @objc(floatingPanelWillRemove:)
    optional
    func floatingPanelWillRemove(_ fpc: FloatingPanelController)

    /// Called when a panel is removed from the parent view controller.
    @objc optional
    func floatingPanelDidRemove(_ fpc: FloatingPanelController)

    /// Asks the delegate for a content offset of the tracking scroll view to be pinned when a panel moves
    ///
    /// If you do not implement this method, the controller uses a value of the content offset plus the content insets
    /// of the tracked scroll view. Your implementation of this method can return a value for a navigation bar with a large
    /// title, for example.
    ///
    /// This method will not be called if the controller doesn't track any scroll view.
    @objc(floatingPanel:contentOffsetForPinningScrollView:)
    optional
    func floatingPanel(_ fpc: FloatingPanelController, contentOffsetForPinning trackingScrollView: UIScrollView) -> CGPoint

    /// Returns a Boolean value that determines whether the tracking scroll view should
    /// scroll or not
    ///
    ///
    /// If you return true, the scroll content scrolls when its scroll position is not
    /// at the top of the content. If the delegate doesn’t implement this method, its
    /// content can be scrolled only in the most expanded state.
    ///
    /// Basically, the decision to scroll is based on the `state` property like the
    /// following code.
    /// ```swift
    /// func floatingPanel(
    ///     _ fpc: FloatingPanelController,
    ///     shouldAllowToScroll scrollView: UIScrollView,
    ///     in state: FloatingPanelState
    /// ) -> Bool {
    ///     return state == .full || state == .half
    /// }
    /// ```
    ///
    /// - Attention: It is recommended that this method always returns the most expanded state(i.e.
    /// .full). If it excludes the state, the panel might do unexpected behaviors.
    @objc(floatingPanel:shouldAllowToScroll:in:)
    optional func floatingPanel(
        _ fpc: FloatingPanelController,
        shouldAllowToScroll scrollView: UIScrollView,
        in state: FloatingPanelState
    ) -> Bool
}

///
/// A container view controller to display a panel to present contents in parallel as a user wants.
///
@objc
open class FloatingPanelController: UIViewController {
    /// Constants indicating how safe area insets are added to the adjusted content inset.
    @objc
    public enum ContentInsetAdjustmentBehavior: Int {
        case always
        case never
    }

    /// A flag used to determine how the controller object lays out the content view when the surface position changes.
    @objc
    public enum ContentMode: Int {
        /// The option to fix the content to keep the height of the top most position.
        case `static`
        /// The option to scale the content to fit the bounds of the root view by changing the surface position.
        case fitToBounds
    }

    /// The delegate of a panel controller object.
    @objc
    public weak var delegate: FloatingPanelControllerDelegate?{
        didSet{
            didUpdateDelegate()
        }
    }

    /// Returns the surface view managed by the controller object. It's the same as `self.view`.
    @objc
    public var surfaceView: SurfaceView {
        return floatingPanel.surfaceView
    }

    /// Returns the backdrop view managed by the controller object.
    @objc
    public var backdropView: BackdropView {
        set { floatingPanel.backdropView = newValue }
        get { return floatingPanel.backdropView }
    }

    /// Returns the scroll view that the controller tracks.
    @objc
    public weak var trackingScrollView: UIScrollView? {
        return floatingPanel.scrollView
    }

    // The underlying gesture recognizer for pan gestures
    @objc
    public var panGestureRecognizer: FloatingPanelPanGestureRecognizer {
        return floatingPanel.panGestureRecognizer
    }

    /// The current position of a panel controller's contents.
    @objc
    public var state: FloatingPanelState {
        return floatingPanel.state
    }

    /// A Boolean value indicating whether a panel controller is attracting the surface to a state anchor.
    @objc
    public var isAttracting: Bool {
        return floatingPanel.isAttracting
    }

    /// The layout object that the controller manages
    ///
    /// You need to call ``invalidateLayout()`` if you want to apply a new layout object into the panel
    /// immediately.
    @objc
    public var layout: FloatingPanelLayout {
        get { _layout }
        set {
            _layout = newValue
            if let parent = parent, let layout = newValue as? UIViewController, layout == parent {
                let log = "Warning: A memory leak occurs due to a retain cycle, as \(self) owns the parent view controller(\(parent)) as its layout object. Don't allow the parent to adopt FloatingPanelLayout."
                os_log(msg, log: sysLog, type: .error, log)
            }
        }
    }

    /// The behavior object that the controller manages
    @objc
    public var behavior: FloatingPanelBehavior {
        get { _behavior }
        set {
            _behavior = newValue
            if let parent = parent, let behavior = newValue as? UIViewController, behavior == parent {
                let log = "Warning: A memory leak occurs due to a retain cycle, as \(self) owns the parent view controller(\(parent)) as its behavior object. Don't allow the parent to adopt FloatingPanelBehavior."
                os_log(msg, log: sysLog, type: .error, log)
            }
        }
    }

    /// The content insets of the tracking scroll view derived from this safe area
    @objc
    public var adjustedContentInsets: UIEdgeInsets {
        return floatingPanel.layoutAdapter.adjustedContentInsets
    }

    /// The behavior for determining the adjusted content offsets.
    ///
    /// This property specifies how the content area of the tracking scroll view is modified using ``adjustedContentInsets``. The default value of this property is FloatingPanelController.ContentInsetAdjustmentBehavior.always.
    @objc
    public var contentInsetAdjustmentBehavior: ContentInsetAdjustmentBehavior = .always

    /// A Boolean value that determines whether the removal interaction is enabled.
    @objc
    public var isRemovalInteractionEnabled: Bool {
        @objc(setRemovalInteractionEnabled:) set { floatingPanel.isRemovalInteractionEnabled = newValue }
        @objc(isRemovalInteractionEnabled) get { return floatingPanel.isRemovalInteractionEnabled }
    }

    /// The view controller responsible for the content portion of a panel.
    @objc
    public var contentViewController: UIViewController? {
        set { set(contentViewController: newValue) }
        get { return _contentViewController }
    }

    /// The NearbyState determines that finger's nearby state.
    public var nearbyState: FloatingPanelState {
        let currentY = surfaceLocation.y
        return floatingPanel.targetState(from: currentY, with: .zero)
    }

    /// Constants that define how a panel content fills in the surface.
    @objc
    public var contentMode: ContentMode = .static {
        didSet {
            guard state != .hidden else { return }
            activateLayout(forceLayout: false)
        }
    }

    private var _contentViewController: UIViewController?

    private(set) var floatingPanel: Core!
    private var preSafeAreaInsets: UIEdgeInsets = .zero // Capture the latest one
    private var safeAreaInsetsObservation: NSKeyValueObservation?
    private let modalTransition = ModalTransition()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        setUp()
    }

    /// Initialize a newly created panel controller.
    @objc
    public init(delegate: FloatingPanelControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        setUp()
    }

    private func setUp() {
        _ = FloatingPanelController.dismissSwizzling

        modalPresentationStyle = .custom
        transitioningDelegate = modalTransition

        let initialLayout: FloatingPanelLayout
        if let layout = delegate?.floatingPanel?(self, layoutFor: traitCollection) {
            initialLayout = layout
        } else {
            initialLayout = FloatingPanelBottomLayout()
        }
        let initialBehavior = FloatingPanelDefaultBehavior()

        floatingPanel = Core(self, layout: initialLayout, behavior: initialBehavior)
    }

    private func didUpdateDelegate(){
        if let layout = delegate?.floatingPanel?(self, layoutFor: traitCollection) {
            _layout = layout
        }
    }

    // MARK:- Overrides

    /// Creates the view that the controller manages.
    open override func loadView() {
        assert(self.storyboard == nil, "Storyboard isn't supported")

        let view = PassthroughView()
        view.backgroundColor = .clear

        backdropView.frame = view.bounds
        view.addSubview(backdropView)

        surfaceView.frame = view.bounds
        view.addSubview(surfaceView)

        self.view = view as UIView
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure to update the static constraint of a panel after rotating a device in static mode
        if contentMode == .static {
            floatingPanel.layoutAdapter.updateStaticConstraint()
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Need to call this method just after the view appears, as the safe area is not
        // correctly set before this time, for example, `show(animated:completion:)`.
        floatingPanel.adjustScrollContentInsetIfNeeded()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if self.view.bounds.size == size {
            return
        }

        // Change a layout for the new view size
        if let newLayout = self.delegate?.floatingPanel?(self, layoutFor: size) {
            layout = newLayout
            activateLayout(forceLayout: true)
        }

        if view.translatesAutoresizingMaskIntoConstraints {
            view.frame.size = size
            view.layoutIfNeeded()
        }
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        if shouldUpdateLayout(from: traitCollection, to: newCollection) == false {
            return
        }

        // Change a layout for the new trait collection
        if let newLayout = self.delegate?.floatingPanel?(self, layoutFor: newCollection) {
            self.layout = newLayout
            activateLayout(forceLayout: true)
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        safeAreaInsetsObservation = nil
    }

    // MARK:- Child view controller to consult
    open override var childForStatusBarStyle: UIViewController? {
        return contentViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        return contentViewController
    }

    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        return contentViewController
    }

    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return contentViewController
    }

    // MARK:- Privates

    private func shouldUpdateLayout(from previous: UITraitCollection, to new: UITraitCollection) -> Bool {
        return previous.horizontalSizeClass != new.horizontalSizeClass
            || previous.verticalSizeClass != new.verticalSizeClass
            || previous.preferredContentSizeCategory != new.preferredContentSizeCategory
            || previous.layoutDirection != new.layoutDirection
    }

    private func update(safeAreaInsets: UIEdgeInsets) {
        guard
            preSafeAreaInsets != safeAreaInsets
            else { return }

        os_log(msg, log: devLog, type: .debug, "Update safeAreaInsets = \(safeAreaInsets)")

        // Prevent an infinite loop on iOS 10: setUpLayout() -> viewDidLayoutSubviews() -> setUpLayout()
        preSafeAreaInsets = safeAreaInsets

        // preserve the current content offset if contentInsetAdjustmentBehavior is `.always`
        var contentOffset: CGPoint?
        if contentInsetAdjustmentBehavior == .always {
            contentOffset = trackingScrollView?.contentOffset
        }

        floatingPanel.layoutAdapter.updateStaticConstraint()
        floatingPanel.adjustScrollContentInsetIfNeeded()

        if let contentOffset = contentOffset {
            trackingScrollView?.contentOffset = contentOffset
        }

        switch contentInsetAdjustmentBehavior {
        case .always:
            trackingScrollView?.contentInset = adjustedContentInsets
        default:
            break
        }
    }

    private func activateLayout(forceLayout: Bool = false) {
        floatingPanel.activateLayout(
            forceLayout: forceLayout,
            contentInsetAdjustmentBehavior: contentInsetAdjustmentBehavior
        )
    }

    func remove() {
        if presentingViewController != nil, parent == nil {
            delegate?.floatingPanelWillRemove?(self)
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.delegate?.floatingPanelDidRemove?(self)
            }
        } else if parent != nil {
            removePanelFromParent(animated: true)
        } else {
            delegate?.floatingPanelWillRemove?(self)
            hide(animated: true) { [weak self] in
                guard let self = self else { return }
                self.view.removeFromSuperview()
                self.delegate?.floatingPanelDidRemove?(self)
            }
        }
    }

    // MARK: - Container view controller interface

    /// Shows the surface view at the initial position defined by the current layout
    /// - Parameters:
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
    @objc(show:completion:)
    public func show(animated: Bool = false, completion: (() -> Void)? = nil) {
        // Must apply the current layout here
        activateLayout(forceLayout: true)

        // Must track the safeAreaInsets of `self.view` to update the layout.
        // There are 2 reasons.
        // 1. This or the parent VC doesn't call viewSafeAreaInsetsDidChange() on the bottom
        // inset's update expectedly.
        // 2. The safe area top inset can be variable on the large title navigation bar(iOS11+).
        // That's why it needs the observation to keep `adjustedContentInsets` correct.
        safeAreaInsetsObservation = self.view.observe(\.safeAreaInsets, options: [.initial, .new, .old]) { [weak self] (_, change) in
            // Use `self.view.safeAreaInsets` because `change.newValue` can be nil in particular case when
            // is reported in https://github.com/SCENEE/FloatingPanel/issues/330
            guard let self = self, change.oldValue != self.view.safeAreaInsets else { return }

            // Sometimes the bounding rectangle of the controlled view becomes invalid when the screen is rotated.
            // This results in its safeAreaInsets change. In that case, `self.update(safeAreaInsets:)` leads
            // an unsatisfied constraints error. So this method should not be called with those bounds.
            guard self.view.bounds.height > 0 && self.view.bounds.width > 0 else { return }

            self.update(safeAreaInsets: self.view.safeAreaInsets)
        }

        move(to: floatingPanel.layoutAdapter.initialState,
             animated: animated,
             completion: completion)
    }

    /// Hides the surface view to the hidden position
    @objc(hide:completion:)
    public func hide(animated: Bool = false, completion: (() -> Void)? = nil) {
        move(to: .hidden,
             animated: animated,
             completion: completion)
    }

    /// Adds the view managed by the controller as a child of the specified view controller.
    /// - Parameters:
    ///     - parent: A parent view controller object that displays FloatingPanelController's view. A container view controller object isn't applicable.
    ///     - viewIndex: Insert the surface view managed by the controller below the specified view index. By default, the surface view will be added to the end of the parent list of subviews.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the presentation finishes. This block has no return value and takes no parameters. You may specify nil for this parameter.
    @objc(addPanelToParent:at:animated:completion:)
    public func addPanel(toParent parent: UIViewController, at viewIndex: Int = -1, animated: Bool = false, completion: (() -> Void)? = nil) {
        guard self.parent == nil else {
            os_log(msg, log: sysLog, type: .error, "Warning: already added to a parent(\(parent))")
            return
        }
        assert((parent is UINavigationController) == false, "UINavigationController displays only one child view controller at a time.")
        assert((parent is UITabBarController) == false, "UITabBarController displays child view controllers with a radio-style selection interface")
        assert((parent is UISplitViewController) == false, "UISplitViewController manages two child view controllers in a master-detail interface")
        assert((parent is UITableViewController) == false, "UITableViewController should not be the parent because the view is a table view so that a panel doesn't work well")
        assert((parent is UICollectionViewController) == false, "UICollectionViewController should not be the parent because the view is a collection view so that a panel doesn't work well")

        if viewIndex < 0 {
            parent.view.addSubview(self.view)
        } else {
            parent.view.insertSubview(self.view, at: viewIndex)
        }

        parent.addChild(self)

        view.frame = parent.view.bounds // Needed for a correct safe area configuration
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: 0.0),
            self.view.leftAnchor.constraint(equalTo: parent.view.leftAnchor, constant: 0.0),
            self.view.rightAnchor.constraint(equalTo: parent.view.rightAnchor, constant: 0.0),
            self.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: 0.0),
            ])

        show(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.didMove(toParent: parent)
            completion?()
        }
    }

    /// Removes the controller and the managed view from its parent view controller
    /// - Parameters:
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
    @objc(removePanelFromParent:completion:)
    public func removePanelFromParent(animated: Bool, completion: (() -> Void)? = nil) {
        guard self.parent != nil else {
            completion?()
            return
        }

        delegate?.floatingPanelWillRemove?(self)

        hide(animated: animated) { [weak self] in
            guard let self = self else { return }

            self.willMove(toParent: nil)

            self.view.removeFromSuperview()

            self.removeFromParent()

            self.delegate?.floatingPanelDidRemove?(self)
            completion?()
        }
    }

    /// Moves the position to the specified position.
    ///
    /// - Parameters:
    ///     - to: Pass a FloatingPanelPosition value to move the surface view to the position.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller has finished moving. This block has no return value and takes no parameters. You may specify nil for this parameter.
    @objc(moveToState:animated:completion:)
    public func move(to: FloatingPanelState, animated: Bool, completion: (() -> Void)? = nil) {
        floatingPanel.move(to: to, animated: animated, completion: completion)
    }

    /// Sets the view controller responsible for the content portion of a panel.
    public func set(contentViewController: UIViewController?) {
        if let vc = _contentViewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        if let vc = contentViewController {
            addChild(vc)

            let surfaceView = floatingPanel.surfaceView
            surfaceView.set(contentView: vc.view, mode: contentMode)

            vc.didMove(toParent: self)
        }

        _contentViewController = contentViewController
    }

    // MARK: - Scroll view tracking

    /// Tracks the specified scroll view to correspond with the scroll.
    ///
    /// - Parameters:
    ///     - scrollView: Specify a scroll view to continuously and seamlessly work in concert with interactions of the surface view
    @objc(trackScrollView:)
    public func track(scrollView: UIScrollView) {
        if let scrollView = floatingPanel.scrollView {
            untrack(scrollView: scrollView)
        }

        floatingPanel.scrollView = scrollView

        switch contentInsetAdjustmentBehavior {
        case .always:
            scrollView.contentInsetAdjustmentBehavior = .never
        default:
            break
        }
    }

    /// [Experimental] Allows the panel to move as its tracking scroll view bounces.
    ///
    /// This method must be called in the delegate method, `UIScrollViewDelegate.scrollViewDidScroll(_:)`,
    /// of its tracking scroll view. This method only supports a bottom positioned panel for now.
    ///
    /// - TODO: Support top, left and right positioned panels.
    public func followScrollViewBouncing() {
        floatingPanel.followScrollViewBouncing()
    }

    /// Cancel tracking the specify scroll view.
    ///
    @objc(untrackScrollView:)
    public func untrack(scrollView: UIScrollView) {
        if floatingPanel.scrollView == scrollView {
            floatingPanel.scrollView = nil
        }
    }

    // MARK: - Accessibility

    open override func accessibilityPerformEscape() -> Bool {
        guard isRemovalInteractionEnabled else { return false }
        dismiss(animated: true, completion: nil)
        return true
    }

    // MARK: - Utilities

    /// Invalidates all layout information of the panel and apply the ``layout`` property into it immediately.
    ///
    /// This lays out subviews of the view that the controller manages with the ``layout`` property by
    /// calling the view's `layoutIfNeeded()`. Thus this method can be called in an animation block to
    /// animate the panel's changes.
    ///
    /// If the controller has a delegate object, this will lay them out using the layout object returned by
    /// `floatingPanel(_:layoutFor:)` delegate method for the current `UITraitCollection`.
    @objc
    public func invalidateLayout() {
        if let newLayout = self.delegate?.floatingPanel?(self, layoutFor: traitCollection) {
            layout = newLayout
        }
        activateLayout(forceLayout: true)
    }

    /// Returns the surface's position in a panel controller's view for the specified state.
    ///
    /// If a panel is top positioned, this returns a point of the bottom-left corner of the surface. If it is left positioned
    /// this returns a point of top-right corner of the surface. If it is bottom or right positioned, this returns a point
    /// of the top-left corner of the surface.
    @objc
    public func surfaceLocation(for state: FloatingPanelState) -> CGPoint {
        return floatingPanel.layoutAdapter.surfaceLocation(for: state)
    }

    /// The surface's position in a panel controller's view.
    ///
    /// If a panel is top positioned, this returns a point of the bottom-left corner of the surface. If it is left positioned
    /// this returns a point of top-right corner of the surface. If it is bottom or right positioned, this returns a point
    /// of the top-left corner of the surface.
    @objc
    public var surfaceLocation: CGPoint {
        get { floatingPanel.layoutAdapter.surfaceLocation }
        set { floatingPanel.layoutAdapter.surfaceLocation = newValue }
    }
}

extension FloatingPanelController {
    func notifyDidMove() {
        #if !TEST
        guard self.view.window != nil else { return }
        #endif
        delegate?.floatingPanelDidMove?(self)
    }

    func animatorForPresenting(to: FloatingPanelState) -> UIViewPropertyAnimator {
        if let animator = delegate?.floatingPanel?(self, animatorForPresentingTo: to) {
            return animator
        }
        let timingParameters = UISpringTimingParameters(decelerationRate: UIScrollView.DecelerationRate.fast.rawValue,
                                                       frequencyResponse: 0.25)
        return UIViewPropertyAnimator(duration: 0.0,
                                      timingParameters: timingParameters)
    }

    func animatorForDismissing(with velocity: CGVector) -> UIViewPropertyAnimator {
        if let animator = delegate?.floatingPanel?(self, animatorForDismissingWith: velocity) {
            return animator
        }
        let timingParameters = UISpringTimingParameters(decelerationRate: UIScrollView.DecelerationRate.fast.rawValue,
                                                       frequencyResponse: 0.25,
                                                       initialVelocity: velocity)
        return UIViewPropertyAnimator(duration: 0.0,
                                      timingParameters: timingParameters)
    }
}

// MARK: - Swizzling

private var originalDismissImp: IMP?
private typealias DismissFunction = @convention(c) (AnyObject, Selector, Bool, (() -> Void)?) -> Void
extension FloatingPanelController {
    private static let dismissSwizzling: Void = {
        guard originalDismissImp == nil else { return }
        let aClass: AnyClass! = UIViewController.self //object_getClass(vc)
        if let originalMethod = class_getInstanceMethod(aClass, #selector(dismiss(animated:completion:))),
           let swizzledImp = class_getMethodImplementation(aClass, #selector(__swizzled_dismiss(animated:completion:))) {
           originalDismissImp = method_setImplementation(originalMethod, swizzledImp)
        }
    }()
}

extension UIViewController {
    @objc
    fileprivate func __swizzled_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let dismissImp = unsafeBitCast(originalDismissImp, to: DismissFunction.self)
        let sel = #selector(UIViewController.dismiss(animated:completion:))

        // Call dismiss(animated:completion:) to a content view controller
        if let fpc = parent as? FloatingPanelController {
            if fpc.presentingViewController != nil {
                dismissImp(self, sel, flag, completion)
            } else {
                fpc.removePanelFromParent(animated: flag, completion: completion)
            }
            return
        }
        // Call dismiss(animated:completion:) to FloatingPanelController directly
        if let fpc = self as? FloatingPanelController {
            // When a panel is presented modally and it's not a child view controller of the presented view controller.
            if fpc.presentingViewController != nil, fpc.parent == nil {
                dismissImp(self, sel, flag, completion)
            } else {
                fpc.removePanelFromParent(animated: flag, completion: completion)
            }
            return
        }

        // For other view controllers
        dismissImp(self, sel, flag, completion)
    }
}
