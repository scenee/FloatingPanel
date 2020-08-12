// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

class SampleListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    enum Menu: Int, CaseIterable {
        case trackingTableView
        case trackingTextView
        case showDetail
        case showModal
        case showPanelModal
        case showMultiPanelModal
        case showPanelInSheetModal
        case showTabBar
        case showPageView
        case showPageContentView
        case showNestedScrollView
        case showRemovablePanel
        case showIntrinsicView
        case showContentInset
        case showContainerMargins
        case showNavigationController
        case showBottomEdgeInteraction

        var name: String {
            switch self {
            case .trackingTableView: return "Scroll tracking(TableView)"
            case .trackingTextView: return "Scroll tracking(TextView)"
            case .showDetail: return "Show Detail Panel"
            case .showModal: return "Show Modal"
            case .showPanelModal: return "Show Panel Modal"
            case .showMultiPanelModal: return "Show Multi Panel Modal"
            case .showPanelInSheetModal: return "Show Panel in Sheet Modal"
            case .showTabBar: return "Show Tab Bar"
            case .showPageView: return "Show Page View"
            case .showPageContentView: return "Show Page Content View"
            case .showNestedScrollView: return "Show Nested ScrollView"
            case .showRemovablePanel: return "Show Removable Panel"
            case .showIntrinsicView: return "Show Intrinsic View"
            case .showContentInset: return "Show with ContentInset"
            case .showContainerMargins: return "Show with ContainerMargins"
            case .showNavigationController: return "Show Navigation Controller"
            case .showBottomEdgeInteraction: return "Show bottom edge interaction"
            }
        }

        var storyboardID: String? {
            switch self {
            case .trackingTableView: return nil
            case .trackingTextView: return "ConsoleViewController"
            case .showDetail: return "DetailViewController"
            case .showModal: return "ModalViewController"
            case .showMultiPanelModal: return nil
            case .showPanelInSheetModal: return nil
            case .showPanelModal: return nil
            case .showTabBar: return "TabBarViewController"
            case .showPageView: return nil
            case .showPageContentView: return nil
            case .showNestedScrollView: return "NestedScrollViewController"
            case .showRemovablePanel: return "DetailViewController"
            case .showIntrinsicView: return "IntrinsicViewController"
            case .showContentInset: return nil
            case .showContainerMargins: return nil
            case .showNavigationController: return "RootNavigationController"
            case .showBottomEdgeInteraction: return nil
            }
        }
    }

    var currentMenu: Menu = .trackingTableView

    var mainPanelVC: FloatingPanelController!
    var detailPanelVC: FloatingPanelController!
    var settingsPanelVC: FloatingPanelController!

    var mainPanelObserves: [NSKeyValueObservation] = []
    var settingsObserves: [NSKeyValueObservation] = []

    var pages: [UIViewController] = []

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
            mainPanelVC.surfaceView.addGestureRecognizer(tapGesture)
        case .showNestedScrollView:
            mainPanelVC.panGestureRecognizer.delegateProxy = self
        case .showPageContentView:
            if let page = (mainPanelVC.contentViewController as? UIPageViewController)?.viewControllers?.first {
                mainPanelVC.track(scrollView: (page as! DebugTableViewController).tableView)
            }
        case .showRemovablePanel, .showIntrinsicView:
            mainPanelVC.isRemovalInteractionEnabled = true

            let backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
            mainPanelVC.backdropView.addGestureRecognizer(backdropTapGesture)
        case .showNavigationController:
            mainPanelVC.contentInsetAdjustmentBehavior = .never
        case .showBottomEdgeInteraction: // For debug
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

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        switch tapGesture.view {
        case mainPanelVC.backdropView:
            mainPanelVC.hide(animated: true, completion: nil)
        case settingsPanelVC.backdropView:
            settingsPanelVC.removePanelFromParent(animated: true)
            settingsPanelVC = nil
        default:
            break
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

        let backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
        settingsPanelVC.backdropView.addGestureRecognizer(backdropTapGesture)

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
                return Menu.allCases.count + 30
            } else {
                return Menu.allCases.count
            }
        } else {
            return Menu.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if Menu.allCases.count > indexPath.row {
            let menu = Menu.allCases[indexPath.row]
            cell.textLabel?.text = menu.name
        } else {
            cell.textLabel?.text = "\(indexPath.row) row"
        }
        return cell
    }
}

extension SampleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Menu.allCases.count > indexPath.row else { return }
        let menu = Menu.allCases[indexPath.row]
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
            (contentVC as? DetailViewController)?.intrinsicHeightConstraint.priority = .defaultLow

            //  Add FloatingPanel to self.view
            detailPanelVC.addPanel(toParent: self, animated: true)
        case .showModal, .showTabBar:
            let modalVC = contentVC
            modalVC.modalPresentationStyle = .fullScreen
            present(modalVC, animated: true, completion: nil)

        case .showPageView:
            pages = [UIColor.blue, .red, .green].compactMap({ (color) -> UIViewController in
                let page = FloatingPanelController(delegate: self)
                page.view.backgroundColor = color
                page.panGestureRecognizer.delegateProxy = self
                page.show()
                return page
            })

            let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
            let closeButton = UIButton(type: .custom)
            pageVC.view.addSubview(closeButton)
            closeButton.setTitle("Close", for: .normal)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.addTarget(self, action: #selector(dismissPresentedVC), for: .touchUpInside)
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: pageVC.layoutGuide.topAnchor, constant: 16.0),
                closeButton.leftAnchor.constraint(equalTo: pageVC.view.leftAnchor, constant: 16.0),
                ])
            pageVC.dataSource = self
            pageVC.setViewControllers([pages[0]], direction: .forward, animated: false, completion: nil)
            pageVC.modalPresentationStyle = .fullScreen
            present(pageVC, animated: true, completion: nil)

        case .showPageContentView:
            pages = [DebugTableViewController(), DebugTableViewController(), DebugTableViewController()]
            let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
            pageVC.dataSource = self
            pageVC.delegate = self
            pageVC.setViewControllers([pages[0]], direction: .forward, animated: false, completion: nil)
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
        case .showBottomEdgeInteraction:
            return BottomEdgeInteractionLayout()
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
        case .showPageView:
            // Tips: Need to allow recognizing the pan gesture of UIPageViewController simultaneously.
            return true
        default:
            return false
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

/**
 - Attention: `FloatingPanelLayout` must not be applied by the parent view
 controller of a panel. But here `SampleListViewController` adopts it
 purposely to check if the library prints an appropriate warning.
 */
extension SampleListViewController: FloatingPanelLayout {
    var position: FloatingPanelPosition { .bottom }
    var initialState: FloatingPanelState { .half }
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: UIScreen.main.bounds.height == 667.0 ? 18.0 : 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 262.0, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}

extension SampleListViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard
            let index = pages.firstIndex(of: viewController),
            index + 1 < pages.count
            else { return nil }
        return pages[index + 1]
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard
            let index = pages.firstIndex(of: viewController),
            index - 1 >= 0
            else { return nil }
        return pages[index - 1]
    }
}
extension SampleListViewController: UIPageViewControllerDelegate {
    // For showPageContent
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let page = pageViewController.viewControllers?.first {
            (pageViewController.parent as! FloatingPanelController).track(scrollView: (page as! DebugTableViewController).tableView)
        }
    }
}

class BottomEdgeInteractionLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .top
    let initialState: FloatingPanelState = .full

    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 88.0, edge: .bottom, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 216.0, edge: .top, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .top, referenceGuide: .safeArea)
        ]
    }
}

class IntrinsicPanelLayout: FloatingPanelBottomLayout {
    override var initialState: FloatingPanelState { .full }
    override var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .safeArea)
        ]
    }
}

class RemovablePanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .half

    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 130.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }

    func backdropAlphaFor(position: FloatingPanelState) -> CGFloat {
        return 0.3
    }
}

class RemovablePanelLandscapeLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .full

    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 216.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }

    func backdropAlphaFor(position: FloatingPanelState) -> CGFloat {
        return 0.3
    }
}

class ModalPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .full

    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0.0, referenceGuide: .safeArea),
        ]
    }

    func backdropAlphaFor(position: FloatingPanelState) -> CGFloat {
        return 0.3
    }
}

class NestedScrollViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nestedScrollView: UIScrollView!

    @IBAction func longPressed(_ sender: Any) {
        print("LongPressed!")
    }
    @IBAction func swipped(_ sender: Any) {
        print("Swipped!")
    }
    @IBAction func tapped(_ sender: Any) {
        print("Tapped!")
    }
}

class DebugTextViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        print("viewDidLoad: TextView --- ", textView.contentOffset, textView.contentInset)

        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = .never
        }
    }

    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews: TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews: TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("TextView --- ", scrollView.contentOffset, scrollView.contentInset)
        if #available(iOS 11.0, *) {
            print("TextView --- ", scrollView.adjustedContentInset)
        }
    }

    @IBAction func close(sender: UIButton) {
        // (self.parent as? FloatingPanelController)?.removePanelFromParent(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }
}

class InspectableViewController: UIViewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print(">>> Content View: viewWillLayoutSubviews", layoutInsets)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print(">>> Content View: viewDidLayoutSubviews", layoutInsets)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(">>> Content View: viewWillAppear", layoutInsets)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(">>> Content View: viewDidAppear", view.bounds, layoutInsets)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(">>> Content View: viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(">>> Content View: viewDidDisappear")
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        print(">>> Content View: willMove(toParent: \(String(describing: parent))")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        print(">>> Content View: didMove(toParent: \(String(describing: parent))")
    }
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print(">>> Content View: willTransition(to: \(newCollection), with: \(coordinator))", layoutInsets)
    }
}

class DebugTableViewController: InspectableViewController {
    lazy var tableView = UITableView(frame: .zero, style: .plain)
    lazy var buttonStackView = UIStackView()
    var items: [String] = []
    var itemHeight: CGFloat = 66.0

    enum Menu: String, CaseIterable {
        case animateScroll = "Animate Scroll"
        case changeContentSize = "Change content size"
        case reorder = "Reorder"
    }

    var reorderButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        view.addSubview(buttonStackView)
        buttonStackView.axis = .vertical
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .trailing
        buttonStackView.spacing = 10.0
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 22.0),
            buttonStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -22.0),
            ])

        for menu in Menu.allCases {
            let button = UIButton()
            button.setTitle(menu.rawValue, for: .normal)
            button.setTitleColor(view.tintColor, for: .normal)
            switch menu {
            case .animateScroll:
                button.addTarget(self, action: #selector(animateScroll), for: .touchUpInside)
            case .changeContentSize:
                button.addTarget(self, action: #selector(changeContentSize), for: .touchUpInside)
            case .reorder:
                button.addTarget(self, action: #selector(reorderItems), for: .touchUpInside)
                reorderButton = button
            }
            buttonStackView.addArrangedSubview(button)
        }

        for i in 0...100 {
            items.append("Items \(i)")
        }
    }

    @objc func animateScroll() {
        tableView.scrollToRow(at: IndexPath(row: lround(Double(items.count) / 2.0),
                                            section: 0),
                              at: .top, animated: true)
    }

    @objc func changeContentSize() {
        let actionSheet = UIAlertController(title: "Change content size", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Large", style: .default, handler: { (_) in
            self.itemHeight = 66.0
            self.changeItems(100)
        }))
        actionSheet.addAction(UIAlertAction(title: "Match", style: .default, handler: { (_) in
            switch self.tableView.bounds.height {
            case 585: // iPhone 6,7,8
                self.itemHeight = self.tableView.bounds.height / 13.0
                self.changeItems(13)
            case 656: // iPhone {6,7,8} Plus
                self.itemHeight = self.tableView.bounds.height / 16.0
                self.changeItems(16)
            default: // iPhone X family
                self.itemHeight = self.tableView.bounds.height / 12.0
                self.changeItems(12)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Short", style: .default, handler: { (_) in
            self.itemHeight = 66.0
            self.changeItems(3)
        }))

        self.present(actionSheet, animated: true, completion: nil)
    }

    @objc func reorderItems() {
        if reorderButton.titleLabel?.text == Menu.reorder.rawValue {
            tableView.isEditing = true
            reorderButton.setTitle("Cancel", for: .normal)
        } else {
            tableView.isEditing = false
            reorderButton.setTitle(Menu.reorder.rawValue, for: .normal)
        }
    }

    func changeItems(_ count: Int) {
        items.removeAll()
        for i in 0..<count {
            items.append("Items \(i)")
        }
        tableView.reloadData()
    }

    @objc func close(sender: UIButton) {
        //  Remove FloatingPanel from a view
        (self.parent as! FloatingPanelController).removePanelFromParent(animated: true, completion: nil)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("TableView --- ", scrollView.contentOffset, scrollView.contentInset)
    }
}

extension DebugTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

extension DebugTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DebugTableViewController -- select row \(indexPath.row)")
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action, path) in
                self.items.remove(at: path.row)
                tableView.deleteRows(at: [path], with: .automatic)
            }),
        ]
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        items.insert(items.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
}

class DetailViewController: InspectableViewController {
    @IBOutlet weak var modeChangeView: UIStackView!
    @IBOutlet weak var intrinsicHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButton: UIButton!
    @IBAction func close(sender: UIButton) {
        // (self.parent as? FloatingPanelController)?.removePanelFromParent(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "Show":
            performSegue(withIdentifier: "ShowSegue", sender: self)
        case "Present Modally":
            performSegue(withIdentifier: "PresentModallySegue", sender: self)
        default:
            break
        }
    }
    @IBAction func modeChanged(_ sender: Any) {
        guard let fpc = parent as? FloatingPanelController else { return }
        fpc.contentMode = (fpc.contentMode == .static) ? .fitToBounds : .static
    }

    @IBAction func tapped(_ sender: Any) {
        print("Detail panel is tapped!")
    }
    @IBAction func swipped(_ sender: Any) {
        print("Detail panel is swipped!")
    }
    @IBAction func longPressed(_ sender: Any) {
        print("Detail panel is longPressed!")
    }
}

class ModalViewController: UIViewController, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController!
    var consoleVC: DebugTextViewController!

    @IBOutlet weak var safeAreaView: UIView!

    var isNewlayout: Bool = false

    override func viewDidLoad() {
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        fpc.surfaceView.appearance = appearance

        // Set a content view controller and track the scroll view
        let consoleVC = storyboard?.instantiateViewController(withIdentifier: "ConsoleViewController") as! DebugTextViewController
        fpc.set(contentViewController: consoleVC)
        fpc.track(scrollView: consoleVC.textView)

        self.consoleVC = consoleVC

        //  Add FloatingPanel to self.view
        fpc.addPanel(toParent: self, at: view.subviews.firstIndex(of: safeAreaView) ?? -1)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //  Remove FloatingPanel from a view
        fpc.removePanelFromParent(animated: false)
    }

    @IBAction func close(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func moveToFull(sender: UIButton) {
        fpc.move(to: .full, animated: true)
    }
    @IBAction func moveToHalf(sender: UIButton) {
        fpc.move(to: .half, animated: true)
    }
    @IBAction func moveToTip(sender: UIButton) {
        fpc.move(to: .tip, animated: true)
    }
    @IBAction func moveToHidden(sender: UIButton) {
        fpc.move(to: .hidden, animated: true)
    }
    @IBAction func updateLayout(_ sender: Any) {
        isNewlayout = !isNewlayout
        UIView.animate(withDuration: 0.5) {
            self.fpc.layout = (self.isNewlayout) ? ModalSecondLayout() : FloatingPanelBottomLayout()
            self.fpc.invalidateLayout()
        }
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return (isNewlayout) ? ModalSecondLayout() : FloatingPanelBottomLayout()
    }
}

class ModalSecondLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition = .bottom
    var initialState: FloatingPanelState { .half }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 262, edge: .top, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}

class TabBarViewController: UITabBarController {}

class TabBarContentViewController: UIViewController {
    enum Tab3Mode {
        case changeOffset
        case changeAutoLayout
        var label: String {
            switch self {
            case .changeAutoLayout: return "Use AutoLayout(OK)"
            case .changeOffset: return "Use ContentOffset(NG)"
            }
        }
    }
    lazy var fpc = FloatingPanelController()
    var consoleVC: DebugTextViewController!

    var threeLayout: ThreeTabBarPanelLayout!
    var tab3Mode: Tab3Mode = .changeAutoLayout
    var switcherLabel: UILabel!

    override func viewDidLoad() {
        fpc.delegate = self

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        fpc.surfaceView.appearance = appearance

        // Set a content view controller and track the scroll view
        let consoleVC = storyboard?.instantiateViewController(withIdentifier: "ConsoleViewController") as! DebugTextViewController
        fpc.set(contentViewController: consoleVC)
        consoleVC.textView.delegate = self // MUST call it before fpc.track(scrollView:)
        fpc.track(scrollView: consoleVC.textView)
        self.consoleVC = consoleVC

        //  Add FloatingPanel to self.view
        fpc.addPanel(toParent: self)


        switch tabBarItem.tag {
        case 1:
            fpc.behavior = TwoTabBarPanelBehavior()
        case 2:
            let switcher = UISwitch()
            fpc.view.addSubview(switcher)
            switcher.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                switcher.bottomAnchor.constraint(equalTo: fpc.surfaceView.topAnchor, constant: -16.0),
                switcher.rightAnchor.constraint(equalTo: fpc.surfaceView.rightAnchor, constant: -16.0),
                ])
            switcher.isOn = true
            switcher.tintColor = .white
            switcher.backgroundColor = .white
            switcher.layer.cornerRadius = 16.0
            switcher.addTarget(self,
                               action: #selector(changeTab3Mode(_:)),
                               for: .valueChanged)
            let label = UILabel()
            label.text = tab3Mode.label
            fpc.view.addSubview(label)
            switcherLabel = label
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: switcher.centerYAnchor, constant: 0.0),
                label.rightAnchor.constraint(equalTo: switcher.leftAnchor, constant: -16.0),
                ])

            // Turn off the mask instead of content inset change
            consoleVC.textView.clipsToBounds = false
        default:
            break
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.invalidateLayout()
    }

    // MARK: - Action

    @IBAction func close(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Private

    @objc
    private func changeTab3Mode(_ sender: UISwitch) {
        if sender.isOn {
            tab3Mode = .changeAutoLayout
        } else {
            tab3Mode = .changeOffset
        }
        switcherLabel.text = tab3Mode.label
    }
}

extension TabBarContentViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.tabBarItem.tag == 2 else { return }
        // Reset an invalid content offset by a user after updating the layout
        // of `consoleVC.textView`.
        // NOTE: FloatingPanel doesn't implicitly reset the offset(i.e.
        // Using KVO of `scrollView.contentOffset`). Because it can lead to an
        // infinite loop if a user also resets a content offset as below and,
        // in the situation, a user has to modify the library.
        if fpc.state != .full, fpc.surfaceLocation.y > fpc.surfaceLocation(for: .full).y {
            scrollView.contentOffset = .zero
        }
    }
}

extension TabBarContentViewController: FloatingPanelControllerDelegate {
    // MARK: - FloatingPanel

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        switch self.tabBarItem.tag {
        case 0:
            return OneTabBarPanelLayout()
        case 1:
            return TwoTabBarPanelLayout()
        case 2:
            threeLayout = ThreeTabBarPanelLayout(parent: self)
            return threeLayout
        default:
            return FloatingPanelBottomLayout()
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        guard self.tabBarItem.tag == 2 else { return }
        switch tab3Mode {
        case .changeAutoLayout:
            /* Good solution: Manipulate top constraint */
            assert(consoleVC.textViewTopConstraint != nil)
            let safeAreaTop = vc.layoutInsets.top
            if vc.surfaceLocation.y + threeLayout.topPadding < safeAreaTop {
                consoleVC.textViewTopConstraint?.constant = min(safeAreaTop - vc.surfaceLocation.y,
                                                                safeAreaTop)
            } else {
                consoleVC.textViewTopConstraint?.constant = threeLayout.topPadding
            }
        case .changeOffset:
            /*
             Bad solution: Manipulate scroll content inset

             FloatingPanelController keeps a content offset in moving a panel
             so that changing content inset or offset causes a buggy behavior.
             */
            guard let scrollView = consoleVC.textView else { return }
            var insets = vc.adjustedContentInsets
            if vc.surfaceView.frame.minY < vc.layoutInsets.top {
                insets.top = vc.layoutInsets.top - vc.surfaceView.frame.minY
            } else {
                insets.top = 0.0
            }
            scrollView.contentInset = insets

            if vc.surfaceView.frame.minY > 0 {
                scrollView.contentOffset = CGPoint(x: 0.0,
                                                   y: 0.0 - scrollView.contentInset.top)
            }
        }

        if vc.surfaceLocation.y > vc.surfaceLocation(for: .half).y {
            let progress = (vc.surfaceLocation.y - vc.surfaceLocation(for: .half).y)
                / (vc.surfaceLocation(for: .tip).y - vc.surfaceLocation(for: .half).y)
            threeLayout.leftConstraint.constant = max(min(progress, 1.0), 0.0) * threeLayout.sideMargin
            threeLayout.rightConstraint.constant = -max(min(progress, 1.0), 0.0) * threeLayout.sideMargin
        } else {
            threeLayout.leftConstraint.constant = 0.0
            threeLayout.rightConstraint.constant = 0.0
        }
    }
}

class OneTabBarPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState { .tip }
    var position: FloatingPanelPosition { .bottom }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 22.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}

class TwoTabBarPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState { .half }
    var position: FloatingPanelPosition { .bottom }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 261.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}

class TwoTabBarPanelBehavior: FloatingPanelBehavior {
    func allowsRubberBanding(for edges: UIRectEdge) -> Bool {
        return [UIRectEdge.top, UIRectEdge.bottom].contains(edges)
    }
}


class ThreeTabBarPanelLayout: FloatingPanelLayout {
    weak var parentVC: UIViewController!

    var leftConstraint: NSLayoutConstraint!
    var rightConstraint: NSLayoutConstraint!

    let topPadding: CGFloat = 17.0
    let sideMargin: CGFloat = 16.0

    init(parent: UIViewController) {
        parentVC = parent
    }

    var initialState: FloatingPanelState { .half }
    var position: FloatingPanelPosition { .bottom }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 261.0 + parentVC.layoutInsets.bottom, edge: .bottom, referenceGuide: .superview),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 88.0 + parentVC.layoutInsets.bottom, edge: .bottom, referenceGuide: .superview),
        ]
    }

    func backdropAlphaFor(position: FloatingPanelState) -> CGFloat {
        return 0.3
    }
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        if #available(iOS 11.0, *) {
            leftConstraint = surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0)
            rightConstraint = surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0.0)
        } else {
            leftConstraint = surfaceView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0)
            rightConstraint = surfaceView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0.0)
        }
        return [ leftConstraint, rightConstraint ]
    }
}

class SettingsViewController: InspectableViewController {
    @IBOutlet weak var largeTitlesSwicth: UISwitch!
    @IBOutlet weak var translucentSwicth: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        versionLabel.text = "Version: \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "--")"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            let prefersLargeTitles = navigationController!.navigationBar.prefersLargeTitles
            largeTitlesSwicth.setOn(prefersLargeTitles, animated: false)
        } else {
            largeTitlesSwicth.isEnabled = false
        }
        let isTranslucent = navigationController!.navigationBar.isTranslucent
        translucentSwicth.setOn(isTranslucent, animated: false)
    }

    @IBAction func toggleLargeTitle(_ sender: UISwitch) {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = sender.isOn
        }
    }
    @IBAction func toggleTranslucent(_ sender: UISwitch) {
        navigationController?.navigationBar.isTranslucent = sender.isOn
    }
}

// MARK -: Multi Panel

import WebKit
final class MultiPanelController: FloatingPanelController, FloatingPanelControllerDelegate {

    private final class FirstPanelContentViewController: UIViewController {

        lazy var webView: WKWebView = WKWebView()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.addSubview(webView)
            webView.frame = view.bounds
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.load(URLRequest(url: URL(string: "https://www.apple.com")!))

            let vc = MultiSecondPanelController()
            vc.setUpContent()
            vc.addPanel(toParent: self)
        }
    }

    private final class MultiSecondPanelController: FloatingPanelController {

        private final class SecondPanelContentViewController: DebugTableViewController {}

        func setUpContent() {
            contentInsetAdjustmentBehavior = .never
            let vc = SecondPanelContentViewController()
            vc.loadViewIfNeeded()
            vc.title = "Second Panel"
            vc.buttonStackView.isHidden = true
            let navigationController = UINavigationController(rootViewController: vc)
            navigationController.navigationBar.barTintColor = .white
            navigationController.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.black
            ]
            set(contentViewController: navigationController)
            self.track(scrollView: vc.tableView)
            surfaceView.containerMargins = .init(top: 24.0, left: 0.0, bottom: layoutInsets.bottom, right: 0.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout = FirstViewLayout()
        isRemovalInteractionEnabled = true

        let vc = FirstPanelContentViewController()
        set(contentViewController: vc)
        track(scrollView: vc.webView.scrollView)
    }

    private final class FirstViewLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full
        var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
            return [
                .full: FloatingPanelLayoutAnchor(absoluteInset: 40.0, edge: .top, referenceGuide: .superview)
            ]
        }
    }
}
