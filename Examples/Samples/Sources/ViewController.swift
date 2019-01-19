//
//  ViewController.swift
//  FloatingModalSample
//
//  Created by Shin Yamamoto on 2018/09/18.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit
import FloatingPanel

class SampleListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FloatingPanelControllerDelegate, FloatingPanelLayout {
    @IBOutlet weak var tableView: UITableView!

    enum Menu: Int, CaseIterable {
        case trackingTableView
        case trackingTextView
        case showDetail
        case showModal
        case showFloatingPanelModal
        case showTabBar
        case showNestedScrollView
        case showRemovablePanel
        case showIntrinsicView

        var name: String {
            switch self {
            case .trackingTableView: return "Scroll tracking(TableView)"
            case .trackingTextView: return "Scroll tracking(TextView)"
            case .showDetail: return "Show Detail Panel"
            case .showModal: return "Show Modal"
            case .showFloatingPanelModal: return "Show Floating Panel Modal"
            case .showTabBar: return "Show Tab Bar"
            case .showNestedScrollView: return "Show Nested ScrollView"
            case .showRemovablePanel: return "Show Removable Panel"
            case .showIntrinsicView: return "Show Intrinsic View"
            }
        }

        var storyboardID: String? {
            switch self {
            case .trackingTableView: return nil
            case .trackingTextView: return "ConsoleViewController"
            case .showDetail: return "DetailViewController"
            case .showModal: return "ModalViewController"
            case .showFloatingPanelModal: return nil
            case .showTabBar: return "TabBarViewController"
            case .showNestedScrollView: return "NestedScrollViewController"
            case .showRemovablePanel: return "DetailViewController"
            case .showIntrinsicView: return "IntrinsicViewController"
            }
        }
    }

    var currentMenu: Menu = .trackingTableView

    var mainPanelVC: FloatingPanelController!
    var detailPanelVC: FloatingPanelController!
    var settingsPanelVC: FloatingPanelController!

    var mainPanelObserves: [NSKeyValueObservation] = []
    var settingsObserves: [NSKeyValueObservation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

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

        // Initialize FloatingPanelController
        mainPanelVC = FloatingPanelController()
        mainPanelVC.delegate = self

        // Initialize FloatingPanelController and add the view
        mainPanelVC.surfaceView.cornerRadius = 6.0
        mainPanelVC.surfaceView.shadowHidden = false

        // Set a content view controller
        mainPanelVC.set(contentViewController: contentVC)

        // Enable tap-to-hide and removal interaction
        switch currentMenu {
        case .showRemovablePanel, .showIntrinsicView:
            mainPanelVC.isRemovalInteractionEnabled = true

            let backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
            mainPanelVC.backdropView.addGestureRecognizer(backdropTapGesture)
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
        default:
            break
        }

        //  Add FloatingPanel to self.view
        mainPanelVC.addPanel(toParent: self, belowView: nil, animated: true)
    }

    @objc func dismissDetailPanelVC()  {
        detailPanelVC.removePanelFromParent(animated: true, completion: nil)
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

    // MARK:- TableViewDatasource

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

    // MARK:- Actions
    @IBAction func showDebugMenu(_ sender: UIBarButtonItem) {
        guard settingsPanelVC == nil else { return }
        // Initialize FloatingPanelController
        settingsPanelVC = FloatingPanelController()

        // Initialize FloatingPanelController and add the view
        settingsPanelVC.surfaceView.cornerRadius = 6.0
        settingsPanelVC.surfaceView.shadowHidden = false
        settingsPanelVC.isRemovalInteractionEnabled = true

        let backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
        settingsPanelVC.backdropView.addGestureRecognizer(backdropTapGesture)

        settingsPanelVC.delegate = self

        let contentVC = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")

        // Set a content view controller
        settingsPanelVC.set(contentViewController: contentVC)

        //  Add FloatingPanel to self.view
        settingsPanelVC.addPanel(toParent: self, belowView: nil, animated: true)
    }

    // MARK:- TableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Menu.allCases.count > indexPath.row else { return }
        let menu = Menu.allCases[indexPath.row]
        let contentVC: UIViewController = {
            guard let storyboardID = menu.storyboardID else { return DebugTableViewController() }
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: storyboardID) else { fatalError() }
            return vc
        }()

        self.currentMenu = menu

        switch menu {
        case .showDetail:
            detailPanelVC?.removePanelFromParent(animated: false)

            // Initialize FloatingPanelController
            detailPanelVC = FloatingPanelController()

            // Initialize FloatingPanelController and add the view
            detailPanelVC.surfaceView.cornerRadius = 6.0
            detailPanelVC.surfaceView.shadowHidden = false

            // Set a content view controller
            detailPanelVC.set(contentViewController: contentVC)

            //  Add FloatingPanel to self.view
            detailPanelVC.addPanel(toParent: self, belowView: nil, animated: true)
        case .showModal, .showTabBar:
            let modalVC = contentVC
            present(modalVC, animated: true, completion: nil)
        case .showFloatingPanelModal:
            let fpc = FloatingPanelController()
            let contentVC = self.storyboard!.instantiateViewController(withIdentifier: "DetailViewController")
            fpc.set(contentViewController: contentVC)
            fpc.delegate = self

            fpc.surfaceView.cornerRadius = 38.5
            fpc.surfaceView.shadowHidden = false

            fpc.isRemovalInteractionEnabled = true

            self.present(fpc, animated: true, completion: nil)
        default:
            detailPanelVC?.removePanelFromParent(animated: true, completion: nil)
            mainPanelVC?.removePanelFromParent(animated: true) {
                self.addMainPanel(with: contentVC)
            }
        }
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        if vc == settingsPanelVC {
            return IntrinsicPanelLayout()
        }

        switch currentMenu {
        case .showRemovablePanel:
            return newCollection.verticalSizeClass == .compact ? RemovablePanelLandscapeLayout() :  RemovablePanelLayout()
        case .showIntrinsicView:
            return IntrinsicPanelLayout()
        case .showFloatingPanelModal:
            if vc != mainPanelVC && vc != detailPanelVC {
                return ModalPanelLayout()
            }
            fallthrough
        default:
            return (newCollection.verticalSizeClass == .compact) ? nil  : self
        }
    }

    func floatingPanel(_ vc: FloatingPanelController, shouldRecognizeSimultaneouslyWith gestureRecognizer: UIGestureRecognizer) -> Bool {
        switch currentMenu {
        case .showNestedScrollView:
            return (vc.contentViewController as? NestedScrollViewController)?.nestedScrollView.gestureRecognizers?.contains(gestureRecognizer) ?? false
        default:
            return false
        }
    }

    func floatingPanelDidEndRemove(_ vc: FloatingPanelController) {
        switch vc {
        case settingsPanelVC:
            settingsPanelVC = nil
        default:
            break
        }
    }

    var initialPosition: FloatingPanelPosition {
        return .half
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return UIScreen.main.bounds.height == 667.0 ? 18.0 : 16.0
        case .half: return 262.0
        case .tip: return 69.0
        case .hidden: return nil
        }
    }
}

class IntrinsicPanelLayout: FloatingPanelIntrinsicLayout { }

class RemovablePanelLayout: FloatingPanelIntrinsicLayout {
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    var initialPosition: FloatingPanelPosition {
        return .half
    }
    var topInteractionBuffer: CGFloat {
        return 200.0
    }
    var bottomInteractionBuffer: CGFloat {
        return 261.0 - 22.0
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .half: return 130.0
        default: return nil
        }
    }
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.3
    }
}

class RemovablePanelLandscapeLayout: FloatingPanelIntrinsicLayout {
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    var bottomInteractionBuffer: CGFloat {
        return 261.0 - 22.0
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .half: return 261.0
        default: return nil
        }
    }
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.3
    }
}

class ModalPanelLayout: FloatingPanelIntrinsicLayout {
    var topInteractionBuffer: CGFloat {
        return 100.0
    }
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
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

class DebugTableViewController: InspectableViewController, UITableViewDataSource, UITableViewDelegate {
    weak var tableView: UITableView!
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

        let tableView = UITableView(frame: .zero,
                                    style: .plain)
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
        self.tableView = tableView

        let stackView = UIStackView()
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .trailing
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 22.0),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -22.0),
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
            stackView.addArrangedSubview(button)
        }

        for i in 0...100 {
            items.append("Items \(i)")
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.cornerRadius = 6.0
        fpc.surfaceView.shadowHidden = false

        // Set a content view controller and track the scroll view
        let consoleVC = storyboard?.instantiateViewController(withIdentifier: "ConsoleViewController") as! DebugTextViewController
        fpc.set(contentViewController: consoleVC)
        fpc.track(scrollView: consoleVC.textView)

        self.consoleVC = consoleVC

        //  Add FloatingPanel to self.view
        fpc.addPanel(toParent: self, belowView: safeAreaView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    @IBAction func updateLayout(_ sender: Any) {
        isNewlayout = !isNewlayout
        UIView.animate(withDuration: 0.5) {
            self.fpc.updateLayout()
        }
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return (isNewlayout) ? ModalSecondLayout() : nil
    }
}

class ModalSecondLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .half
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 18.0
        case .half: return 262.0
        case .tip: return 44.0
        case .hidden: return nil
        }
    }
}

class TabBarViewController: UITabBarController {}

class TabBarContentViewController: UIViewController, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController!
    var consoleVC: DebugTextViewController!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.cornerRadius = 6.0
        fpc.surfaceView.shadowHidden = false

        // Set a content view controller and track the scroll view
        let consoleVC = storyboard?.instantiateViewController(withIdentifier: "ConsoleViewController") as! DebugTextViewController
        fpc.set(contentViewController: consoleVC)
        fpc.track(scrollView: consoleVC.textView)
        self.consoleVC = consoleVC

        //  Add FloatingPanel to self.view
        fpc.addPanel(toParent: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //  Remove FloatingPanel from a view
        fpc.removePanelFromParent(animated: false)
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        switch self.tabBarItem.tag {
        case 0:
            return OneTabBarPanelLayout()
        case 1:
            return TwoTabBarPanelLayout()
        case 2:
            return ThreeTabBarPanelLayout()
        default:
            return nil
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        guard self.tabBarItem.tag == 2 else { return }

        /* Solution 1: Manipulate scoll content inset */
        /*
        guard let scrollView = consoleVC.textView else { return }
        var insets = vc.adjustedContentInsets
        if vc.surfaceView.frame.minY < vc.layoutInsets.top {
            insets.top = vc.layoutInsets.top - vc.surfaceView.frame.minY
        } else {
            insets.top = 0.0
        }
        scrollView.contentInset = insets
         */

        // Solution 2: Manipulate top constraint
        assert(consoleVC.textViewTopConstraint != nil)
        if vc.surfaceView.frame.minY + 17.0 < vc.layoutInsets.top {
            consoleVC.textViewTopConstraint?.constant = vc.layoutInsets.top - vc.surfaceView.frame.minY
        } else {
            consoleVC.textViewTopConstraint?.constant = 17.0
        }
        consoleVC.view.layoutIfNeeded()
    }

    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        guard self.tabBarItem.tag == 2 else { return }

        /* Solution 1: Manipulate scoll content inset */
        /*
        guard let scrollView = consoleVC.textView else { return }
        var insets = vc.adjustedContentInsets
        insets.top = (vc.position == .full) ? vc.layoutInsets.top : 0.0
        scrollView.contentInset = insets
        if scrollView.contentOffset.y - scrollView.contentInset.top < 0.0  {
            scrollView.contentOffset = CGPoint(x: 0.0,
                                               y: 0.0 - scrollView.contentInset.top)
        }
         */

        // Solution 2: Manipulate top constraint
        assert(consoleVC.textViewTopConstraint != nil)
        consoleVC.textViewTopConstraint?.constant = (vc.position == .full) ? vc.layoutInsets.top : 17.0
        consoleVC.view.layoutIfNeeded()
    }

    @IBAction func close(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension FloatingPanelLayout {
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        if #available(iOS 11.0, *) {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
                surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0.0),
            ]
        } else {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0),
                surfaceView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0.0),
            ]
        }
    }
}

class OneTabBarPanelLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .tip
    }
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 22.0
        default: return nil
        }
    }
}

class TwoTabBarPanelLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .half
    }
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    var bottomInteractionBuffer: CGFloat {
        return 261.0 - 22.0
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 261.0
        default: return nil
        }
    }
}

class ThreeTabBarPanelLayout: FloatingPanelFullScreenLayout {
    var initialPosition: FloatingPanelPosition {
        return .half
    }
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 0.0
        case .half: return 261.0
        default: return nil
        }
    }
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.3
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
