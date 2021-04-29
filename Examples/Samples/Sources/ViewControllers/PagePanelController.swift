// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

class PagePanelController: NSObject {
    lazy var pages = [UIColor.blue, .red, .green].compactMap({ (color) -> UIViewController in
        let page = FloatingPanelController(delegate: self)
        page.view.backgroundColor = color
        page.panGestureRecognizer.delegateProxy = self
        page.show()
        return page
    })

    func makePageViewControllerForContent() -> UIPageViewController {
        pages = [DebugTableViewController(), DebugTableViewController(), DebugTableViewController()]
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        pageVC.dataSource = self
        pageVC.delegate = self
        pageVC.setViewControllers([pages[0]], direction: .forward, animated: false, completion: nil)
        return pageVC
    }

    func makePageViewController(for vc: SampleListViewController) -> UIPageViewController {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        let closeButton = UIButton(type: .custom)
        pageVC.view.addSubview(closeButton)
        closeButton.setTitle("Close", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(vc, action: #selector(SampleListViewController.dismissPresentedVC), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: pageVC.layoutGuide.topAnchor, constant: 16.0),
            closeButton.leftAnchor.constraint(equalTo: pageVC.view.leftAnchor, constant: 16.0),
            ])
        pageVC.dataSource = self
        pageVC.setViewControllers([pages[0]], direction: .forward, animated: false, completion: nil)
        pageVC.modalPresentationStyle = .fullScreen
        return pageVC
    }
}

extension PagePanelController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return FloatingPanelBottomLayout()
    }
}

extension PagePanelController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}


extension PagePanelController: UIPageViewControllerDataSource {
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

extension PagePanelController: UIPageViewControllerDelegate {
    // For showPageContent
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let page = pageViewController.viewControllers?.first {
            (pageViewController.parent as! FloatingPanelController).track(scrollView: (page as! DebugTableViewController).tableView)
        }
    }
}
