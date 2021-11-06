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

            addMain(panel: fpc, with: contentVC)

        case .trackingTextView:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            addMain(panel: fpc, with: contentVC)

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
            addMain(panel: fpc, with: pageVC)

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
            addMain(panel: fpc, with: contentVC)

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
            addMain(panel: fpc, with: contentVC)

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

        case .showNavigationController:
            let fpc = FloatingPanelController()
            fpc.contentInsetAdjustmentBehavior = .never
            addMain(panel: fpc, with: contentVC)

        case .showTopPositionedPanel: // For debug
            let fpc = FloatingPanelController()
            let contentVC = UIViewController()
            contentVC.view.backgroundColor = .red
            addMain(panel: fpc, with: contentVC)

        case .showAdaptivePanel, .showAdaptivePanelWithCustomGuide:
            let fpc = FloatingPanelController()
            fpc.isRemovalInteractionEnabled = true
            addMain(panel: fpc, with: contentVC)

        case .showCustomStatePanel:
            let fpc = FloatingPanelController()
            fpc.delegate = self
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.surfaceView.appearance = {
                let appearance = SurfaceAppearance()
                appearance.cornerRadius = 6.0
                return appearance
            }()
            addMain(panel: fpc, with: contentVC)
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

    private func addMain(panel fpc: FloatingPanelController, with contentVC: UIViewController) {
        set(contentViewController: contentVC, to: fpc)

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

    private func set(contentViewController contentVC: UIViewController, to fpc: FloatingPanelController) {
        fpc.set(contentViewController: contentVC)
        // Track a scroll view
        switch contentVC {
        case let consoleVC as DebugTextViewController:
            fpc.track(scrollView: consoleVC.textView)

        case let contentVC as DebugTableViewController:
            let ob = contentVC.tableView.observe(\.isEditing) { (tableView, _) in
                fpc.panGestureRecognizer.isEnabled = !tableView.isEditing
            }
            contentVC.kvoObservers.append(ob)
            fpc.track(scrollView: contentVC.tableView)
        case let contentVC as NestedScrollViewController:
            fpc.track(scrollView: contentVC.scrollView)
        case let navVC as UINavigationController:
            if let rootVC = (navVC.topViewController as? MainViewController) {
                rootVC.loadViewIfNeeded()
                fpc.track(scrollView: rootVC.tableView)
            }
        case let contentVC as ImageViewController:
            if #available(iOS 11.0, *) {
                let mode: ImageViewController.Mode = (useCase == .showAdaptivePanelWithCustomGuide) ? .withHeaderFooter : .onlyImage
                let layoutGuide = contentVC.layoutGuideFor(mode: mode)
                fpc.layout = ImageViewController.PanelLayout(targetGuide: layoutGuide)
            } else {
                fpc.layout = ImageViewController.PanelLayout(targetGuide: nil)
            }
            fpc.track(scrollView: contentVC.scrollView)
        default:
            break
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
