// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class UseCaseController: NSObject {
    unowned let mainVC: MainViewController
    private(set) var useCase: UseCase

    private var mainPanelVC: FloatingPanelController!
    private var detailPanelVC: FloatingPanelController!
    private var settingsPanelVC: FloatingPanelController!
    private lazy var pagePanelController = PagePanelController()
    private lazy var overWindowPanelVC = FloatingPanelController()

    init(mainVC: MainViewController) {
        self.mainVC = mainVC
        self.useCase = .trackingTableView
    }
}

extension UseCaseController {
    func set(useCase: UseCase) {
        self.useCase = useCase

        let contentVC = useCase.makeContentViewController(with: mainVC.storyboard!)

        if let fpc = detailPanelVC {
            fpc.removePanelFromParent(animated: true, completion: nil)
            self.detailPanelVC = nil
        }

        switch useCase {
        case .trackingTableView:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UseCaseController.handleSurface(tapGesture:)))
            tapGesture.cancelsTouchesInView = false
            tapGesture.numberOfTapsRequired = 2
            // Prevents a delay to response a tap in menus of DebugTableViewController.
            tapGesture.delaysTouchesEnded = false
            fpc.surfaceView.addGestureRecognizer(tapGesture)

            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

         case .trackingCollectionViewList:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UseCaseController.handleSurface(tapGesture:)))
            tapGesture.cancelsTouchesInView = false
            tapGesture.numberOfTapsRequired = 2
            // Prevents a delay to response a tap in menus of DebugTableViewController.
            tapGesture.delaysTouchesEnded = false
            fpc.surfaceView.addGestureRecognizer(tapGesture)

            fpc.set(contentViewController: contentVC)
            if #available(iOS 14, *),
                let scrollView = (fpc.contentViewController as? DebugListCollectionViewController)?.collectionView {
                    fpc.track(scrollView: scrollView)
            }
            addMain(panel: fpc)

        case .trackingTextView:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

        case .showDetail:
            // Initialize FloatingPanelController
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            // Set a content view controller
            fpc.set(contentViewController: contentVC)
            fpc.contentMode = .fitToBounds
            (contentVC as? DetailViewController)?.intrinsicHeightConstraint.isActive = false

            detailPanelVC = fpc
            //  Add FloatingPanel to self.view
            fpc.addPanel(toParent: mainVC, animated: true)

        case .showModal, .showTabBar:
            let modalVC = contentVC
            modalVC.modalPresentationStyle = .fullScreen
            mainVC.present(modalVC, animated: true, completion: nil)

        case .showPageView:
            let pageVC = pagePanelController.makePageViewController(for: mainVC)
            mainVC.present(pageVC, animated: true, completion: nil)

        case .showPageContentView:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            let pageVC = pagePanelController.makePageViewControllerForContent()
            if let page = (fpc.contentViewController as? UIPageViewController)?.viewControllers?.first {
                fpc.track(scrollView: (page as! DebugTableViewController).tableView)
            }
            fpc.set(contentViewController: pageVC)
            addMain(panel: fpc)

        case .showRemovablePanel, .showIntrinsicView:
            let fpc = FloatingPanelController()
            fpc.isRemovalInteractionEnabled = true
            fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

        case .showNestedScrollView:
            let fpc = FloatingPanelController()
            fpc.panGestureRecognizer.delegateProxy = self
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

        case .showPanelModal:
            let fpc = FloatingPanelController()
            let contentVC = mainVC.storyboard!.instantiateViewController(withIdentifier: "DetailViewController")
            contentVC.loadViewIfNeeded()
            (contentVC as? DetailViewController)?.modeChangeView.isHidden = true
            fpc.set(contentViewController: contentVC)
            fpc.delegate = self

            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 38.5
            fpc.surfaceView.appearance = appearance
            fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true

            fpc.isRemovalInteractionEnabled = true

            mainVC.present(fpc, animated: true, completion: nil)

        case .showMultiPanelModal:
            let fpc = MultiPanelController()
            mainVC.present(fpc, animated: true, completion: nil)

        case .showOnWindow:
            let fpc = overWindowPanelVC
            fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
            fpc.isRemovalInteractionEnabled = true
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)

            guard let window = UIApplication.shared.windows.first else { fatalError("Any window not found") }

            window.addSubview(fpc.view)
            fpc.view.frame = window.bounds
            fpc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            fpc.show(animated: true)
        case .showPanelInSheetModal:
            let fpc = FloatingPanelController()
            let contentVC = UIViewController()
            fpc.set(contentViewController: contentVC)
            fpc.delegate = self

            let apprearance = SurfaceAppearance()
            apprearance.cornerRadius = 38.5
            apprearance.shadows = []
            fpc.surfaceView.appearance = apprearance
            fpc.isRemovalInteractionEnabled = true

            let mvc = UIViewController()
            mvc.view.backgroundColor = UIColor(displayP3Red: 2/255, green: 184/255, blue: 117/255, alpha: 1.0)
            fpc.addPanel(toParent: mvc)
            mainVC.present(mvc, animated: true, completion: nil)

        case .showContentInset:
            let contentViewController = UIViewController()
            contentViewController.view.backgroundColor = .green

            let fpc = FloatingPanelController()
            fpc.set(contentViewController: contentViewController)
            fpc.surfaceView.contentPadding = .init(top: 20, left: 20, bottom: 20, right: 20)

            fpc.delegate = self
            fpc.isRemovalInteractionEnabled = true
            mainVC.present(fpc, animated: true, completion: nil)

        case .showContainerMargins:
            let fpc = FloatingPanelController()
            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 38.5
            fpc.surfaceView.appearance = appearance

            fpc.surfaceView.backgroundColor = .red
            fpc.surfaceView.containerMargins = .init(top: 24.0, left: 8.0, bottom: max(mainVC.layoutInsets.bottom, 8.0), right: 8.0)
            #if swift(>=5.1) // Actually Xcode 11 or later
            if #available(iOS 13.0, *) {
                fpc.surfaceView.layer.cornerCurve = .continuous
            }
            #endif

            fpc.delegate = self
            fpc.isRemovalInteractionEnabled = true
            mainVC.present(fpc, animated: true, completion: nil)

        case .showNavigationController:
            let fpc = FloatingPanelController()
            fpc.contentInsetAdjustmentBehavior = .never
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

        case .showTopPositionedPanel: // For debug
            let fpc = FloatingPanelController(delegate: self)
            let contentVC = UIViewController()
            contentVC.view.backgroundColor = .red
            fpc.set(contentViewController: contentVC)
            addMain(panel: fpc)

        case .showAdaptivePanel:
            let fpc = FloatingPanelController()
            fpc.isRemovalInteractionEnabled = true
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            if case let contentVC as ImageViewController = contentVC {
                let mode: ImageViewController.Mode = (useCase == .showAdaptivePanelWithCustomGuide) ? .withHeaderFooter : .onlyImage
                let layoutGuide = contentVC.layoutGuideFor(mode: mode)
                fpc.layout = ImageViewController.PanelLayout(targetGuide: layoutGuide)
            }
            addMain(panel: fpc)

        case .showAdaptivePanelWithCustomGuide:
            let fpc = FloatingPanelController()
            fpc.isRemovalInteractionEnabled = true
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()


            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            fpc.layout = AdaptiveLayoutTestViewController.PanelLayout(targetGuide: contentVC.view.makeBoundsLayoutGuide())
            addMain(panel: fpc)

        case .showCustomStatePanel:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            fpc.set(contentViewController: contentVC)
            fpc.ext_trackScrollView(in: contentVC)
            addMain(panel: fpc)

        case .showCustomBackdrop:
            class BlurBackdropView: BackdropView {
                var effectView: UIVisualEffectView!
                override var alpha: CGFloat {
                    set {
                        effectView.alpha = newValue
                    }
                    get {
                        effectView.alpha
                    }
                }
                override init() {
                    super.init()

                    let effect = UIBlurEffect(style: .prominent)
                    let effectView = UIVisualEffectView(effect: effect)
                    addSubview(effectView)
                    effectView.frame = bounds
                    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.effectView = effectView
                }

                required init?(coder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }
            }
            class CustomBottomLayout: FloatingPanelBottomLayout {
                override var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                    return [
                        .full: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .safeArea),
                        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
                        .tip: FloatingPanelLayoutAnchor(fractionalInset: 0.1, edge: .bottom, referenceGuide: .safeArea),
                    ]
                }
                override func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
                    return state == .full ? 0.8 : 0.0
                }
            }

            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.set(contentViewController: contentVC)
            fpc.backdropView = BlurBackdropView()
            fpc.layout = CustomBottomLayout()
            addMain(panel: fpc)
        }
    }

    func setUpSettingsPanel(for mainVC: MainViewController) {
        guard settingsPanelVC == nil else { return }
        // Initialize FloatingPanelController
        settingsPanelVC = FloatingPanelController()

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        settingsPanelVC.surfaceView.appearance = appearance

        settingsPanelVC.isRemovalInteractionEnabled = true
        settingsPanelVC.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        settingsPanelVC.delegate = self

        let contentVC = mainVC.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")

        // Set a content view controller
        settingsPanelVC.set(contentViewController: contentVC)

        //  Add FloatingPanel to self.view
        settingsPanelVC.addPanel(toParent: mainVC, animated: true)
    }

    private func addMain(panel fpc: FloatingPanelController) {
        let oldMainPanelVC = mainPanelVC
        mainPanelVC = fpc
        if let oldMainPanelVC = oldMainPanelVC {
            oldMainPanelVC.removePanelFromParent(animated: true, completion: {
                self.mainPanelVC.addPanel(toParent: self.mainVC, animated: true)
            })
        } else {
            mainPanelVC.addPanel(toParent: mainVC, animated: true)
        }
    }

    @objc
    private func handleSurface(tapGesture: UITapGestureRecognizer) {
        switch mainPanelVC.state {
        case .full:
            mainPanelVC.move(to: .half, animated: true)
        default:
            mainPanelVC.move(to: .full, animated: true)
        }
    }
}

extension UseCaseController: FloatingPanelControllerDelegate {
    func floatingPanel(
        _ fpc: FloatingPanelController,
        shouldAllowToScroll scrollView: UIScrollView,
        in state: FloatingPanelState
    ) -> Bool {
        return state == .full || state == .half
    }

    func floatingPanel(_ vc: FloatingPanelController, contentOffsetForPinning trackingScrollView: UIScrollView) -> CGPoint {
        if useCase == .showNavigationController {
            // 148.0 is the SafeArea's top value for a navigation bar with a large title.
            return CGPoint(x: 0.0, y: 0.0 - trackingScrollView.contentInset.top - 148.0)
        }
        return CGPoint(x: 0.0, y: 0.0 - trackingScrollView.contentInset.top)
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        if vc == settingsPanelVC {
            return IntrinsicPanelLayout()
        }

        switch useCase {
        case .showTopPositionedPanel:
            return TopPositionedPanelLayout()
        case .showRemovablePanel:
            return newCollection.verticalSizeClass == .compact ? RemovablePanelLandscapeLayout() :  RemovablePanelLayout()
        case .showIntrinsicView:
            return IntrinsicPanelLayout()
        case .showPanelModal:
            if vc != mainPanelVC && vc != detailPanelVC {
                return ModalPanelLayout()
            }
            fallthrough
        case .showContentInset:
            return FloatingPanelBottomLayout()
        case .showCustomStatePanel:
            return FloatingPanelLayoutWithCustomState()
        default:
            return (newCollection.verticalSizeClass == .compact) ? FloatingPanelBottomLayout() : mainVC
        }
    }

    func floatingPanelDidRemove(_ vc: FloatingPanelController) {
        switch vc {
        case settingsPanelVC:
            settingsPanelVC = nil
        default:
            break
        }
    }
}

extension UseCaseController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if case .showNestedScrollView = useCase {
            return true
        } else {
            return false
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
         false
    }
}

private extension FloatingPanelController {
    func ext_trackScrollView(in contentVC: UIViewController) {
        switch contentVC {
        case let consoleVC as DebugTextViewController:
            track(scrollView: consoleVC.textView)

        case let contentVC as DebugTableViewController:
            let ob = contentVC.tableView.observe(\.isEditing) { [weak self] (tableView, _) in
                self?.panGestureRecognizer.isEnabled = !tableView.isEditing
            }
            contentVC.kvoObservers.append(ob)
            track(scrollView: contentVC.tableView)

        case let contentVC as NestedScrollViewController:
            track(scrollView: contentVC.scrollView)

        case let navVC as UINavigationController:
            if let rootVC = (navVC.topViewController as? MainViewController) {
                rootVC.loadViewIfNeeded()
                track(scrollView: rootVC.tableView)
            }

        case let contentVC as ImageViewController:
            track(scrollView: contentVC.scrollView)

        case let contentVC as AdaptiveLayoutTestViewController:
            track(scrollView: contentVC.tableView)

        default:
            break
        }
    }
}
