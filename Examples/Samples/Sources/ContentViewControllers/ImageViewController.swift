// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class ImageViewController: UIViewController {
    class PanelLayout: FloatingPanelLayout {
        private unowned var targetGuide: UILayoutGuide
        init(targetGuide: UILayoutGuide) {
            self.targetGuide = targetGuide
        }
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full
        var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
            return [
                .full: FloatingPanelAdaptiveLayoutAnchor(
                    absoluteOffset: 0,
                    contentLayout: targetGuide,
                    referenceGuide: .superview
                ),
                .half: FloatingPanelAdaptiveLayoutAnchor(
                    fractionalOffset: 0.5,
                    contentLayout: targetGuide,
                    referenceGuide: .superview
                )
            ]
        }
    }

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    enum Mode {
        case onlyImage
        case withHeaderFooter
    }

    func layoutGuideFor(mode: Mode) -> UILayoutGuide {
        switch mode {
        case .onlyImage:
            self.headerView.isHidden = true
            self.footerView.isHidden = true
            return scrollView.contentLayoutGuide
        case .withHeaderFooter:
            self.headerView.isHidden = false
            self.footerView.isHidden = false
            let guide = UILayoutGuide()
            view.addLayoutGuide(guide)

            NSLayoutConstraint.activate([
                scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor),

                guide.topAnchor.constraint(equalTo: stackView.topAnchor),
                guide.leftAnchor.constraint(equalTo: stackView.leftAnchor),
                guide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
                guide.rightAnchor.constraint(equalTo: stackView.rightAnchor),
            ])
            return guide
        }
    }
}

