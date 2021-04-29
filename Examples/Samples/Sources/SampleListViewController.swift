// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

class SampleListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var currentMenu: UseCase = .trackingTableView

    var mainPanelVC: FloatingPanelController!
    var detailPanelVC: FloatingPanelController!
    var settingsPanelVC: FloatingPanelController!

    var mainPanelObserves: [NSKeyValueObservation] = []
    var settingsObserves: [NSKeyValueObservation] = []

    lazy var pagePanelController = PagePanelController()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        automaticallyAdjustsScrollViewInsets = false

        let searchController = UISearchController(searchResultsController: nil)
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.largeTitleDisplayMode = .automatic
        } else {
            // Fallback on earlier versions
        }

        let contentVC = DebugTableViewController()
        addMainPanel(with: contentVC)

        var insets = UIEdgeInsets.zero
        insets.bottom += 69.0
        tableView.contentInset = insets
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            if let observation = navigationController?.navigationBar.observe(\.prefersLargeTitles, changeHandler: { (bar, _) in
                self.tableView.reloadData()
            }) {
                settingsObserves.append(observation)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        settingsObserves.removeAll()
    }

    func addMainPanel(with contentVC: UIViewController) {
        mainPanelObserves.removeAll()

        let oldMainPanelVC = mainPanelVC

        mainPanelVC = FloatingPanelController()
        mainPanelVC.delegate = self
        mainPanelVC.contentInsetAdjustmentBehavior = .always

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        mainPanelVC.surfaceView.appearance = appearance

        mainPanelVC.set(contentViewController: contentVC)

        // Enable tap-to-hide and removal interaction
        switch currentMenu {
        case .trackingTableView:
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSurface(tapGesture:)))
            tapGesture.cancelsTouchesInView = false
            tapGesture.numberOfTapsRequired = 2
            // Prevents a delay to response a tap in menus of DebugTableViewController.
            tapGesture.delaysTouchesEnded = false
            mainPanelVC.surfaceView.addGestureRecognizer(tapGesture)
        case .showNestedScrollView:
            mainPanelVC.panGestureRecognizer.delegateProxy = self
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
            mainPanelVC.addPanel(toParent: self, animated: true)
            return
        default:
            break
        }

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
            if let rootVC = (navVC.topViewController as? SampleListViewController) {
                rootVC.loadViewIfNeeded()
                mainPanelVC.track(scrollView: rootVC.tableView)
            }
        case let contentVC as ImageViewController:
            if #available(iOS 11.0, *) {
                let mode: ImageViewController.Mode = (currentMenu == .showAdaptivePanelWithCustomGuide) ? .withHeaderFooter : .onlyImage
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

        //  Add FloatingPanel to self.view
        if let oldMainPanelVC = oldMainPanelVC {
            oldMainPanelVC.removePanelFromParent(animated: true, completion: {
                self.mainPanelVC.addPanel(toParent: self, animated: true)
            })
        } else {
            mainPanelVC.addPanel(toParent: self, animated: true)
        }
    }

    @objc
    func handleSurface(tapGesture: UITapGestureRecognizer) {
        switch mainPanelVC.state {
        case .full:
            mainPanelVC.move(to: .half, animated: true)
        default:
            mainPanelVC.move(to: .full, animated: true)
        }
    }

    // MARK:- Actions
    @IBAction func showDebugMenu(_ sender: UIBarButtonItem) {
        guard settingsPanelVC == nil else { return }
        // Initialize FloatingPanelController
        settingsPanelVC = FloatingPanelController()

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        settingsPanelVC.surfaceView.appearance = appearance

        settingsPanelVC.isRemovalInteractionEnabled = true
        settingsPanelVC.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        settingsPanelVC.delegate = self

        let contentVC = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")

        // Set a content view controller
        settingsPanelVC.set(contentViewController: contentVC)

        //  Add FloatingPanel to self.view
        settingsPanelVC.addPanel(toParent: self, animated: true)
    }
}

extension SampleListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOS 11.0, *) {
            if navigationController?.navigationBar.prefersLargeTitles == true {
                return UseCase.allCases.count + 30
            } else {
                return UseCase.allCases.count
            }
        } else {
            return UseCase.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if UseCase.allCases.count > indexPath.row {
            let menu = UseCase.allCases[indexPath.row]
            cell.textLabel?.text = menu.name
        } else {
            cell.textLabel?.text = "\(indexPath.row) row"
        }
        return cell
    }
}

extension SampleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard UseCase.allCases.count > indexPath.row else { return }
        let menu = UseCase.allCases[indexPath.row]
        let contentVC: UIViewController = {
            guard let storyboardID = menu.storyboardID else { return DebugTableViewController() }
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: storyboardID) else { fatalError() }
            return vc
        }()

        self.currentMenu = menu
        detailPanelVC?.removePanelFromParent(animated: true, completion: nil)
        detailPanelVC = nil

        switch menu {
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
            detailPanelVC.addPanel(toParent: self, animated: true)
        case .showModal, .showTabBar:
            let modalVC = contentVC
            modalVC.modalPresentationStyle = .fullScreen
            present(modalVC, animated: true, completion: nil)

        case .showPageView:
            let pageVC = pagePanelController.makePageViewController(for: self)
            present(pageVC, animated: true, completion: nil)

        case .showPageContentView:
            let pageVC = pagePanelController.makePageViewControllerForContent()
            self.addMainPanel(with: pageVC)
        case .showPanelModal:
            let fpc = FloatingPanelController()
            let contentVC = self.storyboard!.instantiateViewController(withIdentifier: "DetailViewController")
            contentVC.loadViewIfNeeded()
            (contentVC as? DetailViewController)?.modeChangeView.isHidden = true
            fpc.set(contentViewController: contentVC)
            fpc.delegate = self

            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 38.5
            fpc.surfaceView.appearance = appearance
            fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true

            fpc.isRemovalInteractionEnabled = true

            self.present(fpc, animated: true, completion: nil)

        case .showMultiPanelModal:
            let fpc = MultiPanelController()
            self.present(fpc, animated: true, completion: nil)

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
            self.present(mvc, animated: true, completion: nil)
        case .showContentInset:
            let contentViewController = UIViewController()
            contentViewController.view.backgroundColor = .green

            let fpc = FloatingPanelController()
            fpc.set(contentViewController: contentViewController)
            fpc.surfaceView.contentPadding = .init(top: 20, left: 20, bottom: 20, right: 20)

            fpc.delegate = self
            fpc.isRemovalInteractionEnabled = true
            self.present(fpc, animated: true, completion: nil)

        case .showContainerMargins:
            let fpc = FloatingPanelController()

            let appearance = SurfaceAppearance()
            appearance.cornerRadius = 38.5
            fpc.surfaceView.appearance = appearance

            fpc.surfaceView.backgroundColor = .red
            fpc.surfaceView.containerMargins = .init(top: 24.0, left: 8.0, bottom: max(layoutInsets.bottom, 8.0), right: 8.0)
            #if swift(>=5.1) // Actually Xcode 11 or later
            if #available(iOS 13.0, *) {
                fpc.surfaceView.layer.cornerCurve = .continuous
            }
            #endif

            fpc.delegate = self
            fpc.isRemovalInteractionEnabled = true
            self.present(fpc, animated: true, completion: nil)
        default:
            self.addMainPanel(with: contentVC)
        }
    }

    @objc func dismissPresentedVC() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}

extension SampleListViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, contentOffsetForPinning trackingScrollView: UIScrollView) -> CGPoint {
        if currentMenu == .showNavigationController, #available(iOS 11.0, *) {
            // 148.0 is the SafeArea's top value for a navigation bar with a large title.
            return CGPoint(x: 0.0, y: 0.0 - trackingScrollView.contentInset.top - 148.0)
        }
        return CGPoint(x: 0.0, y: 0.0 - trackingScrollView.contentInset.top)
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        if vc == settingsPanelVC {
            return IntrinsicPanelLayout()
        }

        switch currentMenu {
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
            return (newCollection.verticalSizeClass == .compact) ? FloatingPanelBottomLayout() : self
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

extension SampleListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch currentMenu {
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
