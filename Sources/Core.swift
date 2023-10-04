// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import os.log

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
            os_log(msg, log: devLog, type: .debug, "state changed: \(oldValue) -> \(state)")
            if let fpc = ownerVC {
                fpc.delegate?.floatingPanelDidChangeState?(fpc)
            }
        }
    }

    let panGestureRecognizer: FloatingPanelPanGestureRecognizer
    let panGestureDelegateRouter: FloatingPanelPanGestureRecognizer.DelegateRouter
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
    private var scrollBounce = false
    private var scrollIndictorVisible = false
    private var scrollBounceThreshold: CGFloat = -30.0

    // MARK: - Interface

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        ownerVC = vc

        surfaceView = SurfaceView()
        surfaceView.position = layout.position
        surfaceView.backgroundColor = .white

        backdropView = BackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        layoutAdapter = LayoutAdapter(vc: vc, layout: layout)
        behaviorAdapter = BehaviorAdapter(vc: vc, behavior: behavior)

        panGestureRecognizer = FloatingPanelPanGestureRecognizer()
        panGestureDelegateRouter = FloatingPanelPanGestureRecognizer.DelegateRouter(panGestureRecognizer: panGestureRecognizer)

        super.init()

        panGestureRecognizer.set(floatingPanel: self)
        surfaceView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))

        // Assign the delegate router to `FloatingPanelPanGestureRecognizer.delegate` only after setting
        // `FloatingPanelPanGestureRecognizer.floatingPanel` property.
        // This is because `delegateOrigin` is used at the time of assignment to its `delegate` property
        // through the delegate router.
        panGestureRecognizer.delegate = panGestureDelegateRouter

        // Set the tap-to-dismiss action of the backdrop view.
        // It's disabled by default. See also BackdropView.dismissalTapGestureRecognizer.
        backdropView.dismissalTapGestureRecognizer.addTarget(self, action: #selector(handleBackdrop(tapGesture:)))
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
        if !isScrollable(state: state) {
            lockScrollView()
        }
        tearDownActiveInteraction()

        interruptAnimationIfNeeded()

        if animated {
            let updateScrollView: () -> Void = { [weak self] in
                guard let self = self else { return }
                if self.isScrollable(state: self.state), 0 == self.layoutAdapter.offset(from: self.state) {
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
                startAttraction(to: to, with: .zero) { [weak self] in
                    self?.endAttraction(false)
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
                    os_log(msg, log: sysLog, type: .info, "Lay out the surface again to modify an intrinsic size error according to UIStackView")
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
            if isScrollable(state: state) {
                self.unlockScrollView()
            } else {
                self.lockScrollView()

            }
            ownerVC?.notifyDidMove()
            completion?()
        }
    }

    // MARK: - Layout update

    func activateLayout(
        forceLayout: Bool = false,
        contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior
    ) {
        layoutAdapter.prepareLayout()

        // preserve the current content offset if contentInsetAdjustmentBehavior is `.always`
        var contentOffset: CGPoint?
        if contentInsetAdjustmentBehavior == .always {
            contentOffset = scrollView?.contentOffset
        }

        layoutAdapter.updateStaticConstraint()
        layoutAdapter.activateLayout(for: state, forceLayout: forceLayout)

        // Update the backdrop alpha only when called in `Controller.show(animated:completion:)`
        // Because that prevents a backdrop flicking just before presenting a panel(#466).
        if forceLayout {
            backdropView.alpha = getBackdropAlpha(for: state)
        }

        if let contentOffset = contentOffset {
            scrollView?.contentOffset = contentOffset
        }

        adjustScrollContentInsetIfNeeded()
    }

    private func updateLayout(to target: FloatingPanelState) {
        layoutAdapter.activateLayout(for: target, forceLayout: true)
        backdropView.alpha = getBackdropAlpha(for: target)
        adjustScrollContentInsetIfNeeded()
    }

    private func getBackdropAlpha(for target: FloatingPanelState) -> CGFloat {
        return target == .hidden ? 0.0 : layoutAdapter.backdropAlpha(for: target)
    }

    func getBackdropAlpha(at cur: CGFloat, with translation: CGFloat) -> CGFloat {
        /* os_log(msg, log: devLog, type: .debug, "currentY: \(currentY) translation: \(translation)") */
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
        guard gestureRecognizer == panGestureRecognizer else { return false }

        /* os_log(msg, log: devLog, type: .debug, "shouldRecognizeSimultaneouslyWith", otherGestureRecognizer) */

        switch otherGestureRecognizer {
        case is FloatingPanelPanGestureRecognizer:
            // All visible panels' pan gesture should be recognized simultaneously.
            return true
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            if surfaceView.grabberAreaContains(gestureRecognizer.location(in: surfaceView)) {
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
        if otherGestureRecognizer is FloatingPanelPanGestureRecognizer {
            // If this panel is the farthest descendant of visible panels,
            // its ancestors' pan gesture must wait for its pan gesture to fail
            if let view = otherGestureRecognizer.view, surfaceView.isDescendant(of: view) {
                return true
            }
        }
        if otherGestureRecognizer.name == "_UISheetInteractionBackgroundDismissRecognizer" {
            // The dismiss gesture of a sheet modal should not begin until the pan gesture fails.
            return true
        }

        if surfaceView.grabberAreaContains(gestureRecognizer.location(in: surfaceView)) {
            return true
        }

        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
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
                    if surfaceView.grabberAreaContains(gestureRecognizer.location(in: surfaceView)) {
                        return false
                    }

                    guard isScrollable(state: state) else { return false }

                    // The condition where offset > 0 must not be included here. Because it will stop recognizing
                    // the panel pan gesture if a user starts scrolling content from an offset greater than 0.
                    return allowScrollPanGesture(of: scrollView) { offset in offset <= scrollBounceThreshold  }
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
            if otherGestureRecognizer.name == "_UISheetInteractionBackgroundDismissRecognizer" {
                // Should begin the pan gesture without waiting the dismiss gesture of a sheet modal.
                return false
            }
            if surfaceView.grabberAreaContains(gestureRecognizer.location(in: surfaceView)) {
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

            let insideMostExpandedAnchor = 0 < layoutAdapter.offsetFromMostExpandedAnchor

            os_log(msg, log: devLog, type: .debug, """
                scroll gesture(\(state):\(panGesture.state)) -- \
                inside expanded anchor = \(insideMostExpandedAnchor), \
                interactionInProgress = \(interactionInProgress), \
                scroll offset = \(value(of: scrollView.contentOffset)), \
                location = \(value(of: location)), velocity = \(velocity)
                """
            )

            let baseOffset = contentOffsetForPinning(of: scrollView)
            let offsetDiff = value(of: scrollView.contentOffset - baseOffset)

            if insideMostExpandedAnchor {
                // Prevent scrolling if needed
                if isScrollable(state: state) {
                    if interactionInProgress {
                        os_log(msg, log: devLog, type: .debug, "settle offset -- \(value(of: initialScrollOffset))")
                        // Return content offset to initial offset to prevent scrolling
                        stopScrolling(at: initialScrollOffset)
                    } else {
                        if surfaceView.grabberAreaContains(initialLocation) {
                            // Preserve the current content offset in moving from full.
                            stopScrolling(at: initialScrollOffset)
                        }
                        /// When the scroll offset is at the pinned offset and a panel is moved, the content
                        /// must be fixed at the pinned position without scrolling. According to the scroll
                        /// pan gesture behavior, the content might have already scrolled a bit by the time
                        /// this handler is called. Thus `initialScrollOffset` property is used here.
                        if value(of: initialScrollOffset - baseOffset) == 0.0 {
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                } else {
                    // Return content offset to initial offset to prevent scrolling
                    stopScrolling(at: initialScrollOffset)
                }

                // Hide a scroll indicator at the non-top in dragging.
                if interactionInProgress {
                    lockScrollView()
                } else {
                    // Put back the scroll indicator and bounce of tracking scroll view
                    // for scrollable states, not most expanded state.
                    if isScrollable(state: state), self.transitionAnimator == nil {
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
                // Here handles seamless scrolling at the most expanded position
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
                    if isScrollable(state: state) {
                        // Adjust a small gap of the scroll offset just after swiping down starts in the grabber area.
                        if surfaceView.grabberAreaContains(location), surfaceView.grabberAreaContains(initialLocation) {
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                } else {
                    if isScrollable(state: state) {
                        let allowScroll = allowScrollPanGesture(of: scrollView) { offset in
                            offset <= scrollBounceThreshold || 0 < offset
                        }
                        switch layoutAdapter.position {
                        case .top, .left:
                            if velocity < 0, !allowScroll {
                                lockScrollView(strict: true)
                            }
                            if velocity > 0, allowScroll {
                                unlockScrollView()
                            }
                        case .bottom, .right:
                            // Hide a scroll indicator just before starting an interaction by swiping a panel down.
                            if velocity > 0, !allowScroll {
                                lockScrollView(strict: true)
                            }
                            // Show a scroll indicator when an animation is interrupted at the top and content is scrolled up
                            if velocity < 0, allowScroll {
                                unlockScrollView()
                            }
                        }
                        // Adjust a small gap of the scroll offset just before swiping down starts in the grabber area,
                        if surfaceView.grabberAreaContains(location), surfaceView.grabberAreaContains(initialLocation) {
                            stopScrolling(at: initialScrollOffset)
                        }
                    }
                }
            }
        case panGestureRecognizer:
            let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
            // The touch velocity in the surface view
            let velocity = panGesture.velocity(in: panGesture.view)
            // The touch location in the surface view
            let location = panGesture.location(in: panGesture.view)

            os_log(msg, log: devLog, type: .debug, """
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
                                                                  scrollingContent: true,
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
            os_log(msg, log: devLog, type: .debug, "the attraction animator interrupted!!!")
            animator.stopAnimation(true)
            endAttraction(false)
        }
        if let animator = self.transitionAnimator {
            guard 0 <= layoutAdapter.offsetFromMostExpandedAnchor else { return }
            os_log(msg, log: devLog, type: .debug, "a panel animation(interruptible: \(animator.isInterruptible)) interrupted!!!")
            if animator.isInterruptible {
                animator.stopAnimation(false)
                // A user can stop a panel at the nearest Y of a target position so this fine-tunes
                // the a small gap between the presentation layer frame and model layer frame
                // to unlock scroll view properly at finishAnimation(at:)
                if 0 == layoutAdapter.offsetFromMostExpandedAnchor {
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
        guard let scrollView = scrollView, scrollView.frame.contains(initialLocation) else { return false }

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
            isScrollable(state: state),  // When not top most(i.e. .full), don't scroll.
            interactionInProgress == false,  // When interaction already in progress, don't scroll.
            0 == layoutAdapter.offset(from: state),
            !surfaceView.grabberAreaContains(initialLocation)  // When the initial point is within grabber area, don't scroll
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
            if velocity >= 0, offset > 0.0 {
                return true
            }
        case .bottom, .right:
            if  offset > 0.0 {
                return true
            }
            if velocity <= 0, offset < 0.0 {
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
        os_log(msg, log: devLog, type: .debug, "panningBegan -- location = \(value(of: location))")

        guard let scrollView = scrollView else { return }

        initialScrollOffset = scrollView.contentOffset
    }

    private func panningChange(with translation: CGPoint) {
        os_log(msg, log: devLog, type: .debug, "panningChange -- translation = \(value(of: translation))")
        let pre = value(of: layoutAdapter.surfaceLocation)
        let diff = value(of: translation - initialTranslation)
        let next = pre + diff

        layoutAdapter.updateInteractiveEdgeConstraint(diff: diff,
                                                      scrollingContent: shouldScrollingContentInMoving(from: pre, to: next),
                                                      allowsRubberBanding: behaviorAdapter.allowsRubberBanding(for:))

        let cur = value(of: layoutAdapter.surfaceLocation)

        backdropView.alpha = getBackdropAlpha(at: cur, with: value(of: translation))

        guard (pre != cur) else { return }

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidMove?(vc)
        }
    }

    private func shouldScrollingContentInMoving(from pre: CGFloat, to next: CGFloat) -> Bool {
        // Don't allow scrolling if the initial panning location is in the grabber area.
        if surfaceView.grabberAreaContains(initialLocation) {
            return false
        }
        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed {
            switch layoutAdapter.position {
            case .top:
                if pre > .zero, pre < next,
                    scrollView.contentSize.height > scrollView.bounds.height || scrollView.alwaysBounceVertical {
                    return true
                }
            case .left:
                if pre > .zero, pre < next,
                    scrollView.contentSize.width > scrollView.bounds.width || scrollView.alwaysBounceHorizontal {
                    return true
                }
            case .bottom:
                if pre > .zero, pre > next,
                    scrollView.contentSize.height > scrollView.bounds.height || scrollView.alwaysBounceVertical {
                    return true
                }
            case .right:
                if pre > .zero, pre > next,
                    scrollView.contentSize.width > scrollView.bounds.width || scrollView.alwaysBounceHorizontal {
                    return true
                }
            }
        }
        return false
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        os_log(msg, log: devLog, type: .debug, "panningEnd -- translation = \(value(of: translation)), velocity = \(value(of: velocity))")

        if state == .hidden {
            os_log(msg, log: devLog, type: .debug, "Already hidden")
            return
        }

        let currentPos = value(of: layoutAdapter.surfaceLocation)
        let mainVelocity = value(of: velocity)
        var target = self.targetState(from: currentPos, with: mainVelocity)

        endInteraction(for: target)

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
            vc.delegate?.floatingPanelWillEndDragging?(vc, withVelocity: velocity, targetState: &target)
        }

        guard shouldAttract(to: target) else {
            self.state = target
            self.updateLayout(to: target)
            self.unlockScrollView()
            // The `floatingPanelDidEndDragging(_:willAttract:)` must be called after the state property changes.
            // This allows library users to get the correct state in the delegate method.
            if let vc = ownerVC {
                vc.delegate?.floatingPanelDidEndDragging?(vc, willAttract: false)
            }
            return
        }

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidEndDragging?(vc, willAttract: true)
        }

        startAttraction(to: target, with: velocity) { [weak self] in
            self?.endAttraction(true)
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
        os_log(msg, log: devLog, type: .debug, "startInteraction  -- translation = \(value(of: translation)), location = \(value(of: location))")
        guard interactionInProgress == false else { return }

        var offset: CGPoint = .zero

        initialSurfaceLocation = layoutAdapter.surfaceLocation
        if isScrollable(state: state), let scrollView = scrollView {
            ifLabel: if surfaceView.grabberAreaContains(initialLocation) {
                initialScrollOffset = scrollView.contentOffset
            } else if scrollView.frame.contains(initialLocation) {
                let pinningOffset = contentOffsetForPinning(of: scrollView)

                // This code block handles the scenario where there's a navigation bar or toolbar
                // above the tracking scroll view with corresponding content insets set, and users
                // move the panel by interacting with these bars. One case of the scenario can be
                // tested with 'Show Navigation Controller' in Samples.app
                do {
                    // Adjust the location by subtracting scrollView's origin to reference the frame
                    // rectangle of the scroll view itself.
                    let _location = scrollView.convert(location, from: surfaceView) - scrollView.bounds.origin

                    os_log(msg, log: devLog, type: .debug, "startInteraction -- location in scroll view = \(_location))")

                    // Keep the scroll content offset if the current touch position is inside its
                    // content inset area.
                    switch layoutAdapter.position {
                    case .top, .left:
                        let base = value(of: scrollView.bounds.size)
                        if value(of: pinningOffset) + (base - value(of: _location)) < 0 {
                            initialScrollOffset = scrollView.contentOffset
                            break ifLabel
                        }
                    case .bottom, .right:
                        if value(of: pinningOffset) + value(of: _location) < 0 {
                            initialScrollOffset = scrollView.contentOffset
                            break ifLabel
                        }
                    }
                }

                // `initialScrollOffset` must be reset to the pinning offset because the value of `scrollView.contentOffset`,
                // for instance, is a value in [-30, 0) on a bottom positioned panel with `allowScrollPanGesture(of:condition:)`.
                // If it's not reset, the following logic to shift the surface frame will not work and then the scroll
                // content offset will become an unexpected value.
                initialScrollOffset = pinningOffset

                // Shift the surface frame to negate the scroll content offset at startInteraction(at:offset:)
                let offsetDiff = scrollView.contentOffset - pinningOffset
                switch layoutAdapter.position {
                case .top, .left:
                    if value(of: offsetDiff) > 0 {
                        offset = -offsetDiff
                    }
                case .bottom, .right:
                    if value(of: offsetDiff) < 0 {
                        offset = -offsetDiff
                    }
                }
            } else {
                initialScrollOffset = scrollView.contentOffset
            }
            os_log(msg, log: devLog, type: .debug, "initial scroll offset -- \(initialScrollOffset)")
        }

        initialTranslation = translation

        if let vc = ownerVC {
            vc.delegate?.floatingPanelWillBeginDragging?(vc)
        }

        layoutAdapter.startInteraction(at: state, offset: offset)

        interactionInProgress = true

        lockScrollView()
    }

    private func endInteraction(for state: FloatingPanelState) {
        os_log(msg, log: devLog, type: .debug, "endInteraction to \(state)")

        if let scrollView = scrollView {
            os_log(msg, log: devLog, type: .debug, "endInteraction -- scroll offset = \(scrollView.contentOffset)")
        }

        interactionInProgress = false

        // Prevent to keep a scroll view indicator visible at the half/tip position
        if !isScrollable(state: state) {
            lockScrollView()
        }

        layoutAdapter.endInteraction(at: state)
    }

    private func tearDownActiveInteraction() {
        guard panGestureRecognizer.isEnabled else { return }
        // Cancel the pan gesture so that panningEnd(with:velocity:) is called
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
    }

    private func shouldAttract(to state: FloatingPanelState) -> Bool {
        if layoutAdapter.position(for: state) == value(of: layoutAdapter.surfaceLocation) {
            return false
        }
        return true
    }

    private func startAttraction(to state: FloatingPanelState, with velocity: CGPoint, completion: @escaping (() -> Void)) {
        os_log(msg, log: devLog, type: .debug, "startAnimation to \(state) -- velocity = \(value(of: velocity))")
        guard let vc = ownerVC else { return }

        isAttracting = true
        vc.delegate?.floatingPanelWillBeginAttracting?(vc, to: state)
        move(to: state, with: value(of: velocity), completion: completion)
    }

    private func move(to state: FloatingPanelState, with velocity: CGFloat, completion: @escaping (() -> Void)) {
        let (animationConstraint, target) = layoutAdapter.setUpAttraction(to: state)
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

                // Pin the offset of the tracking scroll view while moving by this animator
                if let scrollView = self.scrollView {
                    self.stopScrolling(at: self.initialScrollOffset)
                    os_log(msg, log: devLog, type: .debug, "move -- pinning scroll offset = \(scrollView.contentOffset)")
                }

                ownerVC.notifyDidMove()
        },
            completion: { [weak self] in
                guard let self = self,
                      let ownerVC = self.ownerVC
                else { return }
                self.updateLayout(to: state)
                // Notify when it has reached the target anchor point. At this point, the surface location is equal to
                // the target anchor location.
                ownerVC.notifyDidMove()
                completion()
        })
        moveAnimator?.startAnimation()
        self.state = state
    }

    private func endAttraction(_ tryUnlockScroll: Bool) {
        self.isAttracting = false
        self.moveAnimator = nil

        if let vc = ownerVC {
            vc.delegate?.floatingPanelDidEndAttracting?(vc)
        }

        if let scrollView = scrollView {
            os_log(msg, log: devLog, type: .debug, "finishAnimation -- scroll offset = \(scrollView.contentOffset)")
        }

        os_log(msg, log: devLog, type: .debug, """
            finishAnimation -- state = \(state) \
            surface location = \(layoutAdapter.surfaceLocation) \
            offset from state position = \(layoutAdapter.offset(from: state))
            """)

        if tryUnlockScroll {
            if (isScrollable(state: state) && 0 == layoutAdapter.offset(from: state))
                || shouldLooselyLockScrollView {
                unlockScrollView()
            }
        }
    }

    func value(of point: CGPoint) -> CGFloat {
        return layoutAdapter.position.mainLocation(point)
    }

    func value(of size: CGSize) -> CGFloat {
        return layoutAdapter.position.mainDimension(size)
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

    func targetState(from currentY: CGFloat, with velocity: CGFloat) -> FloatingPanelState {
        os_log(msg, log: devLog, type: .debug, "targetState -- currentY = \(currentY), velocity = \(velocity)")

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
            os_log(msg, log: devLog, type: .debug, "targetState -- negate projection: distance = \(distance)")
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

    func followScrollViewBouncing() {
        guard let scrollView = scrollView else {
            return
        }
        let contentOffset = scrollView.contentOffset.y
        guard contentOffset < 0, layoutAdapter.position == .bottom, isScrollable(state: state) else {
            if surfaceView.transform != .identity {
                surfaceView.transform = .identity
                scrollView.transform = .identity
            }
            return
        }
        surfaceView.transform = CGAffineTransform(translationX: 0, y: -contentOffset)
        scrollView.transform = CGAffineTransform(translationX: 0, y: contentOffset)
    }

    private func lockScrollView(strict: Bool = false) {
        guard let scrollView = scrollView else { return }

        if !strict, shouldLooselyLockScrollView {
            if scrollView.isLooselyLocked {
                os_log(msg, log: devLog, type: .debug, "Already scroll locked loosely.")
                return
            }
            // Don't change its `bounces` property. If it's changed, it will cause its scroll content offset jump at
            // the most expanded anchor position while seamlessly scrolling content. This problem only occurs where its
            // content mode is `.fitToBounds` and the tracking scroll content is smaller than the content view size.
            // The reason why is because `bounces` prop change leads to the "content frame" change on `.fitToBounds`.
            // See also https://github.com/scenee/FloatingPanel/issues/524.
        } else {
            if scrollView.isLocked {
                os_log(msg, log: devLog, type: .debug, "Already scroll locked.")
                return
            }

            scrollBounce = scrollView.bounces
            scrollView.bounces = false
        }
        os_log(msg, log: devLog, type: .debug, "lock scroll view")

        scrollView.isDirectionalLockEnabled = true

        switch layoutAdapter.position {
        case .top, .bottom:
            scrollIndictorVisible = scrollView.showsVerticalScrollIndicator
            scrollView.showsVerticalScrollIndicator = false
        case .left, .right:
            scrollIndictorVisible = scrollView.showsHorizontalScrollIndicator
            scrollView.showsHorizontalScrollIndicator = false
        }
    }

    private func unlockScrollView() {
        guard let scrollView = scrollView, scrollView.isLocked else { return }
        os_log(msg, log: devLog, type: .debug, "unlock scroll view")

        scrollView.bounces = scrollBounce
        scrollView.isDirectionalLockEnabled = false
        switch layoutAdapter.position {
        case .top, .bottom:
            scrollView.showsVerticalScrollIndicator = scrollIndictorVisible
        case .left, .right:
            scrollView.showsHorizontalScrollIndicator = scrollIndictorVisible
        }
    }

    private var shouldLooselyLockScrollView: Bool {
        if surfaceView.frame == .zero {
            return false
        }
        var isSmallScrollContentAndFitToBoundsMode: Bool {
            if ownerVC?.contentMode == .fitToBounds, let scrollView = scrollView,
               value(of: scrollView.contentSize) < value(of: scrollView.bounds.size) + max(layoutAdapter.offsetFromMostExpandedAnchor, 0) {
                return true
            }
            return false
        }
        return isSmallScrollContentAndFitToBoundsMode
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
            return CGPoint(x: 0.0, y: 0.0 - scrollView.adjustedContentInset.top)
        case .right:
            return CGPoint(x: 0.0 - scrollView.adjustedContentInset.left, y: 0.0)
        }
    }

    private func allowScrollPanGesture(of scrollView: UIScrollView, condition: (_ offset: CGFloat) -> Bool) -> Bool {
        var offset: CGFloat = 0
        switch layoutAdapter.position {
        case .top, .left:
            offset = value(of: scrollView.fp_contentOffsetMax - scrollView.contentOffset)
        case .bottom, .right:
            offset = value(of: scrollView.contentOffset - contentOffsetForPinning(of: scrollView))
        }
        return condition(offset)
    }

    func isScrollable(state: FloatingPanelState) -> Bool {
        guard let scrollView = scrollView else { return false }
        if let fpc = ownerVC, 
            let scrollable = fpc.delegate?.floatingPanel?(fpc, shouldAllowToScroll: scrollView, in: state)
        {
            return scrollable
        }
        return state == layoutAdapter.mostExpandedState
    }

    /// Adjust content inset of the tracking scroll view if the controller's
    /// `contentInsetAdjustmentBehavior` is `.always` and its `contentMode` is `.static`.
    /// if its content is scrollable, the content might not be fully visible on `.half`
    /// state, for example. Therefore the content inset needs to adjust to display the
    /// full content.
    func adjustScrollContentInsetIfNeeded() {
        guard
            let fpc = ownerVC,
            let scrollView = scrollView,
            fpc.contentInsetAdjustmentBehavior == .always
        else { return }

        switch fpc.contentMode {
        case .static:
            var inset = scrollView.safeAreaInsets
            let offset = layoutAdapter.offsetFromMostExpandedAnchor
            if  offset > 0 {
                switch layoutAdapter.position {
                case .top:
                    inset.top = offset + scrollView.safeAreaInsets.top
                case .bottom:
                    inset.bottom = offset + scrollView.safeAreaInsets.bottom
                case .left:
                    inset.left = offset + scrollView.safeAreaInsets.left
                case .right:
                    inset.left = offset + scrollView.safeAreaInsets.right
                }
            }
            scrollView.contentInset = inset
        case .fitToBounds:
            scrollView.contentInset = scrollView.safeAreaInsets
        }
    }
}

/// A gesture recognizer that looks for panning (dragging) gestures in a panel.
public final class FloatingPanelPanGestureRecognizer: UIPanGestureRecognizer {
    /// The gesture starting location in the surface view which it is attached to.
    fileprivate var initialLocation: CGPoint = .zero
    private weak var floatingPanel: Core!  //  Core has this gesture recognizer as non-optional
    fileprivate func set(floatingPanel: Core) {
        self.floatingPanel = floatingPanel
    }

    init() {
        super.init(target: nil, action: nil)
        name = "FloatingPanelPanGestureRecognizer"
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialLocation = touches.first?.location(in: view) ?? .zero
        if floatingPanel.transitionAnimator != nil || floatingPanel.moveAnimator != nil {
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
            guard newValue is DelegateRouter else {
                let exception = NSException(
                    name: .invalidArgumentException,
                    reason: "FloatingPanelController's built-in pan gesture recognizer must have its controller as its delegate. Use 'delegateProxy' property.",
                    userInfo: nil
                )
                exception.raise()
                return
            }
            super.delegate = newValue
        }
    }

    /// The default object implementing a set methods of the delegate of the gesture recognizer.
    ///
    /// Use this property with ``delegateProxy`` when you need to use the default gesture behaviors in a proxy implementation.
    public var delegateOrigin: UIGestureRecognizerDelegate {
        return floatingPanel
    }

    /// A proxy object to intercept the default behavior of the gesture recognizer.
    ///
    /// `UIGestureRecognizerDelegate` methods implementing by this object are called instead of the default delegate,
    ///  ``delegateOrigin``.
    public weak var delegateProxy: UIGestureRecognizerDelegate? {
        didSet {
            self.delegate = floatingPanel?.panGestureDelegateRouter // Update the cached IMP
        }
    }

    final class DelegateRouter: NSObject, UIGestureRecognizerDelegate {
        fileprivate unowned let panGestureRecognizer: FloatingPanelPanGestureRecognizer

        init(panGestureRecognizer: FloatingPanelPanGestureRecognizer) {
            self.panGestureRecognizer = panGestureRecognizer
            super.init()
        }

        override func responds(to aSelector: Selector!) -> Bool {
            return panGestureRecognizer.delegateProxy?.responds(to: aSelector) == true
            || panGestureRecognizer.delegateOrigin.responds(to: aSelector)
        }

        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            if panGestureRecognizer.delegateProxy?.responds(to: aSelector) == true {
                return panGestureRecognizer.delegateProxy
            }
            if panGestureRecognizer.delegateOrigin.responds(to: aSelector) {
                return panGestureRecognizer.delegateOrigin
            }
            return nil
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
        os_log(msg, log: devLog, type: .debug, "startAnimation -- \(displayLink)")
        isRunning = true
        displayLink.add(to: RunLoop.main, forMode: .common)
        return true
    }

    func stopAnimation(_ withoutFinishing: Bool) {
        let locked = lock.tryLock()
        defer {
            if locked { lock.unlock() }
        }

        os_log(msg, log: devLog, type: .debug, "stopAnimation -- \(displayLink)")
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
