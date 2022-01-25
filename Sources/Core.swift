// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

///
/// The presentation model of FloatingPanel
///
class Core: NSObject, UIGestureRecognizerDelegate {
    private weak var ownerVC: FloatingPanelController?

    let surfaceView: SurfaceView
    let backdropView: BackdropView
    let layoutAdapter: LayoutAdapter
    let behaviorAdapter: BehaviorAdapter

    weak var scrollView: UIScrollView? {
        didSet {
            oldValue?.panGestureRecognizer.removeTarget(self, action: nil)
            scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))
            if let cur = scrollView {
                if oldValue == nil {
                    initialScrollOffset = cur.contentOffset
                    scrollBounce = cur.bounces
                    scrollIndictorVisible = cur.showsVerticalScrollIndicator
                }
            } else {
                if let pre = oldValue {
                    pre.isDirectionalLockEnabled = false
                    pre.bounces = scrollBounce
                    pre.showsVerticalScrollIndicator = scrollIndictorVisible
                }
            }
        }
    }

    private(set) var state: FloatingPanelState = .hidden {
        didSet {
            log.debug("state changed: \(oldValue) -> \(state)")
            if let vc = ownerVC {
                vc.delegate?.floatingPanelDidChangeState?(vc)
            }
        }
    }

    let panGestureRecognizer: FloatingPanelPanGestureRecognizer
    var isRemovalInteractionEnabled: Bool = false

    fileprivate var isSuspended: Bool = false // Prevent a memory leak in the modal transition
    fileprivate var transitionAnimator: UIViewPropertyAnimator?
    fileprivate var moveAnimator: NumericSpringAnimator?

    private var initialSurfaceLocation: CGPoint = .zero
    private var initialTranslation: CGPoint = .zero
    private var initialLocation: CGPoint {
        return panGestureRecognizer.initialLocation
    }

    var interactionInProgress: Bool = false
    var isAttracting: Bool = false

    // Removal interaction
    var removalVector: CGVector = .zero

    // Scroll handling
    private var initialScrollOffset: CGPoint = .zero
    private var stopScrollDeceleration: Bool = false
    private var scrollBounce = false
    private var scrollIndictorVisible = false
    private var grabberAreaFrame: CGRect {
        return surfaceView.grabberAreaFrame
    }

    // MARK: - Interface

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        ownerVC = vc

        surfaceView = SurfaceView()
        surfaceView.backgroundColor = .white

        backdropView = BackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        layoutAdapter = LayoutAdapter(vc: vc, layout: layout)
        behaviorAdapter = BehaviorAdapter(vc: vc, behavior: behavior)

        panGestureRecognizer = FloatingPanelPanGestureRecognizer()

        if #available(iOS 11.0, *) {
            panGestureRecognizer.name = "FloatingPanelPanGestureRecognizer"
        }

        super.init()

        panGestureRecognizer.floatingPanel = self
        surfaceView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))
        panGestureRecognizer.delegate = self

        // Set tap-to-dismiss in the backdrop view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
        tapGesture.isEnabled = false
        backdropView.dismissalTapGestureRecognizer = tapGesture
        backdropView.addGestureRecognizer(tapGesture)
    }

    deinit {
        // Release `NumericSpringAnimator.displayLink` from the run loop.
        self.moveAnimator?.stopAnimation(false)
    }

    func move(to: FloatingPanelState, animated: Bool, completion: (() -> Void)? = nil) {
        move(from: state, to: to, animated: animated, completion: completion)
    }

    private func move(from: FloatingPanelState, to: FloatingPanelState, animated: Bool, completion: (() -> Void)? = nil) {
        assert(layoutAdapter.validStates.contains(to), "Can't move to '\(to)' state because it's not valid in the layout")
        guard let vc = ownerVC else {
            completion?()
            return
        }
        if state != layoutAdapter.mostExpandedState {
            lockScrollView()
        }
        tearDownActiveInteraction()

        interruptAnimationIfNeeded()

        if animated {
            let updateScrollView: () -> Void = { [weak self] in
                guard let self = self else { return }
                if self.state == self.layoutAdapter.mostExpandedState, abs(self.layoutAdapter.offsetFromMostExpandedAnchor) <= 1.0 {
                    self.unlockScrollView()
                } else {
                    self.lockScrollView()
                }
            }

            let animator: UIViewPropertyAnimator
            switch (from, to) {
            case (.hidden, let to):
                animator = vc.animatorForPresenting(to: to)
            case (_, .hidden):
                let animationVector = CGVector(dx: abs(removalVector.dx), dy: abs(removalVector.dy))
                animator = vc.animatorForDismissing(with: animationVector)
            default:
                move(to: to, with: 0) { [weak self] in
                    guard let self = self else { return }

                    self.moveAnimator = nil
                    updateScrollView()
                    completion?()
                }
                return
            }

            let shouldDoubleLayout = from == .hidden
                && surfaceView.hasStackView()
                && layoutAdapter.isIntrinsicAnchor(state: to)

            animator.addAnimations { [weak self] in
                guard let self = self else { return }

                self.state = to
                self.updateLayout(to: to)

                if shouldDoubleLayout {
                    log.info("Lay out the surface again to modify an intrinsic size error according to UIStackView")
                    self.updateLayout(to: to)
                }
            }
            animator.addCompletion { [weak self] _ in
                guard let self = self else { return }

                self.transitionAnimator = nil
                updateScrollView()
                self.ownerVC?.notifyDidMove()
                completion?()
            }
            self.transitionAnimator = animator
            if isSuspended {
                return
            }
            animator.startAnimation()
        } else {
            self.state = to
            self.updateLayout(to: to)
            if self.state == self.layoutAdapter.mostExpandedState {
                self.unlockScrollView()
            } else {
                self.lockScrollView()

            }
            ownerVC?.notifyDidMove()
            completion?()
        }
    }

    // MARK: - Layout update

    func activateLayout(forceLayout: Bool = false,
                        contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior) {
        layoutAdapter.prepareLayout()

        // preserve the current content offset if contentInsetAdjustmentBehavior is `.always`
        var contentOffset: CGPoint?
        if contentInsetAdjustmentBehavior == .always {
            contentOffset = scrollView?.contentOffset
        }

        layoutAdapter.updateStaticConstraint()
        layoutAdapter.activateLayout(for: state, forceLayout: true)

        // Update the backdrop alpha only when called in `Controller.show(animated:completion:)`
        // Because that prevents a backdrop flicking just before presenting a panel(#466).
        if forceLayout {
            backdropView.alpha = getBackdropAlpha(for: state)
        }

        if let contentOffset = contentOffset {
            scrollView?.contentOffset = contentOffset
        }
    }

    private func updateLayout(to target: FloatingPanelState) {
        self.layoutAdapter.activateLayout(for: target, forceLayout: true)
        self.backdropView.alpha = self.getBackdropAlpha(for: target)
    }

    private func getBackdropAlpha(for target: FloatingPanelState) -> CGFloat {
        return target == .hidden ? 0.0 : layoutAdapter.backdropAlpha(for: target)
    }

    func getBackdropAlpha(at cur: CGFloat, with translation: CGFloat) -> CGFloat {
        /* log.debug("currentY: \(currentY) translation: \(translation)") */
        let forwardY = (translation >= 0)

        let segment = layoutAdapter.segment(at: cur, forward: forwardY)

        let lowerState = segment.lower ?? layoutAdapter.mostExpandedState
        let upperState = segment.upper ?? layoutAdapter.leastExpandedState

        let preState = forwardY ? lowerState : upperState
        let nextState = forwardY ? upperState : lowerState

        let next = value(of: layoutAdapter.surfaceLocation(for: nextState))
        let pre = value(of: layoutAdapter.surfaceLocation(for: preState))

        let nextAlpha = layoutAdapter.backdropAlpha(for: nextState)
        let preAlpha = layoutAdapter.backdropAlpha(for: preState)

        if pre == next {
            return preAlpha
        }
        return preAlpha + max(min(1.0, 1.0 - (next - cur) / (next - pre) ), 0.0) * (nextAlpha - preAlpha)
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let result = panGestureRecognizer.delegateProxy?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) {
            return result
        }

        guard gestureRecognizer == panGestureRecognizer else { return false }

        /* log.debug("shouldRecognizeSimultaneouslyWith", otherGestureRecognizer) */

        switch otherGestureRecognizer {
        case is FloatingPanelPanGestureRecognizer:
            // All visible panels' pan gesture should be recognized simultaneously.
            return true
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            if grabberAreaFrame.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
                return true
            }
            // all gestures of the tracking scroll view should be recognized in parallel
            // and handle them in self.handle(panGesture:)
            return scrollView?.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
        default:
            // Should recognize tap/long press gestures in parallel when the surface view is at an anchor position.
            let adapterY = layoutAdapter.position(for: state)
            return abs(value(of: layoutAdapter.surfaceLocation) - adapterY) < (1.0 / surfaceView.fp_displayScale)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let result = panGestureRecognizer.delegateProxy?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) {
            return result
        }

        if otherGestureRecognizer is FloatingPanelPanGestureRecognizer {
            // If this panel is the farthest descendant of visible panels,
            // its ancestors' pan gesture must wait for its pan gesture to fail
            if let view = otherGestureRecognizer.view, surfaceView.isDescendant(of: view) {
                return true
            }
        }
        if #available(iOS 11.0, *),
            otherGestureRecognizer.name == "_UISheetInteractionBackgroundDismissRecognizer" {
            // The dismiss gesture of a sheet modal should not begin until the pan gesture fails.
            return true
        }

        if grabberAreaFrame.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
            return true
        }

        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let result = panGestureRecognizer.delegateProxy?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) {
            return result
        }

        guard gestureRecognizer == panGestureRecognizer else { return false }

        // Should begin the pan gesture without waiting for the tracking scroll view's gestures.
        // `scrollView.gestureRecognizers` can contains the following gestures
        // * UIScrollViewDelayedTouchesBeganGestureRecognizer
        // * UIScrollViewPanGestureRecognizer (scrollView.panGestureRecognizer)
        // * _UIDragAutoScrollGestureRecognizer
        // * _UISwipeActionPanGestureRecognizer
        // * UISwipeDismissalGestureRecognizer
        if let scrollView = scrollView {
            // On short contents scroll, `_UISwipeActionPanGestureRecognizer` blocks
            // the panel's pan gesture if not returns false
            if let scrollGestureRecognizers = scrollView.gestureRecognizers,
                scrollGestureRecognizers.contains(otherGestureRecognizer) {
                switch otherGestureRecognizer {
                case scrollView.panGestureRecognizer:
                    if grabberAreaFrame.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
                        return false
                    }
                    return allowScrollPanGesture(for: scrollView)
                default:
                    return false
                }
            }
        }

        switch otherGestureRecognizer {
        case is FloatingPanelPanGestureRecognizer:
            // If this panel is the farthest descendant of visible panels,
            // its pan gesture does not require its ancestors' pan gesture to fail
            if let view = otherGestureRecognizer.view, surfaceView.isDescendant(of: view) {
                return false
            }
            return true
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            if #available(iOS 11.0, *),
                otherGestureRecognizer.name == "_UISheetInteractionBackgroundDismissRecognizer" {
                // Should begin the pan gesture without waiting the dismiss gesture of a sheet modal.
                return false
            }
            if grabberAreaFrame.contains(gestureRecognizer.location(in: gestureRecognizer.view)) {
                return false
            }
            // Do not begin the pan gesture until these gestures fail
            return true
        default:
            // Should begin the pan gesture without waiting tap/long press gestures fail
            return false
        }
    }

    // MARK: - Gesture handling

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        removalVector = .zero
        ownerVC?.remove()
    }

    @objc func handle(panGesture: UIPanGestureRecognizer) {
        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }

            let velocity = value(of: panGesture.velocity(in: panGesture.view))
            let location = panGesture.location(in: surfaceView)

            let belowEdgeMost = 0 > layoutAdapter.offsetFromMostExpandedAnchor + (1.0 / surfaceView.fp_displayScale)

            log.debug("""
                scroll gesture(\(state):\(panGesture.state)) -- \
                belowTop = \(belowEdgeMost), \
                interactionInProgress = \(interactionInProgress), \
                scroll offset = \(value(of: scrollView.contentOffset)), \
                location = \(value(of: location)), velocity = \(velocity)
                """)

            let offsetDiff = value(of: scrollView.contentOffset - contentOffsetForPinning(of: scrollView))

            if belowEdgeMost {
                // Scroll offset pinning
                if state == layoutAdapter.mostExpandedState {
                    if interactionInProgress {
                        log.debug("settle offset --", value(of: initialScrollOffset))
                        stopScrolling(at: initialScrollOffset)
                    } else {
                        if grabberAreaFrame.contains(location) {
                            // Preserve the current content offset in moving from full.
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                } else {
                    stopScrolling(at: initialScrollOffset)
                }

                // Hide a scroll indicator at the non-top in dragging.
                if interactionInProgress {
                    lockScrollView()
                } else {
                    if state == layoutAdapter.mostExpandedState, self.transitionAnimator == nil {
                        switch layoutAdapter.position {
                        case .top, .left:
                            if offsetDiff < 0 && velocity > 0 {
                                unlockScrollView()
                            }
                        case .bottom, .right:
                            if offsetDiff > 0 && velocity < 0 {
                                unlockScrollView()
                            }
                        }
                    }
                }
            } else {
                if interactionInProgress {
                    // Show a scroll indicator at the top in dragging.
                    switch layoutAdapter.position {
                    case .top, .left:
                        if offsetDiff <= 0 && velocity >= 0 {
                            unlockScrollView()
                            return
                        }
                    case .bottom, .right:
                        if offsetDiff >= 0 && velocity <= 0 {
                            unlockScrollView()
                            return
                        }
                    }
                    if state == layoutAdapter.mostExpandedState {
                        // Adjust a small gap of the scroll offset just after swiping down starts in the grabber area.
                        if grabberAreaFrame.contains(location), grabberAreaFrame.contains(initialLocation) {
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                } else {
                    if state == layoutAdapter.mostExpandedState {
                        switch layoutAdapter.position {
                        case .top, .left:
                            if velocity < 0, !allowScrollPanGesture(for: scrollView) {
                                lockScrollView()
                            }
                            if velocity > 0, allowScrollPanGesture(for: scrollView) {
                                unlockScrollView()
                            }
                        case .bottom, .right:
                            // Hide a scroll indicator just before starting an interaction by swiping a panel down.
                            if velocity > 0, !allowScrollPanGesture(for: scrollView) {
                                lockScrollView()
                            }
                            // Show a scroll indicator when an animation is interrupted at the top and content is scrolled up
                            if velocity < 0, allowScrollPanGesture(for: scrollView) {
                                unlockScrollView()
                            }
                        }
                        // Adjust a small gap of the scroll offset just before swiping down starts in the grabber area,
                        if grabberAreaFrame.contains(location), grabberAreaFrame.contains(initialLocation) {
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                }
            }
        case panGestureRecognizer:
            let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
            let velocity = panGesture.velocity(in: panGesture.view)
            let location = panGesture.location(in: panGesture.view)

            log.debug("""
                panel gesture(\(state):\(panGesture.state)) -- \
                translation =  \(value(of: translation)), \
                location = \(value(of: location)), \
                velocity = \(value(of: velocity))
                """)

            if interactionInProgress == false, isAttracting == false,
                let vc = ownerVC, vc.delegate?.floatingPanelShouldBeginDragging?(vc) == false {
                return
            }

            interruptAnimationIfNeeded()

            if panGesture.state == .began {
                panningBegan(at: location)
                return
            }

            if shouldScrollViewHandleTouch(scrollView, point: location, velocity: value(of: velocity)) {
                return
            }

            switch panGesture.state {
            case .changed:
                if interactionInProgress == false {
                    startInteraction(with: translation, at: location)
                }
                panningChange(with: translation)
            case .ended, .cancelled, .failed:
                if interactionInProgress == false {
                    startInteraction(with: translation, at: location)
                    // Workaround: Prevent stopping the surface view b/w anchors if the pan gesture
                    // doesn't pass through .changed state after an interruptible animator is interrupted.
                    let diff = translation - .leastNonzeroMagnitude
                    layoutAdapter.updateInteractiveEdgeConstraint(diff: value(of: diff),
                                                                  overflow: true,
                                                                  allowsRubberBanding: behaviorAdapter.allowsRubberBanding(for:))
                }
                panningEnd(with: translation, velocity: velocity)
            default:
                break
            }
        default:
            return
        }
    }

    private func interruptAnimationIfNeeded() {
        if let animator = self.moveAnimator, animator.isRunning {
            log.debug("the attraction animator interrupted!!!")
            animator.stopAnimation(true)
            endAttraction(false)
        }
        if let animator = self.transitionAnimator {
            guard 0 >= layoutAdapter.offsetFromMostExpandedAnchor else { return }
            log.debug("a panel animation(interruptible: \(animator.isInterruptible)) interrupted!!!")
            if animator.isInterruptible {
                animator.stopAnimation(false)
                // A user can stop a panel at the nearest Y of a target position so this fine-tunes
                // the a small gap between the presentation layer frame and model layer frame
                // to unlock scroll view properly at finishAnimation(at:)
                if abs(layoutAdapter.offsetFromMostExpandedAnchor) <= 1.0 {
                    layoutAdapter.surfaceLocation = layoutAdapter.surfaceLocation(for: layoutAdapter.mostExpandedState)
                }
                animator.finishAnimation(at: .current)
            } else {
                animator.stopAnimation(true)
            }
        }
    }

    private func shouldScrollViewHandleTouch(_ scrollView: UIScrollView?, point: CGPoint, velocity: CGFloat) -> Bool {
        // When no scrollView, nothing to handle.
        guard let scrollView = scrollView else { return false }

        // For _UISwipeActionPanGestureRecognizer
        if let scrollGestureRecognizers = scrollView.gestureRecognizers {
            for gesture in scrollGestureRecognizers {
                guard gesture.state == .began || gesture.state == .changed
                else { continue }

                if gesture != scrollView.panGestureRecognizer {
                    return true
                }
            }
        }

        guard
            state == layoutAdapter.mostExpandedState,  // When not top most(i.e. .full), don't scroll.
            interactionInProgress == false,        // When interaction already in progress, don't scroll.
            0 == layoutAdapter.offsetFromMostExpandedAnchor
        else {
            return false
        }

        // When the current point is within grabber area but the initial point is not, do scroll.
        if grabberAreaFrame.contains(point), !grabberAreaFrame.contains(initialLocation) {
            return true
        }

        // When the initial point is within grabber area and the current point is out of surface, don't scroll.
        if grabberAreaFrame.contains(initialLocation), !surfaceView.frame.contains(point) {
            return false
        }

        let scrollViewFrame = scrollView.convert(scrollView.bounds, to: surfaceView)
        guard
            scrollViewFrame.contains(initialLocation), // When the initial point not in scrollView, don't scroll.
            !grabberAreaFrame.contains(point)          // When point within grabber area, don't scroll.
        else {
            return false
        }

        let offset = value(of: scrollView.contentOffset - contentOffsetForPinning(of: scrollView))
        // The zero offset must be excluded because the offset is usually zero
        // after a panel moves from half/tip to full.
        switch layoutAdapter.position {
        case .top, .left:
            if  offset < 0.0 {
                return true
            }
            if velocity >= 0 {
                return true
            }
        case .bottom, .right:
            if  offset > 0.0 {
                return true
            }
            if velocity <= 0 {
                return true
            }
        }

        if scrollView.isDecelerating {
            return true
        }
        if let tableView = (scrollView as? UITableView), tableView.isEditing {
            return true
        }

        return false
    }

    private func panningBegan(at location: CGPoint) {
        // A user interaction does not always start from Began state of the pan gesture
        // because it can be recognized in scrolling a content in a content view controller.
        // So here just preserve the current state if needed.
        log.debug("panningBegan -- location = \(value(of: location))")

        guard let scrollView = scrollView else { return }
        if state == layoutAdapter.mostExpandedState {
            if grabberAreaFrame.contains(location) {
                initialScrollOffset = scrollView.contentOffset
            }
        } else {
            initialScrollOffset = scrollView.contentOffset
        }
    }

    private func panningChange(with translation: CGPoint) {
        log.debug("panningChange -- translation = \(value(of: translation))")
        let pre = value(of: layoutAdapter.surfaceLocation)
        let diff = value(of: translation - initialTranslation)
        let next = pre + diff
        let overflow = shouldOverflow(from: pre, to: next)

        layoutAdapter.updateInteractiveEdgeConstraint(diff: diff,
                                                      overflow: overflow,
                                                      allowsRubberBanding: behaviorAdapter.allowsRubberBanding(for:))

        let cur = value(of: layoutAdapter.surfaceLocation)

        backdropView.alpha = getBackdropAlpha(at: cur, with: value(of: translation))

        guard (pre != cur) else { return }

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidMove?(vc)
        }
    }

    private func shouldOverflow(from pre: CGFloat, to next: CGFloat) -> Bool {
        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed {
            switch layoutAdapter.position {
            case .top:
                if pre > .zero, pre < next,
                    scrollView.contentSize.height > scrollView.bounds.height || scrollView.alwaysBounceVertical {
                    return false
                }
            case .left:
                if pre > .zero, pre < next,
                    scrollView.contentSize.width > scrollView.bounds.width || scrollView.alwaysBounceHorizontal {
                    return false
                }
            case .bottom:
                if pre > .zero, pre > next,
                    scrollView.contentSize.height > scrollView.bounds.height || scrollView.alwaysBounceVertical {
                    return false
                }
            case .right:
                if pre > .zero, pre > next,
                    scrollView.contentSize.width > scrollView.bounds.width || scrollView.alwaysBounceHorizontal {
                    return false
                }
            }
        }
        return true
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        log.debug("panningEnd -- translation = \(value(of: translation)), velocity = \(value(of: velocity))")

        if state == .hidden {
            log.debug("Already hidden")
            return
        }

        stopScrollDeceleration = (0 > layoutAdapter.offsetFromMostExpandedAnchor + (1.0 / surfaceView.fp_displayScale)) // Projecting the dragging to the scroll dragging or not
        if stopScrollDeceleration {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.stopScrolling(at: self.initialScrollOffset)
            }
        }

        let currentPos = value(of: layoutAdapter.surfaceLocation)
        let mainVelocity = value(of: velocity)
        var targetPosition = self.targetPosition(from: currentPos, with: mainVelocity)

        endInteraction(for: targetPosition)

        if isRemovalInteractionEnabled {
            let distToHidden = CGFloat(abs(currentPos - layoutAdapter.position(for: .hidden)))
            switch layoutAdapter.position {
            case .top, .bottom:
                removalVector = (distToHidden != 0) ? CGVector(dx: 0.0, dy: velocity.y/distToHidden) : .zero
            case .left, .right:
                removalVector = (distToHidden != 0) ? CGVector(dx: velocity.x/distToHidden, dy: 0.0) : .zero
            }
            if shouldRemove(with: removalVector) {
                ownerVC?.remove()
                return
            }
        }

        if let vc = ownerVC {
            vc.delegate?.floatingPanelWillEndDragging?(vc, withVelocity: velocity, targetState: &targetPosition)
        }

        guard shouldAttract(to: targetPosition) else {
            if let vc = ownerVC {
                vc.delegate?.floatingPanelDidEndDragging?(vc, willAttract: false)
            }

            self.state = targetPosition
            self.updateLayout(to: targetPosition)
            self.unlockScrollView()
            return
        }

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidEndDragging?(vc, willAttract: true)
        }

        // Workaround: Disable a tracking scroll to prevent bouncing a scroll content in a panel animating
        let isScrollEnabled = scrollView?.isScrollEnabled
        if let scrollView = scrollView, targetPosition != layoutAdapter.mostExpandedState {
            scrollView.isScrollEnabled = false
        }

        startAttraction(to: targetPosition, with: velocity)

        // Workaround: Reset `self.scrollView.isScrollEnabled`
        if let scrollView = scrollView, targetPosition != layoutAdapter.mostExpandedState,
            let isScrollEnabled = isScrollEnabled {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }

    // MARK: - Behavior

    private func shouldRemove(with velocityVector: CGVector) -> Bool {
        guard let vc = ownerVC else { return false }
        if let result = vc.delegate?.floatingPanel?(vc, shouldRemoveAt: vc.surfaceLocation, with: velocityVector) {
            return result
        }
        let threshold = behaviorAdapter.removalInteractionVelocityThreshold
        switch layoutAdapter.position {
        case .top:
            return (velocityVector.dy <= -threshold)
        case .left:
            return (velocityVector.dx <= -threshold)
        case .bottom:
            return (velocityVector.dy >= threshold)
        case .right:
            return (velocityVector.dx >= threshold)
        }
    }

    private func startInteraction(with translation: CGPoint, at location: CGPoint) {
        /* Don't lock a scroll view to show a scroll indicator after hitting the top */
        log.debug("startInteraction  -- translation = \(value(of: translation)), location = \(value(of: location))")
        guard interactionInProgress == false else { return }

        var offset: CGPoint = .zero

        initialSurfaceLocation = layoutAdapter.surfaceLocation
        if state == layoutAdapter.mostExpandedState, let scrollView = scrollView {
            if grabberAreaFrame.contains(location) {
                initialScrollOffset = scrollView.contentOffset
            } else {
                initialScrollOffset = scrollView.contentOffset
                let offsetDiff = scrollView.contentOffset - contentOffsetForPinning(of: scrollView)
                switch layoutAdapter.position {
                case .top, .left:
                    // Fit the surface bounds to a scroll offset content by startInteraction(at:offset:)
                    if value(of: offsetDiff) > 0 {
                        offset = -offsetDiff
                    }
                case .bottom, .right:
                    // Fit the surface bounds to a scroll offset content by startInteraction(at:offset:)
                    if value(of: offsetDiff) < 0 {
                        offset = -offsetDiff
                    }
                }
            }
            log.debug("initial scroll offset --", initialScrollOffset)
        }

        initialTranslation = translation

        if let vc = ownerVC {
            vc.delegate?.floatingPanelWillBeginDragging?(vc)
        }

        layoutAdapter.startInteraction(at: state, offset: offset)

        interactionInProgress = true

        lockScrollView()
    }

    private func endInteraction(for targetPosition: FloatingPanelState) {
        log.debug("endInteraction to \(targetPosition)")

        if let scrollView = scrollView {
            log.debug("endInteraction -- scroll offset = \(scrollView.contentOffset)")
        }

        interactionInProgress = false

        // Prevent to keep a scroll view indicator visible at the half/tip position
        if targetPosition != layoutAdapter.mostExpandedState {
            lockScrollView()
        }

        layoutAdapter.endInteraction(at: targetPosition)
    }

    private func tearDownActiveInteraction() {
        guard panGestureRecognizer.isEnabled else { return }
        // Cancel the pan gesture so that panningEnd(with:velocity:) is called
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
    }

    private func shouldAttract(to targetState: FloatingPanelState) -> Bool {
        if layoutAdapter.position(for: targetState) == value(of: layoutAdapter.surfaceLocation) {
            return false
        }
        return true
    }

    private func startAttraction(to targetPosition: FloatingPanelState, with velocity: CGPoint) {
        log.debug("startAnimation to \(targetPosition) -- velocity = \(value(of: velocity))")
        guard let vc = ownerVC else { return }

        isAttracting = true
        vc.delegate?.floatingPanelWillBeginAttracting?(vc, to: targetPosition)
        move(to: targetPosition, with: value(of: velocity)) {
            self.endAttraction(true)
        }
    }

    private func move(to targetPosition: FloatingPanelState, with velocity: CGFloat, completion: @escaping (() -> Void)) {
        let (animationConstraint, target) = layoutAdapter.setUpAttraction(to: targetPosition)
        let initialData = NumericSpringAnimator.Data(value: animationConstraint.constant, velocity: velocity)
        moveAnimator = NumericSpringAnimator(
            initialData: initialData,
            target: target,
            displayScale: surfaceView.fp_displayScale,
            decelerationRate: behaviorAdapter.springDecelerationRate,
            responseTime: behaviorAdapter.springResponseTime,
            update: { [weak self] data in
                guard let self = self,
                      let ownerVC = self.ownerVC // Ensure the owner vc is existing for `layoutAdapter.surfaceLocation`
                else { return }
                animationConstraint.constant = data.value
                let current = self.value(of: self.layoutAdapter.surfaceLocation)
                let translation = data.value - initialData.value
                self.backdropView.alpha = self.getBackdropAlpha(at: current, with: translation)
                ownerVC.notifyDidMove()
        },
            completion: { [weak self] in
                guard let self = self,
                      self.ownerVC != nil else { return }
                self.updateLayout(to: targetPosition)
                completion()
        })
        moveAnimator?.startAnimation()
        state = targetPosition
    }

    private func endAttraction(_ finished: Bool) {
        self.isAttracting = false
        self.moveAnimator = nil

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidEndAttracting?(vc)
        }

        if let scrollView = scrollView {
            log.debug("finishAnimation -- scroll offset = \(scrollView.contentOffset)")
        }

        stopScrollDeceleration = false

        log.debug("""
            finishAnimation -- state = \(state) \
            surface location = \(layoutAdapter.surfaceLocation) \
            edge most position = \(layoutAdapter.surfaceLocation(for: layoutAdapter.mostExpandedState))
            """)
        if finished, state == layoutAdapter.mostExpandedState, abs(layoutAdapter.offsetFromMostExpandedAnchor) <= 1.0 {
            unlockScrollView()
        }
    }

    func value(of point: CGPoint) -> CGFloat {
        return layoutAdapter.position.mainLocation(point)
    }

    func setValue(_ newValue: CGPoint, to point: inout CGPoint) {
        switch layoutAdapter.position {
        case .top, .bottom:
            point.y = newValue.y
        case .left, .right:
            point.x = newValue.x
        }
    }

    // Distance travelled after decelerating to zero velocity at a constant rate.
    // Refer to the slides p176 of [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/)
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }

    func targetPosition(from currentY: CGFloat, with velocity: CGFloat) -> (FloatingPanelState) {
        log.debug("targetPosition -- currentY = \(currentY), velocity = \(velocity)")

        let sortedPositions = layoutAdapter.sortedAnchorStatesByCoordinate

        guard sortedPositions.count > 1 else {
            return state
        }

        // Projection
        let decelerationRate = behaviorAdapter.momentumProjectionRate
        let baseY = abs(layoutAdapter.position(for: layoutAdapter.leastExpandedState) - layoutAdapter.position(for: layoutAdapter.mostExpandedState))
        let vecY = velocity / baseY
        var pY = project(initialVelocity: vecY, decelerationRate: decelerationRate) * baseY + currentY

        let distance = (currentY - layoutAdapter.position(for: state))
        let forwardY = velocity == 0 ? distance > 0 : velocity > 0

        let segment = layoutAdapter.segment(at: pY, forward: forwardY)

        var fromPos: FloatingPanelState
        var toPos: FloatingPanelState

        let (lowerPos, upperPos) = (segment.lower ?? sortedPositions.first!, segment.upper ?? sortedPositions.last!)
        (fromPos, toPos) = forwardY ? (lowerPos, upperPos) : (upperPos, lowerPos)

        if behaviorAdapter.shouldProjectMomentum(to: toPos) == false {
            log.debug("targetPosition -- negate projection: distance = \(distance)")
            let segment = layoutAdapter.segment(at: currentY, forward: forwardY)
            var (lowerPos, upperPos) = (segment.lower ?? sortedPositions.first!, segment.upper ?? sortedPositions.last!)
            // Equate the segment out of {top,bottom} most state to the {top,bottom} most segment
            if lowerPos == upperPos {
                if forwardY {
                    upperPos = lowerPos.next(in: sortedPositions)
                } else {
                    lowerPos = lowerPos.pre(in: sortedPositions)
                }
            }
            (fromPos, toPos) = forwardY ? (lowerPos, upperPos) : (upperPos, lowerPos)
            // Block a projection to a segment over the next from the current segment
            // (= Trim pY with the current segment)
            if forwardY {
                pY = max(min(pY, layoutAdapter.position(for: toPos.next(in: sortedPositions))), layoutAdapter.position(for: fromPos))
            } else {
                pY = max(min(pY, layoutAdapter.position(for: fromPos)), layoutAdapter.position(for: toPos.pre(in: sortedPositions)))
            }
        }

        // Redirection
        let redirectionalProgress = max(min(behaviorAdapter.redirectionalProgress(from: fromPos, to: toPos), 1.0), 0.0)
        let progress = abs(pY - layoutAdapter.position(for: fromPos)) / abs(layoutAdapter.position(for: fromPos) - layoutAdapter.position(for: toPos))
        return progress > redirectionalProgress ? toPos : fromPos
    }

    // MARK: - ScrollView handling

    private func lockScrollView() {
        guard let scrollView = scrollView else { return }

        if scrollView.isLocked {
            log.debug("Already scroll locked.")
            return
        }
        log.debug("lock scroll view")

        scrollBounce = scrollView.bounces
        scrollIndictorVisible = scrollView.showsVerticalScrollIndicator

        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
    }

    private func unlockScrollView() {
        guard let scrollView = scrollView, scrollView.isLocked else { return }
        log.debug("unlock scroll view")

        scrollView.isDirectionalLockEnabled = false
        scrollView.bounces = scrollBounce
        scrollView.showsVerticalScrollIndicator = scrollIndictorVisible
    }

    private func stopScrolling(at contentOffset: CGPoint) {
        // Must use setContentOffset(_:animated) to force-stop deceleration
        guard let scrollView = scrollView else { return }
        var offset = scrollView.contentOffset
        setValue(contentOffset, to: &offset)
        scrollView.setContentOffset(offset, animated: false)
    }

    private func contentOffsetForPinning(of scrollView: UIScrollView) -> CGPoint {
        if let vc = ownerVC, let origin = vc.delegate?.floatingPanel?(vc, contentOffsetForPinning: scrollView) {
            return origin
        }
        switch layoutAdapter.position {
        case .top:
            return CGPoint(x: 0.0, y: scrollView.fp_contentOffsetMax.y)
        case .left:
            return CGPoint(x: scrollView.fp_contentOffsetMax.x, y: 0.0)
        case .bottom:
            return CGPoint(x: 0.0, y: 0.0 - scrollView.fp_contentInset.top)
        case .right:
            return CGPoint(x: 0.0 - scrollView.fp_contentInset.left, y: 0.0)
        }
    }

    private func allowScrollPanGesture(for scrollView: UIScrollView) -> Bool {
        guard state == layoutAdapter.mostExpandedState else { return false }
        var offsetY: CGFloat = 0
        switch layoutAdapter.position {
        case .top, .left:
            offsetY = value(of: scrollView.fp_contentOffsetMax - scrollView.contentOffset)
        case .bottom, .right:
            offsetY = value(of: scrollView.contentOffset - contentOffsetForPinning(of: scrollView))
        }
        return offsetY <= -30.0 || offsetY > 0
    }

    // MARK: - UIPanGestureRecognizer Intermediation
    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || panGestureRecognizer.delegateProxy?.responds(to: aSelector) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if panGestureRecognizer.delegateProxy?.responds(to: aSelector) == true {
            return panGestureRecognizer.delegateProxy
        }
        return super.forwardingTarget(for: aSelector)
    }
}

/// A gesture recognizer that looks for panning (dragging) gestures in a panel.
public final class FloatingPanelPanGestureRecognizer: UIPanGestureRecognizer {
    fileprivate weak var floatingPanel: Core?
    fileprivate var initialLocation: CGPoint = .zero

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialLocation = touches.first?.location(in: view) ?? .zero
        if floatingPanel?.transitionAnimator != nil || floatingPanel?.moveAnimator != nil {
            self.state = .began
        }
    }
    /// The delegate of the gesture recognizer.
    ///
    /// - Note: The delegate is used by FloatingPanel itself. If you set your own delegate object, an
    /// exception is raised. If you want to handle the methods of UIGestureRecognizerDelegate, you can use `delegateProxy`.
    public override weak var delegate: UIGestureRecognizerDelegate? {
        get {
            return super.delegate
        }
        set {
            guard newValue is Core else {
                let exception = NSException(name: .invalidArgumentException,
                                            reason: "FloatingPanelController's built-in pan gesture recognizer must have its controller as its delegate. Use 'delegateProxy' property.",
                                            userInfo: nil)
                exception.raise()
                return
            }
            super.delegate = newValue
        }
    }

    /// An object to intercept the delegate of the gesture recognizer.
    ///
    /// If an object adopting `UIGestureRecognizerDelegate` is set, the delegate methods are proxied to it.
    public weak var delegateProxy: UIGestureRecognizerDelegate? {
        didSet {
            self.delegate = floatingPanel // Update the cached IMP
        }
    }
}

// MARK: - Animator

private class NumericSpringAnimator: NSObject {
    struct Data {
        let value: CGFloat
        let velocity: CGFloat
    }

    private class UnfairLock {
        var unfairLock = os_unfair_lock()
        func lock() {
            os_unfair_lock_lock(&unfairLock);
        }
        func tryLock() -> Bool {
            return os_unfair_lock_trylock(&unfairLock);
        }
        func unlock() {
            os_unfair_lock_unlock(&unfairLock);
        }
    }

    private(set) var isRunning = false

    private var lock = UnfairLock()

    private lazy var displayLink = CADisplayLink(target: self, selector: #selector(update(_:)))

    private var data: Data

    private let target: CGFloat
    private let displayScale: CGFloat
    private let zeta: CGFloat
    private let omega: CGFloat

    private let update: ((_ data: Data) -> Void)
    private let completion: (() -> Void)

    init(initialData: Data,
         target: CGFloat,
         displayScale: CGFloat,
         decelerationRate: CGFloat,
         responseTime: CGFloat,
         update: @escaping ((_ data: Data) -> Void),
         completion: @escaping (() -> Void)) {

        self.data = initialData
        self.target = target
        self.displayScale = displayScale

        let frequency = 1 / responseTime // oscillation frequency
        let duration: CGFloat = 0.001 // millisecond
        self.zeta = abs(initialData.velocity) > 300 ? CoreGraphics.log(decelerationRate) / (-2.0 * .pi * frequency * duration)  : 1.0
        self.omega = 2.0 * .pi * frequency

        self.update = update
        self.completion = completion
    }

    @discardableResult
    func startAnimation() -> Bool{
        lock.lock()
        defer { lock.unlock() }

        if isRunning {
            return false
        }
        log.debug("startAnimation --", displayLink)
        isRunning = true
        displayLink.add(to: RunLoop.main, forMode: .common)
        return true
    }

    func stopAnimation(_ withoutFinishing: Bool) {
        let locked = lock.tryLock()
        defer {
            if locked { lock.unlock() }
        }

        log.debug("stopAnimation --", displayLink)
        isRunning = false
        displayLink.invalidate()
        if withoutFinishing {
            return
        }
        completion()
    }

    @objc
    func update(_ displayLink: CADisplayLink) {
        guard lock.tryLock() else { return }
        defer { lock.unlock() }

        let pre = data.value
        var cur = pre
        var velocity = data.velocity
        spring(x: &cur,
               v: &velocity,
               xt: target,
               zeta: zeta,
               omega: omega,
               h: CGFloat(displayLink.targetTimestamp - displayLink.timestamp))
        data = Data(value: cur, velocity: velocity)
        update(data)
        if abs(target - data.value) <= (1 / displayScale),
           abs(pre - data.value) / (1 / displayScale) <= 1 {
            stopAnimation(false)
        }
    }

    /**
     - Parameters:
     - x: value
     - v: velocity
     - xt: target value
     - zeta: damping ratio
     - omega: angular frequency
     - h: time step
     */
    private func spring(x: inout CGFloat, v: inout CGFloat, xt: CGFloat, zeta: CGFloat, omega: CGFloat, h: CGFloat) {
        let f = 1.0 + 2.0 * h * zeta * omega
        let h2 = pow(h, 2)
        let o2 = pow(omega, 2)
        let det = f + h2 * o2
        x = (f * x + h * v + h2 * o2 * xt) / det
        v = (v + h * o2 * (xt - x)) / det
    }
}

extension FloatingPanelController {
    func suspendTransitionAnimator(_ suspended: Bool) {
        self.floatingPanel.isSuspended = suspended
    }
    var transitionAnimator: UIViewPropertyAnimator? {
        return self.floatingPanel.transitionAnimator
    }
}
