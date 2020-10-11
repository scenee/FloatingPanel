//
//  RCSegmentView.swift
//  Example
//
//  Created by Ramesh R C on 21.03.20.
//  Copyright © 2020 Ramesh R C. All rights reserved.
//

import UIKit

public protocol RCSegmentViewDelegate:class {
    func setController() -> [RCSegmentSlide]
    func didDisplayViewController(vc:UIViewController, at index:Int)
    func updateConfig() -> RCSegmentButtonConfig
}

open class RCSegmentView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    public var delegate:RCSegmentViewDelegate?
    public var config:RCSegmentButtonConfig =  RCSegmentButtonConfig()
    var segmentViewHeight:NSLayoutConstraint?
    
    fileprivate lazy var segmentControllerView : RCSegmentedControl = {
        let segmentedControl = RCSegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.delegate = self
        return segmentedControl
    }()
    
    fileprivate lazy var segmentPageViewController : RCSegmentPageViewController = {
        let sPageView = RCSegmentPageViewController()
        sPageView.view.translatesAutoresizingMaskIntoConstraints = false
        sPageView.segmentPageDelegate = self
        return sPageView
    }()
    
    convenience override init(frame:CGRect) {
        self.init(frame: frame)
    }
    
    convenience init(frame:CGRect,withConfig config:RCSegmentButtonConfig) {
        self.init(frame: UIScreen.main.bounds)
        self.config = config
    }
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = UIColor.white
        updateView()
    }
    
    private func updateView() {
        self.addSegmentTabView()
        self.addSegmentPageViewController()
        
        self.setController()
    }
    
    private func setController(){
        guard let d = delegate else {return}
        segmentPageViewController.orderedViewController = d.setController().map({$0.vc})
        segmentControllerView.config = d.updateConfig()
        segmentControllerView.setButtonTitles(buttonTitles: d.setController().map({$0.buttonTitle}))
        if (d.setController().map({$0.buttonTitle}).count < 2){
            segmentViewHeight?.constant = 0
            self.layoutIfNeeded()
        }
    }
    
    
    func addSegmentTabView(){
        self.addSubview(segmentControllerView)
        segmentControllerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        segmentControllerView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        segmentControllerView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        segmentViewHeight = segmentControllerView.heightAnchor.constraint(equalToConstant: 40)
        segmentViewHeight?.isActive = true
    }
    
    func addSegmentPageViewController(){
        self.addSubview(segmentPageViewController.view)
        segmentPageViewController.view.topAnchor.constraint(equalTo: segmentControllerView.bottomAnchor, constant: 10).isActive = true
//        segmentPageViewController.view.topAnchor.constraint(equalTo: segmentControllerView.bottomAnchor).isActive = true
        segmentPageViewController.view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        segmentPageViewController.view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        segmentPageViewController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}

extension RCSegmentView: RCSegmentPageViewControllerDelegate {
    
    func didDisplayViewController(vc: UIViewController, at index: Int) {
        guard let d = delegate else {return}
        d.didDisplayViewController(vc: vc, at: index)
        segmentControllerView.setIndex(index: index)
    }
}
extension RCSegmentView: RCSegmentedControlDelegate {
    func changeToIndex(index: Int) {
        // Heree updateing screen
        segmentPageViewController.visibleVC(at: index)
    }
}

public struct RCSegmentSlide {
    public var buttonTitle : String
    public var vc : UIViewController
    
    public init(buttonTitle: String, vc: UIViewController) {
        self.buttonTitle = buttonTitle
        self.vc = vc
    }
}

public struct RCSegmentButtonConfig {
    var textColor:UIColor = .black
    var selectorViewColor: UIColor = .red
    var selectorTextColor: UIColor = .red
    var bottomViewColor: UIColor = .gray
    var titleFont: UIFont = UIFont.systemFont(ofSize: 15)
    var titleSelectionFont: UIFont = UIFont.systemFont(ofSize: 16)
    
    public init() {
        
    }
}
