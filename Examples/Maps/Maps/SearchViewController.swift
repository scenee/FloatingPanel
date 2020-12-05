// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func setUpSearchView() {
        searchVC.loadViewIfNeeded()
        searchVC.tableView.delegate = self
        searchVC.searchBar.placeholder = "Search for a place or address"
        let isPad = (traitCollection.userInterfaceIdiom == .pad)
        searchVC.items = [
            .init(mark: "mark", title: "Marked Location" + (isPad ? " (Left panel)" : ""), subtitle: "Golden Gate Bridge, San Francisco"),
            .init(mark: "mark", title: "Marked Location"  + (isPad ? " (Right panel)" : ""), subtitle: "San Francisco Museum of Modern Art"),
        ]
        searchVC.items.append(contentsOf: (0...98).map {
            .init(mark: "like", title: "Favorites", subtitle: "\($0) Places")
        })
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        deactivate(searchBar: searchVC.searchBar)

        // Show a detail panel
        switch indexPath.row {
        case 0:
            detailVC.item = searchVC.items[safe: 0]

            // Show detail vc in the left positioned panel
            switch traitCollection.userInterfaceIdiom {
            case .pad:
                detailFpc.layout = DetailPanelPadLeftLayout()
                detailFpc.surfaceView.containerMargins = UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0)
            default:
                detailFpc.layout = DetailPanelPhoneLayout()
                detailFpc.surfaceView.containerMargins = .zero
            }
            detailFpc.addPanel(toParent: self, animated: true)
        case 1:
            detailVC.item = searchVC.items[safe: 1]

            // Show detail vc in the right positioned panel
            switch traitCollection.userInterfaceIdiom {
            case .pad:
                detailFpc.layout = DetailPanelPadRightLayout()
                detailFpc.surfaceView.containerMargins = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 16.0)
            default:
                detailFpc.layout = DetailPanelPhoneLayout()
                detailFpc.surfaceView.containerMargins = .zero
            }
            detailFpc.addPanel(toParent: self, animated: true)
        default:
            break
        }
    }
}

// MARK: - Models

struct LocationItem {
    let mark: String
    let title: String
    let subtitle: String

    init(mark: String, title: String, subtitle: String) {
        self.mark = mark
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: -

class SearchViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!

    var items: [LocationItem] = []

    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        searchBar.setSearchText(fontSize: 15.0)

        hideHeader(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11, *) {
        } else {
            // Exmaple: Add rounding corners on iOS 10
            visualEffectView.layer.cornerRadius = 9.0
            visualEffectView.clipsToBounds = true

            // Exmaple: Add shadow manually on iOS 10
            view.layer.insertSublayer(shadowLayer, at: 0)
            let rect = visualEffectView.frame
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 3.0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let cell = cell as? SearchCell, let item = items[safe: indexPath.row] {
            cell.iconImageView.image = UIImage(named: item.mark)
            cell.titleLabel.text = item.title
            cell.subTitleLabel.text = item.subtitle
        }
        return cell
    }

    func showHeader(animated: Bool) {
        changeHeader(height: 116.0, aniamted: animated)
    }

    func hideHeader(animated: Bool) {
        changeHeader(height: 0.0, aniamted: animated)
    }

    private func changeHeader(height: CGFloat, aniamted: Bool) {
        guard let headerView = tableView.tableHeaderView, headerView.bounds.height != height else { return }
        if aniamted == false {
            updateHeader(height: height)
            return
        }
        tableView.beginUpdates()
        UIView.animate(withDuration: 0.25) {
            self.updateHeader(height: height)
        }
        tableView.endUpdates()
    }

    private func updateHeader(height: CGFloat) {
        guard let headerView = tableView.tableHeaderView else { return }
        var frame = headerView.frame
        frame.size.height = height
        self.tableView.tableHeaderView?.frame = frame
    }
}

class SearchCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
}

class SearchHeaderView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.clipsToBounds = true
    }
}

extension UISearchBar {
    func setSearchText(fontSize: CGFloat) {
        if #available(iOS 13, *) {
            let font = searchTextField.font
            searchTextField.font = font?.withSize(fontSize)
        } else {
            let textField = value(forKey: "_searchField") as! UITextField
            textField.font = textField.font?.withSize(fontSize)
        }
    }
}
