//
//  RCSegmentPageViewController.swift
//  Example
//
//  Created by Ramesh R C on 21.03.20.
//  Copyright © 2020 Ramesh R C. All rights reserved.
//

import UIKit

protocol RCSegmentPageViewControllerDelegate:class {
    func didDisplayViewController(vc:UIViewController, at index:Int)
}

class RCSegmentPageViewController: UIPageViewController {

    weak var segmentPageDelegate:RCSegmentPageViewControllerDelegate?
    public var orderedViewController : [UIViewController] = [] {
        didSet {
            DispatchQueue.main.async {
                self.refreshViewControllers()
            }
        }
    }
    fileprivate lazy var currentIndex = 0
    
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.prepareView()
    }
    
    private func prepareView(){
        self.dataSource = self
        self.delegate = self
    }
    
    private func refreshViewControllers(){
        if let firstVC = orderedViewController.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
    }

    private func getVcIndex(vc:UIViewController) -> Int?{
        if(orderedViewController.count > 0 && orderedViewController.firstIndex(of: vc) ?? -1 < orderedViewController.count){
            return  orderedViewController.firstIndex(of: vc)
        }
        return nil
    }
    
    func visibleVC(at index:Int){
        guard orderedViewController.count > index,
            currentIndex != index else {
            return
        }
        let vc = orderedViewController[index]
        // Managing scroll direction
        if (currentIndex < index){
            setViewControllers([vc], direction:UIPageViewController.NavigationDirection.forward, animated: true, completion: { _ in})
        }else{
            setViewControllers([vc], direction:UIPageViewController.NavigationDirection.reverse, animated: true, completion: { _ in})
        }
        currentIndex = index
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RCSegmentPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewController.firstIndex(of: viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {return nil }
        guard orderedViewController.count > previousIndex else { return nil }
        return orderedViewController[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewController.firstIndex(of: viewController) else { return nil }
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < orderedViewController.count else { return nil }
        guard orderedViewController.count > nextIndex else { return nil }
        return orderedViewController[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if(finished){
            guard let vc = pageViewController.viewControllers?.first else { return  }
            guard let d = segmentPageDelegate, let index = self.getVcIndex(vc: vc) else {return}
            d.didDisplayViewController(vc: vc, at: index)
            self.currentIndex = index
        }
    }
    
    func presentationCount(for: UIPageViewController) -> Int {
        return orderedViewController.count - 1
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return -1
    }
}
