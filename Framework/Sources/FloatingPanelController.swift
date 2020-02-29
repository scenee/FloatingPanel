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

    /// Called when the floating panel has changed to a new position. Can be called inside an animation block, so any
    /// view properties set inside this function will be automatically animated alongside the panel.
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController)

    /// Asks the delegate if dragging should begin by the pan gesture recognizer.
    func floatingPanelShouldBeginDragging(_ vc: FloatingPanelController) -> Bool

    func floatingPanelDidMove(_ vc: FloatingPanelController) // any surface frame changes in dragging

    // called on start of dragging (may require some time and or distance to move)
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController)
    // called on finger up if the user dragged. velocity is in points/second.
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition)
    func floatingPanelWillBeginDecelerating(_ vc: FloatingPanelController) // called on finger up as we are moving
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) // called when scroll view grinds to a halt

    // called on start of dragging to remove its views from a parent view controller
    func floatingPanelDidEndDraggingToRemove(_ vc: FloatingPanelController, withVelocity velocity: CGPoint)
    // called when its views are removed from a parent view controller
    func floatingPanelDidEndRemove(_ vc: FloatingPanelController)

    /// Asks the delegate if the other gesture recognizer should be allowed to recognize the gesture in parallel.
    ///
    /// By default, any tap and long gesture recognizers are allowed to recognize gestures simultaneously.
    func floatingPanel(_ vc: FloatingPanelController, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool

    /// Asks the delegate for a content offset of the tracked scroll view to be pinned when a floating panel moves
    ///
    /// If you do not implement this method, the controller uses a value of the content offset plus the content insets
    /// of the tracked scroll view. Your implementation of this method can return a value for a navigation bar with a large
    /// title, for example.
    ///
    /// This method will not be called if the controller doesn't track any scroll view.
    func floatingPanel(_ vc: FloatingPanelController, contentOffsetForPinning trackedScrollView: UIScrollView) -> CGPoint
}

public extension FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return nil
    }
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return nil
    }
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {}
    func floatingPanelShouldBeginDragging(_ vc: FloatingPanelController) -> Bool {
        return true
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {}
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {}
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {}
    func floatingPanelWillBeginDecelerating(_ vc: FloatingPanelController) {}
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {}

    func floatingPanelDidEndDraggingToRemove(_ vc: FloatingPanelController, withVelocity velocity: CGPoint) {}
    func floatingPanelDidEndRemove(_ vc: FloatingPanelController) {}

    func floatingPanel(_ vc: FloatingPanelController, shouldRecognizeSimultaneouslyWith gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    func floatingPanel(_ vc: FloatingPanelController, contentOffsetForPinning trackedScrollView: UIScrollView) -> CGPoint {
        return CGPoint(x: 0.0, y: 0.0 - trackedScrollView.contentInset.top)
    }
}


public enum FloatingPanelPosition: Int {
    case full
    case half
    case tip
    case hidden

    static var allCases: [FloatingPanelPosition] {
        return [.full, .half, .tip, .hidden]
    }

    func next(in positions: [FloatingPanelPosition]) -> FloatingPanelPosition {
        #if swift(>=4.2)
        guard
            let index = positions.firstIndex(of: self),
            positions.indices.contains(index + 1)
            else { return self }
        #else
        guard
            let index = positions.index(of: self),
            positions.indices.contains(index + 1)
            else { return self }
        #endif
        return positions[index + 1]
    }

    func pre(in positions: [FloatingPanelPosition]) -> FloatingPanelPosition {
        #if swift(>=4.2)
        guard
            let index = positions.firstIndex(of: self),
            positions.indices.contains(index - 1)
            else { return self }
        #else
        guard
            let index = positions.index(of: self),
            positions.indices.contains(index - 1)
            else { return self }
        #endif
        return positions[index - 1]
    }
}

///
/// A container view controller to display a floating panel to present contents in parallel as a user wants.
///
open class FloatingPanelController: UIViewController {
    /// Constants indicating how safe area insets are added to the adjusted content inset.
    public enum ContentInsetAdjustmentBehavior: Int {
        case always
        case never
    }

    /// A flag used to determine how the controller object lays out the content view when the surface position changes.
    public enum ContentMode: Int {
        /// The option to fix the content to keep the height of the top most position.
        case `static`
        /// The option to scale the content to fit the bounds of the root view by changing the surface position.
        case fitToBounds
    }

    /// The delegate of the floating panel controller object.
    public weak var delegate: FloatingPanelControllerDelegate?{
        didSet{
            didUpdateDelegate()
        }
    }

    /// Returns the surface view managed by the controller object. It's the same as `self.view`.
    public var surfaceView: FloatingPanelSurfaceView! {
        return floatingPanel.surfaceView
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
        return floatingPanel.panGestureRecognizer
    }

    /// The current position of the floating panel controller's contents.
    public var position: FloatingPanelPosition {
        return floatingPanel.state
    }

    /// The layout object managed by the controller
    public var layout: FloatingPanelLayout {
        return floatingPanel.layoutAdapter.layout
    }

    /// The behavior object managed by the controller
    public var behavior: FloatingPanelBehavior {
        return floatingPanel.behavior
    }

    /// The content insets of the tracking scroll view derived from this safe area
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

    /// The view controller responsible for the content portion of the floating panel.
    public var contentViewController: UIViewController? {
        set { set(contentViewController: newValue) }
        get { return _contentViewController }
    }
    
    /// The NearbyPosition determines that finger's nearby position.
    public var nearbyPosition: FloatingPanelPosition {
        let currentY = surfaceView.frame.minY
        return floatingPanel.targetPosition(from: currentY, with: .zero)
    }
    
    public var contentMode: ContentMode = .static {
        didSet {
            guard position != .hidden else { return }
            activateLayout()
        }
    }

    private var _contentViewController: UIViewController?

    private(set) var floatingPanel: FloatingPanelCore!
    private var preSafeAreaInsets: UIEdgeInsets = .zero // Capture the latest one
    private var safeAreaInsetsObservation: NSKeyValueObservation?
    private let modalTransition = FloatingPanelModalTransition()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    /// Initialize a newly created floating panel controller.
    public init(delegate: FloatingPanelControllerDelegate? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        setUp()
    }

    private func setUp() {
        _ = FloatingPanelController.dismissSwizzling

        modalPresentationStyle = .custom
        transitioningDelegate = modalTransition

        floatingPanel = FloatingPanelCore(self,
                                      layout: fetchLayout(for: self.traitCollection),
                                      behavior: fetchBehavior(for: self.traitCollection))
    }

    private func didUpdateDelegate(){
        floatingPanel.layoutAdapter.layout = fetchLayout(for: traitCollection)
        floatingPanel.behavior = fetchBehavior(for: self.traitCollection)
    }

    // MARK:- Overrides

    /// Creates the view that the controller manages.
    open override func loadView() {
        assert(self.storyboard == nil, "Storyboard isn't supported")

        let view = FloatingPanelPassThroughView()
        view.backgroundColor = .clear

        backdropView.frame = view.bounds
        view.addSubview(backdropView)

        surfaceView.frame = view.bounds
        view.addSubview(surfaceView)

        self.view = view as UIView
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {}
        else {
            // Because {top,bottom}LayoutGuide is managed as a view
            if preSafeAreaInsets != layoutInsets,
                floatingPanel.isDecelerating == false {
                self.update(safeAreaInsets: layoutInsets)
            }
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if view.translatesAutoresizingMaskIntoConstraints {
            view.frame.size = size
            view.layoutIfNeeded()
        }
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.prepare(for: newCollection)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        safeAreaInsetsObservation = nil
    }

    // MARK:- Child view controller to consult
    #if swift(>=4.2)
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
    #else
    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return contentViewController
    }

    open override var childViewControllerForStatusBarHidden: UIViewController? {
        return contentViewController
    }

    open override func childViewControllerForScreenEdgesDeferringSystemGestures() -> UIViewController? {
        return contentViewController
    }

    open override func childViewControllerForHomeIndicatorAutoHidden() -> UIViewController? {
        return contentViewController
    }
    #endif

    // MARK:- Internals
    func prepare(for newCollection: UITraitCollection) {
        guard newCollection.shouldUpdateLayout(from: traitCollection) else { return }
        // Change a layout & behavior for a new trait collection
        reloadLayout(for: newCollection)
        activateLayout()
        floatingPanel.behavior = fetchBehavior(for: newCollection)
    }

    // MARK:- Privates

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
        guard
            preSafeAreaInsets != safeAreaInsets
            else { return }

        log.debug("Update safeAreaInsets", safeAreaInsets)

        // Prevent an infinite loop on iOS 10: setUpLayout() -> viewDidLayoutSubviews() -> setUpLayout()
        preSafeAreaInsets = safeAreaInsets

        activateLayout()

        switch contentInsetAdjustmentBehavior {
        case .always:
            scrollView?.contentInset = adjustedContentInsets
            scrollView?.scrollIndicatorInsets = adjustedContentInsets
        default:
            break
        }
    }

    private func reloadLayout(for traitCollection: UITraitCollection) {
        floatingPanel.layoutAdapter.layout = fetchLayout(for: traitCollection)

        if let parent = self.parent {
            if let layout = layout as? UIViewController, layout == parent {
                log.warning("A memory leak will occur by a retain cycle because \(self) owns the parent view controller(\(parent)) as the layout object. Don't let the parent adopt FloatingPanelLayout.")
            }
            if let behavior = behavior as? UIViewController, behavior == parent {
                log.warning("A memory leak will occur by a retain cycle because \(self) owns the parent view controller(\(parent)) as the behavior object. Don't let the parent adopt FloatingPanelBehavior.")
            }
        }
    }

    private func activateLayout() {
        floatingPanel.layoutAdapter.prepareLayout(in: self)

        // preserve the current content offset if contentInsetAdjustmentBehavior is `.always`
        var contentOffset: CGPoint?
        if contentInsetAdjustmentBehavior == .always {
            contentOffset = scrollView?.contentOffset
        }

        floatingPanel.layoutAdapter.updateHeight()
        floatingPanel.layoutAdapter.activateLayout(of: floatingPanel.state)

        if let contentOffset = contentOffset {
            scrollView?.contentOffset = contentOffset
        }
    }

    // MARK: - Container view controller interface

    /// Shows the surface view at the initial position defined by the current layout
    public func show(animated: Bool = false, completion: (() -> Void)? = nil) {
        // Must apply the current layout here
        reloadLayout(for: traitCollection)
        activateLayout()

        if #available(iOS 11.0, *) {
            // Must track the safeAreaInsets of `self.view` to update the layout.
            // There are 2 reasons.
            // 1. This or the parent VC doesn't call viewSafeAreaInsetsDidChange() on the bottom
            // inset's update expectedly.
            // 2. The safe area top inset can be variable on the large title navigation bar(iOS11+).
            // That's why it needs the observation to keep `adjustedContentInsets` correct.
            safeAreaInsetsObservation = self.observe(\.view.safeAreaInsets, options: [.initial, .new, .old]) { [weak self] (vc, change) in
                guard change.oldValue != change.newValue else { return }
                self?.update(safeAreaInsets: vc.layoutInsets)
            }
        } else {
            // KVOs for topLayoutGuide & bottomLayoutGuide are not effective.
            // Instead, update(safeAreaInsets:) is called at `viewDidLayoutSubviews()`
        }

        move(to: floatingPanel.layoutAdapter.layout.initialPosition,
             animated: animated,
             completion: completion)
    }

    /// Hides the surface view to the hidden position
    public func hide(animated: Bool = false, completion: (() -> Void)? = nil) {
        move(to: .hidden,
             animated: animated,
             completion: completion)
    }

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

        if let belowView = belowView {
            parent.view.insertSubview(self.view, belowSubview: belowView)
        } else {
            parent.view.addSubview(self.view)
        }

        #if swift(>=4.2)
        parent.addChild(self)
        #else
        parent.addChildViewController(self)
        #endif

        view.frame = parent.view.bounds // Needed for a correct safe area configuration
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: 0.0),
            self.view.leftAnchor.constraint(equalTo: parent.view.leftAnchor, constant: 0.0),
            self.view.rightAnchor.constraint(equalTo: parent.view.rightAnchor, constant: 0.0),
            self.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: 0.0),
            ])

        show(animated: animated) { [weak self] in
            guard let `self` = self else { return }
            #if swift(>=4.2)
            self.didMove(toParent: parent)
            #else
            self.didMove(toParentViewController: parent)
            #endif
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

        hide(animated: animated) { [weak self] in
            guard let `self` = self else { return }
            #if swift(>=4.2)
            self.willMove(toParent: nil)
            #else
            self.willMove(toParentViewController: nil)
            #endif

            self.view.removeFromSuperview()

            #if swift(>=4.2)
            self.removeFromParent()
            #else
            self.removeFromParentViewController()
            #endif

            completion?()
        }
    }

    /// Moves the position to the specified position.
    /// - Parameters:
    ///     - to: Pass a FloatingPanelPosition value to move the surface view to the position.
    ///     - animated: Pass true to animate the presentation; otherwise, pass false.
    ///     - completion: The block to execute after the view controller has finished moving. This block has no return value and takes no parameters. You may specify nil for this parameter.
    public func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        precondition(floatingPanel.layoutAdapter.vc != nil, "Use show(animated:completion)")
        floatingPanel.move(to: to, animated: animated, completion: completion)
    }

    /// Sets the view controller responsible for the content portion of the floating panel.
    public func set(contentViewController: UIViewController?) {
        if let vc = _contentViewController {
            #if swift(>=4.2)
            vc.willMove(toParent: nil)
            #else
            vc.willMove(toParentViewController: nil)
            #endif

            vc.view.removeFromSuperview()

            #if swift(>=4.2)
            vc.removeFromParent()
            #else
            vc.removeFromParentViewController()
            #endif
        }

        if let vc = contentViewController {
            #if swift(>=4.2)
            addChild(vc)
            #else
            addChildViewController(vc)
            #endif

            let surfaceView = floatingPanel.surfaceView
            surfaceView.add(contentView: vc.view)

            #if swift(>=4.2)
            vc.didMove(toParent: self)
            #else
            vc.didMove(toParentViewController: self)
            #endif
        }

        _contentViewController = contentViewController
    }

    @available(*, unavailable, renamed: "set(contentViewController:)")
    open  override func show(_ vc: UIViewController, sender: Any?) {
        if let target = self.parent?.targetViewController(forAction: #selector(UIViewController.show(_:sender:)), sender: sender) {
            target.show(vc, sender: sender)
        }
    }

    @available(*, unavailable, renamed: "set(contentViewController:)")
    open  override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if let target = self.parent?.targetViewController(forAction: #selector(UIViewController.showDetailViewController(_:sender:)), sender: sender) {
            target.showDetailViewController(vc, sender: sender)
        }
    }

    // MARK: - Scroll view tracking

    /// Tracks the specified scroll view to correspond with the scroll.
    ///
    /// - Parameters:
    ///     - scrollView: Specify a scroll view to continuously and seamlessly work in concert with interactions of the surface view or nil to cancel it.
    public func track(scrollView: UIScrollView?) {
        guard let scrollView = scrollView else {
            floatingPanel.scrollView = nil
            return
        }

        floatingPanel.scrollView = scrollView

        switch contentInsetAdjustmentBehavior {
        case .always:
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            } else {
                #if swift(>=4.2)
                children.forEach { (vc) in
                    vc.automaticallyAdjustsScrollViewInsets = false
                }
                #else
                childViewControllers.forEach { (vc) in
                    vc.automaticallyAdjustsScrollViewInsets = false
                }
                #endif
            }
        default:
            break
        }
    }

    // MARK: - Utilities

    /// Updates the layout object from the delegate and lays out the views managed
    /// by the controller immediately.
    ///
    /// This method updates the `FloatingPanelLayout` object from the delegate and
    /// then it calls `layoutIfNeeded()` of the root view to force the view
    /// to update the floating panel's layout immediately. It can be called in an
    /// animation block.
    public func updateLayout() {
        reloadLayout(for: traitCollection)
        activateLayout()
    }

    /// Returns the y-coordinate of the point at the origin of the surface view.
    public func originYOfSurface(for pos: FloatingPanelPosition) -> CGFloat {
        return floatingPanel.layoutAdapter.positionY(for: pos)
    }
}

extension FloatingPanelController {
    private static let dismissSwizzling: Any? = {
        let aClass: AnyClass! = UIViewController.self //object_getClass(vc)
        if let imp = class_getMethodImplementation(aClass, #selector(dismiss(animated:completion:))),
            let originalAltMethod = class_getInstanceMethod(aClass, #selector(fp_original_dismiss(animated:completion:))) {
            method_setImplementation(originalAltMethod, imp)
        }
        let originalMethod = class_getInstanceMethod(aClass, #selector(dismiss(animated:completion:)))
        let swizzledMethod = class_getInstanceMethod(aClass, #selector(fp_dismiss(animated:completion:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            // switch implementation..
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        return nil
    }()
}

public extension UIViewController {
    @objc func fp_original_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // Implementation will be replaced by IMP of self.dismiss(animated:completion:)
    }
    @objc func fp_dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // Call dismiss(animated:completion:) to a content view controller
        if let fpc = parent as? FloatingPanelController {
            if fpc.presentingViewController != nil {
                self.fp_original_dismiss(animated: flag, completion: completion)
            } else {
                fpc.removePanelFromParent(animated: flag, completion: completion)
            }
            return
        }
        // Call dismiss(animated:completion:) to FloatingPanelController directly
        if let fpc = self as? FloatingPanelController {
            if fpc.presentingViewController != nil {
                self.fp_original_dismiss(animated: flag, completion: completion)
            } else {
                fpc.removePanelFromParent(animated: flag, completion: completion)
            }
            return
        }

        // For other view controllers
        self.fp_original_dismiss(animated: flag, completion: completion)
    }
}
