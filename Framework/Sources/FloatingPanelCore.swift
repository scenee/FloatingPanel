//
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass // For Xcode 9.4.1

///
/// FloatingPanel presentation model
///
class FloatingPanelCore: NSObject, UIGestureRecognizerDelegate {
    // MUST be a weak reference to prevent UI freeze on the presentation modally
    weak var viewcontroller: FloatingPanelController?

    let surfaceView: FloatingPanelSurfaceView
    let backdropView: FloatingPanelBackdropView
    var layoutAdapter: FloatingPanelLayoutAdapter
    var behavior: FloatingPanelBehavior

    weak var scrollView: UIScrollView? {
        didSet {
            oldValue?.panGestureRecognizer.removeTarget(self, action: nil)
            scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))
        }
    }

    private(set) var state: FloatingPanelPosition = .hidden {
        didSet {
            if let vc = viewcontroller {
                vc.delegate?.floatingPanelDidChangePosition(vc)
            }
        }
    }

    private var isBottomState: Bool {
        let remains = layoutAdapter.supportedPositions.filter { $0.rawValue > state.rawValue }
        return remains.count == 0
    }

    let panGestureRecognizer: FloatingPanelPanGestureRecognizer
    var isRemovalInteractionEnabled: Bool = false

    fileprivate var animator: UIViewPropertyAnimator?

    private var initialFrame: CGRect = .zero
    private var initialTranslationY: CGFloat = 0
    private var initialLocation: CGPoint = .nan

    var interactionInProgress: Bool = false
    var isDecelerating: Bool = false

    // Scroll handling
    private var initialScrollOffset: CGPoint = .zero
    private var stopScrollDeceleration: Bool = false
    private var scrollBouncable = false
    private var scrollIndictorVisible = false

    // MARK: - Interface

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        viewcontroller = vc

        surfaceView = FloatingPanelSurfaceView()
        surfaceView.backgroundColor = .white

        backdropView = FloatingPanelBackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        self.layoutAdapter = FloatingPanelLayoutAdapter(surfaceView: surfaceView,
                                                        backdropView: backdropView,
                                                        layout: layout)
        self.behavior = behavior

        panGestureRecognizer = FloatingPanelPanGestureRecognizer()

        if #available(iOS 11.0, *) {
            panGestureRecognizer.name = "FloatingPanelSurface"
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

    func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        move(from: state, to: to, animated: animated, completion: completion)
    }

    private func move(from: FloatingPanelPosition, to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        assert(layoutAdapter.validPositions.contains(to), "Can't move to '\(to)' position because it's not valid in the layout")
        guard let vc = viewcontroller else {
            completion?()
            return
        }
        if state != layoutAdapter.topMostState {
            lockScrollView()
        }
        tearDownActiveInteraction()

        if animated {
            let animator: UIViewPropertyAnimator
            switch (from, to) {
            case (.hidden, let to):
                animator = behavior.addAnimator(vc, to: to)
            case (let from, .hidden):
                animator = behavior.removeAnimator(vc, from: from)
            case (let from, let to):
                animator = behavior.moveAnimator(vc, from: from, to: to)
            }

            animator.addAnimations { [weak self] in
                guard let `self` = self else { return }

                self.state = to
                self.updateLayout(to: to)
            }
            animator.addCompletion { [weak self] _ in
                guard let `self` = self else { return }
                self.animator = nil
                if self.state == self.layoutAdapter.topMostState {
                    self.unlockScrollView()
                } else {
                    self.lockScrollView()
                }
                completion?()
            }
            self.animator = animator
            animator.startAnimation()
        } else {
            self.state = to
            self.updateLayout(to: to)
            if self.state == self.layoutAdapter.topMostState {
                self.unlockScrollView()
            } else {
                self.lockScrollView()
            }
            completion?()
        }
    }

    // MARK: - Layout update

    private func updateLayout(to target: FloatingPanelPosition) {
        self.layoutAdapter.activateFixedLayout()
        self.layoutAdapter.activateInteractiveLayout(of: target)
    }

    func getBackdropAlpha(at currentY: CGFloat, with translation: CGPoint) -> CGFloat {
        let forwardY = (translation.y >= 0)
        let segment = layoutAdapter.segument(at: currentY, forward: forwardY)
        let lowerPos = segment.lower ?? layoutAdapter.topMostState
        let upperPos = segment.upper ?? layoutAdapter.bottomMostState

        let pre = forwardY ? lowerPos : upperPos
        let next = forwardY ? upperPos : lowerPos

        let nextY = layoutAdapter.positionY(for: next)
        let preY = layoutAdapter.positionY(for: pre)

        let nextAlpha = layoutAdapter.layout.backdropAlphaFor(position: next)
        let preAlpha = layoutAdapter.layout.backdropAlphaFor(position: pre)

        if preY == nextY {
            return preAlpha
        } else {
            return preAlpha + max(min(1.0, 1.0 - (nextY - currentY) / (nextY - preY) ), 0.0) * (nextAlpha - preAlpha)
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return false }

        /* log.debug("shouldRecognizeSimultaneouslyWith", otherGestureRecognizer) */

        if let vc = viewcontroller,
            vc.delegate?.floatingPanel(vc, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false {
            return true
        }

        switch otherGestureRecognizer {
        case is FloatingPanelPanGestureRecognizer:
            // All visiable panels' pan gesture should be recognized simultaneously.
            return true
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            // all gestures of the tracking scroll view should be recognized in parallel
            // and handle them in self.handle(panGesture:)
            return scrollView?.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
        default:
            // Should recognize tap/long press gestures in parallel when the surface view is at an anchor position.
            let surfaceFrame = surfaceView.layer.presentation()?.frame ?? surfaceView.frame
            let surfaceY = surfaceFrame.minY
            let adapterY = layoutAdapter.positionY(for: state)

            return abs(surfaceY - adapterY) < (1.0 / surfaceView.traitCollection.displayScale)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        /* log.debug("shouldBeRequiredToFailBy", otherGestureRecognizer) */
        if otherGestureRecognizer is FloatingPanelPanGestureRecognizer {
            // If this panel is the farthest descendant of visiable panels,
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
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return false }

        /* log.debug("shouldRequireFailureOf", otherGestureRecognizer) */

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

        if let vc = viewcontroller,
            vc.delegate?.floatingPanel(vc, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false {
            return false
        }

        switch otherGestureRecognizer {
        case is FloatingPanelPanGestureRecognizer:
            // If this panel is the farthest descendant of visiable panels,
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
            // Do not begin the pan gesture until these gestures fail
            return true
        default:
            // Should begin the pan gesture without waiting tap/long press gestures fail
            return false
        }
    }

    var grabberAreaFrame: CGRect {
        let grabberAreaFrame = CGRect(x: surfaceView.bounds.origin.x,
                                     y: surfaceView.bounds.origin.y,
                                     width: surfaceView.bounds.width,
                                     height: surfaceView.topGrabberBarHeight * 2)
        return grabberAreaFrame
    }

    // MARK: - Gesture handling

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        viewcontroller?.dismiss(animated: true) { [weak self] in
            guard let vc = self?.viewcontroller else { return }
            vc.delegate?.floatingPanelDidEndRemove(vc)
        }
    }

    @objc func handle(panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: panGesture.view)

        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }

            let location = panGesture.location(in: surfaceView)

            let surfaceMinY = surfaceView.presentationFrame.minY
            let adapterTopY = layoutAdapter.topY
            let belowTop = surfaceMinY > (adapterTopY + (1.0 / surfaceView.traitCollection.displayScale))
            log.debug("scroll gesture(\(state):\(panGesture.state)) --",
                "belowTop = \(belowTop),",
                "interactionInProgress = \(interactionInProgress),",
                "scroll offset = \(scrollView.contentOffset.y),",
                "location = \(location.y), velocity = \(velocity.y)")

            let offset = scrollView.contentOffset.y - contentOrigin(of: scrollView).y

            if belowTop {
                // Scroll offset pinning
                if state == layoutAdapter.topMostState {
                    if interactionInProgress {
                        log.debug("settle offset --", initialScrollOffset.y)
                        scrollView.setContentOffset(initialScrollOffset, animated: false)
                    } else {
                        if grabberAreaFrame.contains(location) {
                            // Preserve the current content offset in moving from full.
                            scrollView.setContentOffset(initialScrollOffset, animated: false)
                        }
                    }
                } else {
                    scrollView.setContentOffset(initialScrollOffset, animated: false)
                }

                // Hide a scroll indicator at the non-top in dragging.
                if interactionInProgress {
                    lockScrollView()
                } else {
                    if state == layoutAdapter.topMostState, self.animator == nil,
                        offset > 0, velocity.y < 0 {
                        unlockScrollView()
                    }
                }
            } else {
                if interactionInProgress {
                    // Show a scroll indicator at the top in dragging.
                    if offset >= 0, velocity.y <= 0 {
                        unlockScrollView()
                    } else {
                        if state == layoutAdapter.topMostState {
                            // Adjust a small gap of the scroll offset just after swiping down starts in the grabber area.
                            if grabberAreaFrame.contains(location), grabberAreaFrame.contains(initialLocation) {
                                scrollView.setContentOffset(initialScrollOffset, animated: false)
                            }
                        }
                    }
                } else {
                    if state == layoutAdapter.topMostState {
                        // Hide a scroll indicator just before starting an interaction by swiping a panel down.
                        if velocity.y > 0, !allowScrollPanGesture(for: scrollView) {
                            lockScrollView()
                        }
                        // Show a scroll indicator when an animation is interrupted at the top and content is scrolled up
                        if velocity.y < 0, allowScrollPanGesture(for: scrollView) {
                            unlockScrollView()
                        }

                        // Adjust a small gap of the scroll offset just before swiping down starts in the grabber area,
                        if grabberAreaFrame.contains(location), grabberAreaFrame.contains(initialLocation) {
                            scrollView.setContentOffset(initialScrollOffset, animated: false)
                        }
                    }
                }
            }
        case panGestureRecognizer:
            let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
            let location = panGesture.location(in: panGesture.view)

            log.debug("panel gesture(\(state):\(panGesture.state)) --",
                "translation =  \(translation.y), location = \(location.y), velocity = \(velocity.y)")

            if interactionInProgress == false, isDecelerating == false,
                let vc = viewcontroller, vc.delegate?.floatingPanelShouldBeginDragging(vc) == false {
                return
            }

            if let animator = self.animator {
                guard surfaceView.presentationFrame.minY >= layoutAdapter.topMaxY else { return }
                log.debug("panel animation(interruptible: \(animator.isInterruptible)) interrupted!!!")
                if animator.isInterruptible {
                    animator.stopAnimation(false)
                    // A user can stop a panel at the nearest Y of a target position so this fine-tunes
                    // the a small gap between the presentation layer frame and model layer frame
                    // to unlock scroll view properly at finishAnimation(at:)
                    if abs(surfaceView.frame.minY - layoutAdapter.topY) <= 1.0 {
                        surfaceView.frame.origin.y = layoutAdapter.topY
                    }
                    animator.finishAnimation(at: .current)
                } else {
                    self.endAnimation(false) // Must call it manually
                }
            }

            if panGesture.state == .began {
                panningBegan(at: location)
                return
            }

            if shouldScrollViewHandleTouch(scrollView, point: location, velocity: velocity) {
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
                    let dy = translation.y - .leastNonzeroMagnitude
                    layoutAdapter.updateInteractiveTopConstraint(diff: dy,
                                                                 allowsTopBuffer: true,
                                                                 with: behavior)
                }
                panningEnd(with: translation, velocity: velocity)
            default:
                break
            }
        default:
            return
        }
    }

    private func shouldScrollViewHandleTouch(_ scrollView: UIScrollView?, point: CGPoint, velocity: CGPoint) -> Bool {
        // When no scrollView, nothing to handle.
        guard let scrollView = scrollView else { return false }

        // For _UISwipeActionPanGestureRecognizer
        if let scrollGestureRecognizers = scrollView.gestureRecognizers {
            for gesture in scrollGestureRecognizers {
                guard gesture.state == .began || gesture.state == .changed
                else { continue }

                if gesture !=  scrollView.panGestureRecognizer {
                    return true
                }
            }
        }

        guard
            state == layoutAdapter.topMostState,   // When not top most(i.e. .full), don't scroll.
            interactionInProgress == false,        // When interaction already in progress, don't scroll.
            surfaceView.frame.minY == layoutAdapter.topY
        else {
            return false
        }

        // When the current and initial point within grabber area, do scroll.
        if grabberAreaFrame.contains(point), !grabberAreaFrame.contains(initialLocation) {
            return true
        }

        let scrollViewFrame = scrollView.convert(scrollView.bounds, to: surfaceView)
        guard
            scrollViewFrame.contains(initialLocation), // When initialLocation not in scrollView, don't scroll.
            !grabberAreaFrame.contains(point)           // When point within grabber area, don't scroll.
        else {
            return false
        }

        let offset = scrollView.contentOffset.y - contentOrigin(of: scrollView).y
        // The zero offset must be excluded because the offset is usually zero
        // after a panel moves from half/tip to full.
        if  offset > 0.0 {
            return true
        }
        if scrollView.isDecelerating {
            return true
        }
        if velocity.y <= 0 {
            return true
        }

        return false
    }

    private func panningBegan(at location: CGPoint) {
        // A user interaction does not always start from Began state of the pan gesture
        // because it can be recognized in scrolling a content in a content view controller.
        // So here just preserve the current state if needed.
        log.debug("panningBegan -- location = \(location.y)")
        initialLocation = location

        guard let scrollView = scrollView else { return }
        if state == layoutAdapter.topMostState {
            if grabberAreaFrame.contains(location) {
                initialScrollOffset = scrollView.contentOffset
            }
        } else {
            initialScrollOffset = scrollView.contentOffset
        }
    }

    private func panningChange(with translation: CGPoint) {
        log.debug("panningChange -- translation = \(translation.y)")
        let preY = surfaceView.frame.minY
        let dy = translation.y - initialTranslationY

        layoutAdapter.updateInteractiveTopConstraint(diff: dy,
                                                     allowsTopBuffer: allowsTopBuffer(for: dy),
                                                     with: behavior)

        let currentY = surfaceView.frame.minY
        backdropView.alpha = getBackdropAlpha(at: currentY, with: translation)
        preserveContentVCLayoutIfNeeded()

        let didMove = (preY != currentY)
        guard didMove else { return }

        if let vc = viewcontroller {
            vc.delegate?.floatingPanelDidMove(vc)
        }
    }

    private func allowsTopBuffer(for translationY: CGFloat) -> Bool {
        let preY = surfaceView.frame.minY
        let nextY = initialFrame.offsetBy(dx: 0.0, dy: translationY).minY
        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed,
            preY > 0 && preY > nextY {
            return false
        } else {
            return true
        }
    }

    private var disabledBottomAutoLayout = false
    private var disabledAutoLayoutItems: Set<NSLayoutConstraint> = []
    // Prevent stretching a view having a constraint to SafeArea.bottom in an overflow
    // from the full position because SafeArea is global in a screen.
    private func preserveContentVCLayoutIfNeeded() {
        guard let vc = viewcontroller else { return }
        guard vc.contentMode != .fitToBounds else { return }

        // Must include topY
        if (surfaceView.frame.minY <= layoutAdapter.topY) {
            if !disabledBottomAutoLayout {
                disabledAutoLayoutItems.removeAll()
                vc.contentViewController?.view?.constraints.forEach({ (const) in
                    switch vc.contentViewController?.layoutGuide.bottomAnchor {
                    case const.firstAnchor:
                        (const.secondItem as? UIView)?.disableAutoLayout()
                        const.isActive = false
                        disabledAutoLayoutItems.insert(const)
                    case const.secondAnchor:
                        (const.firstItem as? UIView)?.disableAutoLayout()
                        const.isActive = false
                        disabledAutoLayoutItems.insert(const)
                    default:
                        break
                    }
                })
            }
            disabledBottomAutoLayout = true
        } else {
            if disabledBottomAutoLayout {
                disabledAutoLayoutItems.forEach({ (const) in
                    switch vc.contentViewController?.layoutGuide.bottomAnchor {
                    case const.firstAnchor:
                        (const.secondItem as? UIView)?.enableAutoLayout()
                        const.isActive = true
                    case const.secondAnchor:
                        (const.firstItem as? UIView)?.enableAutoLayout()
                        const.isActive = true
                    default:
                        break
                    }
                })
                disabledAutoLayoutItems.removeAll()
            }
            disabledBottomAutoLayout = false
        }
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        log.debug("panningEnd -- translation = \(translation.y), velocity = \(velocity.y)")

        if state == .hidden {
            log.debug("Already hidden")
            return
        }

        stopScrollDeceleration = surfaceView.frame.minY > (layoutAdapter.topY + (1.0 / surfaceView.traitCollection.displayScale)) // Projecting the dragging to the scroll dragging or not
        if stopScrollDeceleration {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.stopScrollingWithDeceleration(at: self.initialScrollOffset)
            }
        }

        let currentY = surfaceView.frame.minY
        let targetPosition = self.targetPosition(from: currentY, with: velocity)
        let distance = self.distance(to: targetPosition)

        endInteraction(for: targetPosition)

        if isRemovalInteractionEnabled, isBottomState {
            let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: min(velocity.y/distance, behavior.removalVelocity)) : .zero
            // `velocityVector` will be replaced by just a velocity(not vector) when FloatingPanelRemovalInteraction will be added.
            if shouldStartRemovalAnimation(with: velocityVector), let vc = viewcontroller {
                vc.delegate?.floatingPanelDidEndDraggingToRemove(vc, withVelocity: velocity)
                let animationVector = CGVector(dx: abs(velocityVector.dx), dy: abs(velocityVector.dy))
                startRemovalAnimation(vc, with: animationVector) { [weak self] in
                    self?.finishRemovalAnimation()
                }
                return
            }
        }

        if scrollView != nil, !stopScrollDeceleration,
            surfaceView.frame.minY == layoutAdapter.topY,
            targetPosition == layoutAdapter.topMostState {
            self.state = targetPosition
            self.updateLayout(to: targetPosition)
            self.unlockScrollView()
            if let vc = viewcontroller {
                vc.delegate?.floatingPanelDidEndDragging(vc, withVelocity: .zero, targetPosition: targetPosition)
            }
            return
        }

        if let vc = viewcontroller {
            vc.delegate?.floatingPanelDidEndDragging(vc, withVelocity: velocity, targetPosition: targetPosition)
        }

        // Workaround: Disable a tracking scroll to prevent bouncing a scroll content in a panel animating
        let isScrollEnabled = scrollView?.isScrollEnabled
        if let scrollView = scrollView, targetPosition != .full {
            scrollView.isScrollEnabled = false
        }

        startAnimation(to: targetPosition, at: distance, with: velocity)

        // Workaround: Reset `self.scrollView.isScrollEnabled`
        if let scrollView = scrollView, targetPosition != .full,
            let isScrollEnabled = isScrollEnabled {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }

    private func shouldStartRemovalAnimation(with velocityVector: CGVector) -> Bool {
        let posY = layoutAdapter.positionY(for: state)
        let currentY = surfaceView.frame.minY
        let hiddenY = layoutAdapter.positionY(for: .hidden)
        let vth = behavior.removalVelocity
        let pth = max(min(behavior.removalProgress, 1.0), 0.0)

        let num = (currentY - posY)
        let den = (hiddenY - posY)

        guard num >= 0, den != 0, (num / den >= pth || velocityVector.dy == vth)
        else { return false }

        return true
    }

    private func startRemovalAnimation(_ vc: FloatingPanelController, with velocityVector: CGVector, completion: (() -> Void)?) {
        let animator = behavior.removalInteractionAnimator(vc, with: velocityVector)

        animator.addAnimations { [weak self] in
            self?.state = .hidden
            self?.updateLayout(to: .hidden)
        }
        animator.addCompletion({ _ in
            self.animator = nil
            completion?()
        })
        self.animator = animator
        animator.startAnimation()
    }

    private func finishRemovalAnimation() {
        viewcontroller?.dismiss(animated: false) { [weak self] in
            guard let vc = self?.viewcontroller else { return }
            vc.delegate?.floatingPanelDidEndRemove(vc)
        }
    }

    private func startInteraction(with translation: CGPoint, at location: CGPoint) {
        /* Don't lock a scroll view to show a scroll indicator after hitting the top */
        log.debug("startInteraction  -- translation = \(translation.y), location = \(location.y)")
        guard interactionInProgress == false else { return }

        var offset: CGPoint = .zero

        initialFrame = surfaceView.frame
        if state == layoutAdapter.topMostState, let scrollView = scrollView {
            if grabberAreaFrame.contains(location) {
                initialScrollOffset = scrollView.contentOffset
            } else {
                initialScrollOffset = contentOrigin(of: scrollView)
                // Fit the surface bounds to a scroll offset content by startInteraction(at:offset:)
                let scrollOffsetY = (scrollView.contentOffset.y - contentOrigin(of: scrollView).y)
                if scrollOffsetY < 0 {
                    offset = CGPoint(x: -scrollView.contentOffset.x, y: -scrollOffsetY)
                }
            }
            log.debug("initial scroll offset --", initialScrollOffset)
        }

        initialTranslationY = translation.y

        if let vc = viewcontroller {
            vc.delegate?.floatingPanelWillBeginDragging(vc)
        }

        layoutAdapter.startInteraction(at: state, offset: offset)

        interactionInProgress = true

        lockScrollView()
    }

    private func endInteraction(for targetPosition: FloatingPanelPosition) {
        log.debug("endInteraction to \(targetPosition)")

        if let scrollView = scrollView {
            log.debug("endInteraction -- scroll offset = \(scrollView.contentOffset)")
        }

        interactionInProgress = false

        // Prevent to keep a scroll view indicator visible at the half/tip position
        if targetPosition != layoutAdapter.topMostState {
            lockScrollView()
        }

        layoutAdapter.endInteraction(at: targetPosition)
    }

    private func tearDownActiveInteraction() {
        // Cancel the pan gesture so that panningEnd(with:velocity:) is called
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
    }

    private func startAnimation(to targetPosition: FloatingPanelPosition, at distance: CGFloat, with velocity: CGPoint) {
        log.debug("startAnimation to \(targetPosition) -- distance = \(distance), velocity = \(velocity.y)")
        guard let vc = viewcontroller else { return }

        isDecelerating = true

        vc.delegate?.floatingPanelWillBeginDecelerating(vc)

        let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: velocity.y / distance) : .zero
        let animator = behavior.interactionAnimator(vc, to: targetPosition, with: velocityVector)
        animator.addAnimations { [weak self] in
            guard let `self` = self, let vc = self.viewcontroller else { return }
            self.state = targetPosition
            if animator.isInterruptible {
                switch vc.contentMode {
                case .fitToBounds:
                    UIView.performWithLinear(startTime: 0.0, relativeDuration: 0.75) {
                        self.layoutAdapter.activateFixedLayout()
                        self.surfaceView.superview!.layoutIfNeeded()
                    }
                case .static:
                    self.layoutAdapter.activateFixedLayout()
                }
            } else {
                self.layoutAdapter.activateFixedLayout()
            }
            self.layoutAdapter.activateInteractiveLayout(of: targetPosition)
        }
        animator.addCompletion { [weak self] pos in
            // Prevent calling `finishAnimation(at:)` by the old animator whose `isInterruptive` is false
            // when a new animator has been started after the old one is interrupted.
            guard let `self` = self, self.animator == animator else { return }
            log.debug("finishAnimation to \(targetPosition)")
            self.endAnimation(pos == .end)
        }
        self.animator = animator
        animator.startAnimation()
    }

    private func endAnimation(_ finished: Bool) {
        self.isDecelerating = false
        self.animator = nil

        if let vc = viewcontroller {
            vc.delegate?.floatingPanelDidEndDecelerating(vc)
        }

        if let scrollView = scrollView {
            log.debug("finishAnimation -- scroll offset = \(scrollView.contentOffset)")
        }

        stopScrollDeceleration = false

        log.debug("finishAnimation -- state = \(state) surface.minY = \(surfaceView.presentationFrame.minY) topY = \(layoutAdapter.topY)")
        if finished, state == layoutAdapter.topMostState, abs(surfaceView.presentationFrame.minY - layoutAdapter.topY) <= 1.0 {
            unlockScrollView()
        }
    }

    private func distance(to targetPosition: FloatingPanelPosition) -> CGFloat {
        let currentY = surfaceView.frame.minY
        let targetY = layoutAdapter.positionY(for: targetPosition)
        return CGFloat(targetY - currentY)
    }

    // Distance travelled after decelerating to zero velocity at a constant rate.
    // Refer to the slides p176 of [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/)
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }

    func targetPosition(from currentY: CGFloat, with velocity: CGPoint) -> (FloatingPanelPosition) {
        guard let vc = viewcontroller else { return state }
        let supportedPositions = layoutAdapter.supportedPositions

        guard supportedPositions.count > 1 else {
            return state
        }

        let sortedPositions = Array(supportedPositions).sorted(by: { $0.rawValue < $1.rawValue })

        // Projection
        let decelerationRate = behavior.momentumProjectionRate(vc)
        let baseY = abs(layoutAdapter.positionY(for: layoutAdapter.bottomMostState) - layoutAdapter.positionY(for: layoutAdapter.topMostState))
        let vecY = velocity.y / baseY
        var pY = project(initialVelocity: vecY, decelerationRate: decelerationRate) * baseY + currentY

        let forwardY = velocity.y == 0 ? (currentY - layoutAdapter.positionY(for: state) > 0) : velocity.y > 0

        let segment = layoutAdapter.segument(at: pY, forward: forwardY)

        var fromPos: FloatingPanelPosition
        var toPos: FloatingPanelPosition

        let (lowerPos, upperPos) = (segment.lower ?? sortedPositions.first!, segment.upper ?? sortedPositions.last!)
        (fromPos, toPos) = forwardY ? (lowerPos, upperPos) : (upperPos, lowerPos)

        if behavior.shouldProjectMomentum(vc, for: toPos) == false {
            let segment = layoutAdapter.segument(at: currentY, forward: forwardY)
            var (lowerPos, upperPos) = (segment.lower ?? sortedPositions.first!, segment.upper ?? sortedPositions.last!)
            // Equate the segment out of {top,bottom} most state to the {top,bottom} most segment
            if lowerPos == upperPos {
                if forwardY {
                    upperPos = lowerPos.next(in: sortedPositions)
                } else {
                    lowerPos = upperPos.pre(in: sortedPositions)
                }
            }
            (fromPos, toPos) = forwardY ? (lowerPos, upperPos) : (upperPos, lowerPos)
            // Block a projection to a segment over the next from the current segment
            // (= Trim pY with the current segment)
            if forwardY {
                pY = max(min(pY, layoutAdapter.positionY(for: toPos.next(in: sortedPositions))), layoutAdapter.positionY(for: fromPos))
            } else {
                pY = max(min(pY, layoutAdapter.positionY(for: fromPos)), layoutAdapter.positionY(for: toPos.pre(in: sortedPositions)))
            }
        }

        // Redirection
        let redirectionalProgress = max(min(behavior.redirectionalProgress(vc, from: fromPos, to: toPos), 1.0), 0.0)
        let progress = abs(pY - layoutAdapter.positionY(for: fromPos)) / abs(layoutAdapter.positionY(for: fromPos) - layoutAdapter.positionY(for: toPos))
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

        scrollBouncable = scrollView.bounces
        scrollIndictorVisible = scrollView.showsVerticalScrollIndicator

        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
    }

    private func unlockScrollView() {
        guard let scrollView = scrollView, scrollView.isLocked else { return }
        log.debug("unlock scroll view")

        scrollView.isDirectionalLockEnabled = false
        scrollView.bounces = scrollBouncable
        scrollView.showsVerticalScrollIndicator = scrollIndictorVisible
    }

    private func stopScrollingWithDeceleration(at contentOffset: CGPoint) {
        // Must use setContentOffset(_:animated) to force-stop deceleration
        scrollView?.setContentOffset(contentOffset, animated: false)
    }

    private func contentOrigin(of scrollView: UIScrollView) -> CGPoint {
        if let vc = viewcontroller, let origin = vc.delegate?.floatingPanel(vc, contentOffsetForPinning: scrollView) {
            return origin
        }
        return CGPoint(x: 0.0, y: 0.0 - scrollView.contentInset.top)
    }

    private func allowScrollPanGesture(for scrollView: UIScrollView) -> Bool {
        let contentOffset = scrollView.contentOffset - contentOrigin(of: scrollView)
        if state == layoutAdapter.topMostState {
            return contentOffset.y <= -30.0 || contentOffset.y > 0
        }
        return false
    }
}

class FloatingPanelPanGestureRecognizer: UIPanGestureRecognizer {
    fileprivate weak var floatingPanel: FloatingPanelCore?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if floatingPanel?.animator != nil {
            self.state = .began
        }
    }
    override weak var delegate: UIGestureRecognizerDelegate? {
        get {
            return super.delegate
        }
        set {
            guard newValue is FloatingPanelCore else {
                let exception = NSException(name: .invalidArgumentException,
                                            reason: "FloatingPanelController's built-in pan gesture recognizer must have its controller as its delegate.",
                                            userInfo: nil)
                exception.raise()
                return
            }
            super.delegate = newValue
        }
    }
}
