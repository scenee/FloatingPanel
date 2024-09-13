//
//  RCSegmentedControl.swift
//  
//
//  Created by Ramesh R C on 17.10.19.
//  Copyright © 2019 SyroCon. All rights reserved.
//

import Foundation
import UIKit
protocol RCSegmentedControlDelegate:class {
    func changeToIndex(index:Int)
}

class RCSegmentedControl: UIView {
    private var buttonTitles:[String]!
    private var buttons: [UIButton]!
    private var selectorView: UIView!
    private var bottomView: UIView!
    
//    var textColor:UIColor = .black
//    var selectorViewColor: UIColor = .red
//    var selectorTextColor: UIColor = .red
//    var bottomViewColor: UIColor = .gray
//    var titleFont: UIFont = UIFont.systemFont(ofSize: 15)
//    var titleSelectionFont: UIFont = UIFont.systemFont(ofSize: 16)
    
    weak var delegate:RCSegmentedControlDelegate?
    var config:RCSegmentButtonConfig = RCSegmentButtonConfig()
    var selectorViewLeft:NSLayoutConstraint?
    
    private var _selectedIndex:Int = 0
    public var seletedIndex : Int {
        return _selectedIndex
    }
    
    convenience init(frame:CGRect,buttonTitle:[String]) {
        self.init(frame: frame)
        self.buttonTitles = buttonTitle
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.backgroundColor = UIColor.white
        updateView()
    }
    override func layoutSubviews() {
        configSelectorView()
    }
    func setButtonTitles(buttonTitles:[String]) {
        self.buttonTitles = buttonTitles
        self.updateView()
    }
    
    func setIndex(index:Int) {
        buttons.forEach({ $0.setTitleColor(config.textColor, for: .normal) })
        let button = buttons[index]
        self.buttonAction(sender: button)
        
//        _selectedIndex = index
//        button.setTitleColor(config.selectorTextColor, for: .normal)
//        let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(index)
//        UIView.animate(withDuration: 0.2) {
////            self.selectorView.frame.origin.x = selectorPosition
//            self.selectorViewLeft?.constant = selectorPosition
//            self.layoutIfNeeded()
//        }
    }
    
    @objc func buttonAction(sender:UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.setTitleColor(config.textColor, for: .normal)
            btn.titleLabel?.font = config.titleFont
            if btn == sender {
                let selectorPosition = frame.width/CGFloat(buttonTitles.count) * CGFloat(buttonIndex)
                _selectedIndex = buttonIndex
                delegate?.changeToIndex(index: _selectedIndex)
                UIView.animate(withDuration: 0.3) {
//                    self.selectorView.frame.origin.x = selectorPosition
                    self.selectorViewLeft?.constant = selectorPosition
                    self.layoutIfNeeded()
                }
                btn.setTitleColor(config.selectorTextColor, for: .normal)
                btn.titleLabel?.font = config.titleSelectionFont
            }
        }
    }
}

//Configuration View
extension RCSegmentedControl {
    private func updateView() {
        createButton()
        configBottomLineView()
        configStackView()
    }
    
    private func configStackView() {
        let scrollview = UIScrollView()
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.showsHorizontalScrollIndicator = false
        addSubview(scrollview)
        scrollview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scrollview.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        scrollview.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        scrollview.addSubview(stack)
//        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: scrollview.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: scrollview.leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: scrollview.rightAnchor).isActive = true
        
        let wConstraint = stack.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1)
//        wConstraint.priority = .defaultLow
        wConstraint.isActive = true
    }
    
    private func configSelectorView() {
        guard let buttonTitles = self.buttonTitles,
            selectorView == nil else {
            return
        }
        let selectorWidth = frame.width / CGFloat(buttonTitles.count)
        let height = CGFloat(buttonTitles.count < 2 ? 0 : 2)
        selectorView = UIView()
        selectorView.translatesAutoresizingMaskIntoConstraints = false
        selectorView.backgroundColor = config.selectorViewColor
        insertSubview(selectorView, aboveSubview: self)
        
        selectorViewLeft = selectorView.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 0)
        selectorViewLeft?.isActive = true
        selectorView.widthAnchor.constraint(equalToConstant: (selectorWidth - 20)).isActive = true
        selectorView.heightAnchor.constraint(equalToConstant: height).isActive = true
        selectorView.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: 0).isActive = true
    }
    
    private func configBottomLineView() {
        guard let buttonTitles = self.buttonTitles else {return}
        
        let height = CGFloat(buttonTitles.count < 2 ? 0 : 2)
        bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = config.bottomViewColor
        addSubview(bottomView)
        bottomView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        bottomView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    private func createButton() {
        buttons = [UIButton]()
        buttons.removeAll()
        subviews.forEach({$0.removeFromSuperview()})
        guard let buttonTitles = self.buttonTitles else {
            return
        }
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .custom)
            button.setTitle(buttonTitle, for: .normal)
            button.addTarget(self, action:#selector(RCSegmentedControl.buttonAction(sender:)), for: .touchUpInside)
            button.setTitleColor(config.textColor, for: .normal)
            buttons.append(button)
            button.titleLabel?.font = config.titleFont
            button.sizeToFit()
        }
        buttons[0].setTitleColor(config.selectorTextColor, for: .normal)
        buttons[0].titleLabel?.font = config.titleSelectionFont
    }
    
}

public struct RCSegmentedConfig {

}
