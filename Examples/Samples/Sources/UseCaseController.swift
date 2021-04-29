// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class UseCaseController: NSObject {
    unowned let mainVC: MainViewController
    private(set) var useCase: UseCase = .trackingTableView

    fileprivate var mainPanelVC: FloatingPanelController!
    private var detailPanelVC: FloatingPanelController!
    private var settingsPanelVC: FloatingPanelController!

    private lazy var pagePanelController = PagePanelController()

    private var mainPanelObserves: [NSKeyValueObservation] = []

    init(mainVC: MainViewController) {
        self.mainVC = mainVC
    }

    func set(useCase: UseCase) {
        self.useCase = useCase

        let contentVC = useCase.makeContentViewController(with: mainVC.storyboard!)

        detailPanelVC?.removePanelFromParent(animated: true, completion: nil)
        detailPanelVC = nil

        switch useCase {
        case .showDetail:
            detailPanelVC?.removePanelFromParent(animated: false)

            // Initialize FloatingPanelController
            detailPanelVC = FloatingPanelController()
            detailPanelVC.delegate = self

            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 6.0
            detailPanelVC.surfaceView.appearance = appearance

            // Set a content view controller
            detailPanelVC.set(contentViewController: contentVC)

            detailPanelVC.contentMode = .fitToBounds
            (contentVC as? DetailViewController)?.intrinsicHeightConstraint.isActive = false

            //  Add FloatingPanel to self.view
            detailPanelVC.addPanel(toParent: mainVC, animated: true)
        case .showModal, .showTabBar:
            let modalVC = contentVC
            modalVC.modalPresentationStyle = .fullScreen
            mainVC.present(modalVC, animated: true, completion: nil)

        case .showPageView:
            let pageVC = pagePanelController.makePageViewController(for: mainVC)
            mainVC.present(pageVC, animated: true, completion: nil)

        case .showPageContentView:
            let pageVC = pagePanelController.makePageViewControllerForContent()
            self.addMainPanel(with: pageVC)
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
        default:
            self.addMainPanel(with: contentVC)
        }
    }

    private func addMainPanel(with contentVC: UIViewController) {
        mainPanelObserves.removeAll()

        let oldMainPanelVC = mainPanelVC

        mainPanelVC = FloatingPanelController()
        mainPanelVC.delegate = self
        mainPanelVC.contentInsetAdjustmentBehavior = .always

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        mainPanelVC.surfaceView.appearance = appearance

        set(contentViewController: contentVC)

        useCase.setUpInteraction(for: self)

        //  Add FloatingPanel to self.view
        if let oldMainPanelVC = oldMainPanelVC {
            oldMainPanelVC.removePanelFromParent(animated: true, completion: {
                self.mainPanelVC.addPanel(toParent: self.mainVC, animated: true)
            })
        } else {
            mainPanelVC.addPanel(toParent: mainVC, animated: true)
        }
    }

    private func set(contentViewController contentVC: UIViewController) {
        mainPanelVC.set(contentViewController: contentVC)
        // Track a scroll view
        switch contentVC {
        case let consoleVC as DebugTextViewController:
            mainPanelVC.track(scrollView: consoleVC.textView)

        case let contentVC as DebugTableViewController:
            let ob = contentVC.tableView.observe(\.isEditing) { (tableView, _) in
                self.mainPanelVC.panGestureRecognizer.isEnabled = !tableView.isEditing
            }
            mainPanelObserves.append(ob)
            mainPanelVC.track(scrollView: contentVC.tableView)
        case let contentVC as NestedScrollViewController:
            mainPanelVC.track(scrollView: contentVC.scrollView)
        case let navVC as UINavigationController:
            if let rootVC = (navVC.topViewController as? MainViewController) {
                rootVC.loadViewIfNeeded()
                mainPanelVC.track(scrollView: rootVC.tableView)
            }
        case let contentVC as ImageViewController:
            if #available(iOS 11.0, *) {
                let mode: ImageViewController.Mode = (useCase == .showAdaptivePanelWithCustomGuide) ? .withHeaderFooter : .onlyImage
                let layoutGuide = contentVC.layoutGuideFor(mode: mode)
                mainPanelVC.layout = ImageViewController.PanelLayout(targetGuide: layoutGuide)
            } else {
                mainPanelVC.layout = ImageViewController.PanelLayout(targetGuide: nil)
            }
            mainPanelVC.delegate = nil
            mainPanelVC.isRemovalInteractionEnabled = true
            mainPanelVC.track(scrollView: contentVC.scrollView)
        default:
            break
        }
    }

    @objc
    fileprivate func handleSurface(tapGesture: UITapGestureRecognizer) {
        switch mainPanelVC.state {
        case .full:
            mainPanelVC.move(to: .half, animated: true)
        default:
            mainPanelVC.move(to: .full, animated: true)
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
}

extension UseCaseController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, contentOffsetForPinning trackingScrollView: UIScrollView) -> CGPoint {
        if useCase == .showNavigationController, #available(iOS 11.0, *) {
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
        switch useCase {
        case .showNestedScrollView:
            return true
        default:
            return false
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension UseCase {
    func makeContentViewController(with storyboard: UIStoryboard) -> UIViewController {
        guard let storyboardID = self.storyboardID else { return DebugTableViewController() }
        return storyboard.instantiateViewController(withIdentifier: storyboardID)
    }

    func setUpInteraction(for useCaseController: UseCaseController) {
        let mainVC = useCaseController.mainVC
        let mainPanelVC = useCaseController.mainPanelVC!

        // Enable tap-to-hide and removal interaction
        switch self {
        case .trackingTableView:
            let tapGesture = UITapGestureRecognizer(target: useCaseController, action: #selector(UseCaseController.handleSurface(tapGesture:)))
            tapGesture.cancelsTouchesInView = false
            tapGesture.numberOfTapsRequired = 2
            // Prevents a delay to response a tap in menus of DebugTableViewController.
            tapGesture.delaysTouchesEnded = false
            mainPanelVC.surfaceView.addGestureRecognizer(tapGesture)
        case .showNestedScrollView:
            mainPanelVC.panGestureRecognizer.delegateProxy = useCaseController
        case .showPageContentView:
            if let page = (mainPanelVC.contentViewController as? UIPageViewController)?.viewControllers?.first {
                mainPanelVC.track(scrollView: (page as! DebugTableViewController).tableView)
            }
        case .showRemovablePanel, .showIntrinsicView:
            mainPanelVC.isRemovalInteractionEnabled = true
            mainPanelVC.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        case .showNavigationController:
            mainPanelVC.contentInsetAdjustmentBehavior = .never
        case .showTopPositionedPanel: // For debug
            let contentVC = UIViewController()
            contentVC.view.backgroundColor = .red
            mainPanelVC.set(contentViewController: contentVC)
            mainPanelVC.addPanel(toParent: mainVC, animated: true)
            return
        default:
            break
        }
    }
}
