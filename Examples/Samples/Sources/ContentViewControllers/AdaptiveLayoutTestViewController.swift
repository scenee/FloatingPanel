// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class AdaptiveLayoutTestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    class PanelLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full

        private weak var targetGuide: UILayoutGuide?
        init(targetGuide: UILayoutGuide?) {
            self.targetGuide = targetGuide
        }
        var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
            if #available(iOS 11.0, *), let targetGuide = targetGuide {
                return [
                    .full: FloatingPanelAdaptiveLayoutAnchor(absoluteOffset: 0.0,
                                                             contentLayout: targetGuide,
                                                             referenceGuide: .superview,
                                                             boundingGuide: .superview),
                    .half: FloatingPanelAdaptiveLayoutAnchor(fractionalOffset: 0.5,
                                                             contentLayout: targetGuide,
                                                             referenceGuide: .superview,
                                                             boundingGuide: .safeArea),

                ]
            } else {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 500,
                                                     edge: .bottom,
                                                     referenceGuide: .superview)
                ]
            }
        }
    }

    @IBOutlet weak var tableView: IntrinsicTableView!
    let cellResuseID = "Cell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellResuseID)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellResuseID, for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        50
    }
}

class IntrinsicTableView: UITableView {

    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
