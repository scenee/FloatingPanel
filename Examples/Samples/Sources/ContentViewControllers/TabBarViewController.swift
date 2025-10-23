// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class TabBarViewController: UITabBarController {}

final class TabBarContentViewController: UIViewController {
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


        if #available(iOS 15, *) {
            tabBarController?.tabBar.scrollEdgeAppearance = UITabBarAppearance()
        }

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
    let initialState: FloatingPanelState = .half
    let position: FloatingPanelPosition = .bottom
    let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(absoluteInset: 261.0, edge: .bottom, referenceGuide: .safeArea)
    ]
}

final class TwoTabBarPanelBehavior: FloatingPanelBehavior {
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

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.3
    }

    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        leftConstraint = surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0)
        rightConstraint = surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0.0)
        return [ leftConstraint, rightConstraint ]
    }
}
