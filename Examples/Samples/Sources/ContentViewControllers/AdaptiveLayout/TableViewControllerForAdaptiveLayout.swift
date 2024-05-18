// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class TableViewControllerForAdaptiveLayout: UIViewController, UITableViewDataSource, UITableViewDelegate {
    class PanelLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full

        private unowned var targetGuide: UILayoutGuide

        init(targetGuide: UILayoutGuide) {
            self.targetGuide = targetGuide
        }

        var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
            return [
                .full: FloatingPanelAdaptiveLayoutAnchor(
                    absoluteOffset: 0.0,
                    contentLayout: targetGuide,
                    referenceGuide: .superview,
                    contentBoundingGuide: .safeArea
                ),
                .half: FloatingPanelAdaptiveLayoutAnchor(
                    fractionalOffset: 0.5,
                    contentLayout: targetGuide,
                    referenceGuide: .superview,
                    contentBoundingGuide: .safeArea
                ),
            ]
        }
    }

    @IBOutlet weak var tableView: IntrinsicTableView!
    private let cellID = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .orange
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        40
    }
}

class IntrinsicTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
