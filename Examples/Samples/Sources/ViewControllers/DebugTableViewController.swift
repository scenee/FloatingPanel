// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

class DebugTableViewController: InspectableViewController {
    lazy var tableView = UITableView(frame: .zero, style: .plain)
    lazy var buttonStackView = UIStackView()
    var items: [String] = []
    var itemHeight: CGFloat = 66.0

    enum Menu: String, CaseIterable {
        case animateScroll = "Animate Scroll"
        case changeContentSize = "Change content size"
        case reorder = "Reorder"
        case moveToFull = "Move to Full"
        case moveToHalf = "Move to Half"
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
            case .moveToFull:
                button.addTarget(self, action: #selector(moveToFull), for: .touchUpInside)
            case .moveToHalf:
                button.addTarget(self, action: #selector(moveToHalf), for: .touchUpInside)
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

    @objc func moveToFull() {
        (self.parent as! FloatingPanelController).move(to: .full, animated: true)
    }

    @objc func moveToHalf() {
        (self.parent as! FloatingPanelController).move(to: .half, animated: true)
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
