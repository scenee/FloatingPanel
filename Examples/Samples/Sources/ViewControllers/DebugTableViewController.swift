// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

class DebugTableViewController: InspectableViewController {
    // MARK: - Views

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()
    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .trailing
        stackView.spacing = 10.0
        return stackView
    }()
    private lazy var reorderButton: UIButton = {
        let button = UIButton()
        button.setTitle(Menu.reorder.rawValue, for: .normal)
        button.setTitleColor(view.tintColor, for: .normal)
        button.addTarget(self, action: #selector(reorderItems), for: .touchUpInside)
        return button
    }()
    private lazy var trackingSwitchWrapper: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 8.0
        stackView.addArrangedSubview(trackingLabel)
        stackView.addArrangedSubview(trackingSwitch)
        return stackView
    }()
    private lazy var trackingLabel: UILabel = {
        let label = UILabel()
        label.text = "Tracking"
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        return label
    }()
    private lazy var trackingSwitch: UISwitch = {
        let trackingSwitch = UISwitch()
        trackingSwitch.isOn = true
        trackingSwitch.addTarget(self, action: #selector(turnTrackingOn), for: .touchUpInside)
        return trackingSwitch
    }()

    // MARK: - Properties

    private lazy var items: [String] = {
        let items = (0..<100).map { "Items \($0)" }
        return Command.replace(items: items)
    }()
    private var itemHeight: CGFloat = 66.0

    enum Menu: String, CaseIterable {
        case turnOffTracking = "Tracking"
        case reorder = "Reorder"
    }

    enum Command: Int, CaseIterable {
        case animateScroll
        case changeContentSize
        case moveToFull
        case moveToHalf
        var text: String {
            switch self {
            case .animateScroll: return "Scroll in the middle"
            case .changeContentSize: return "Change content size"
            case .moveToFull: return "Move to Full"
            case.moveToHalf: return "Move to Half"
            }
        }

        static func replace(items: [String]) -> [String] {
            return items.enumerated().map { (index, text) -> String in
                if let action = Command(rawValue: index) {
                    return "\(index). \(action.text)"
                }
                return text
            }
        }

        func execute(for vc: DebugTableViewController, sourceView: UIView) {
            switch self {
            case .animateScroll:
                vc.animateScroll()
            case .changeContentSize:
                vc.changeContentSize(sourceView: sourceView)
            case .moveToFull:
                vc.moveToFull()
            case .moveToHalf:
                vc.moveToHalf()
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutTableView()
        layoutMenuStackView()
        setUpMenu()
    }

    private func layoutTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
    }

    private func layoutMenuStackView() {
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 22.0),
            buttonStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -22.0),
            ])
    }

    private func setUpMenu() {
        for menu in Menu.allCases {
            switch menu {
            case .reorder:
                buttonStackView.addArrangedSubview(reorderButton)
            case .turnOffTracking:
                buttonStackView.addArrangedSubview(trackingSwitchWrapper)
            }
        }
    }

    // MARK: - Menu
    @objc
    private func reorderItems() {
        if reorderButton.titleLabel?.text == Menu.reorder.rawValue {
            tableView.isEditing = true
            reorderButton.setTitle("Cancel", for: .normal)
        } else {
            tableView.isEditing = false
            reorderButton.setTitle(Menu.reorder.rawValue, for: .normal)
        }
    }

    @objc
    private func turnTrackingOn(_ sender: UISwitch) {
        guard let fpc = self.parent as? FloatingPanelController else { return }
        if sender.isOn {
            fpc.track(scrollView: tableView)
        } else {
            fpc.untrack(scrollView: tableView)
        }
    }

    // MARK: - Actions

    private func execute(command: Command, sourceView: UIView) {
        command.execute(for: self, sourceView: sourceView)
    }

    @objc
    private func animateScroll() {
        tableView.scrollToRow(at: IndexPath(row: lround(Double(items.count) / 2.0),
                                            section: 0),
                              at: .top, animated: true)
    }

    @objc
    private func changeContentSize(sourceView: UIView) {
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

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }

        self.present(actionSheet, animated: true, completion: nil)
    }

    private func changeItems(_ count: Int) {
        items = Command.replace(items: (0..<count).map{ "\($0). No action" })
        tableView.reloadData()
    }

    @objc
    private func moveToFull() {
        (self.parent as! FloatingPanelController).move(to: .full, animated: true)
    }

    @objc
    private func moveToHalf() {
        (self.parent as! FloatingPanelController).move(to: .half, animated: true)
    }

    @objc
    private func close(sender: UIButton) {
        //  Remove FloatingPanel from a view
        (self.parent as! FloatingPanelController).removePanelFromParent(animated: true, completion: nil)
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
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("TableView --- ", scrollView.contentOffset, scrollView.contentInset)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DebugTableViewController -- select row \(indexPath.row)")
        guard let action = Command(rawValue: indexPath.row) else { return }
        let cell = tableView.cellForRow(at: indexPath)
        execute(command: action, sourceView: cell ?? tableView)
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
