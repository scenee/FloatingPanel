//
//  ViewController.swift
//  MiddlePanel
//
//  Created by Ramesh R C on 11.12.19.
//  Copyright © 2019 Ramesh R C. All rights reserved.
//

import UIKit
import FloatingPanel

class ViewController: UIViewController {

    var fpc: FloatingPanelController!
    var hotelDetailsVC: HotelDetailsViewController!
    var initialColor: UIColor = .black
    @IBOutlet var middleImageView: UIView!
    @IBOutlet var topNavView: UIView!
    var imageViewTopConstraint: NSLayoutConstraint!
    var imageViewTopSuperViewConstraint: NSLayoutConstraint!
    var inistalMoveValue:CGFloat = -100
    let ppp = FloatingPanelHotelBehavior()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imageViewTopSuperViewConstraint = middleImageView.topAnchor.constraint(equalTo: view.topAnchor, constant:0)
        initialColor = view.backgroundColor!
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = UIColor(displayP3Red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        fpc.surfaceView.cornerRadius = 24.0
        fpc.surfaceView.shadowHidden = true
        fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)

        hotelDetailsVC = storyboard?.instantiateViewController(withIdentifier: "HotelDetailsVC") as? HotelDetailsViewController

        // Set a content view controller
        fpc.set(contentViewController: hotelDetailsVC)
//        fpc.track(scrollView: newsVC.scrollView)
        fpc.addPanel(toParent: self, belowView: nil, animated: false)
        
        middleImageView.frame = .zero
        fpc.view.addSubview(middleImageView)
//        fpc.surfaceView.insertSubview(middleImageView, belowSubview: fpc.surfaceView)
        middleImageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewTopConstraint = middleImageView.topAnchor.constraint(equalTo: fpc.surfaceView.topAnchor, constant: inistalMoveValue)
        
        NSLayoutConstraint.activate([
            imageViewTopSuperViewConstraint,
            middleImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
            middleImageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0.0),
            middleImageView.heightAnchor.constraint(equalToConstant: 200)
            ])
        fpc.view.bringSubviewToFront(fpc.surfaceView)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        let visibleHeight = fpc.surfaceView.frame.height - fpc.surfaceView.frame.minY
        inistalMoveValue = fpc.surfaceView.frame.minY - (visibleHeight/2)
        imageViewTopSuperViewConstraint.constant = inistalMoveValue
        
        self.view.bringSubviewToFront(topNavView)
        
        topNavView.backgroundColor = UIColor.white
        topNavView.alpha = 0
    }
    override func viewDidDisappear(_ animated: Bool) {
        
    }
}

extension ViewController : FloatingPanelControllerDelegate{
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return FloatingPanelHotelLayout(middle: self.view.frame.height/2)
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return nil
    }
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {
        var animator: UIViewPropertyAnimator!
        animator = UIViewPropertyAnimator(duration: 0, curve: .linear) { [unowned self] in
            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
            self.inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
            self.imageViewTopSuperViewConstraint.constant = max(self.inistalMoveValue,0)
        }
        animator.startAnimation()
//        UIView.animate(withDuration: 0.25) {
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            self.inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
//            self.imageViewTopSuperViewConstraint.constant = max(self.inistalMoveValue,0)
//        }
    }
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        
//        UIView.animate(withDuration: 0.25) {
//
//            self.middleImageView.layoutIfNeeded()
//                   }
//
//        var animator: UIViewPropertyAnimator!
//        animator.addCompletion({
//
//        })
//        animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) { [unowned self] in
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            self.inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
//            self.imageViewTopSuperViewConstraint.constant = max(self.inistalMoveValue,0)
//        }
//        animator.startAnimation()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            self.inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
//            self.imageViewTopSuperViewConstraint.constant = max(self.inistalMoveValue,0)
//        })
    }
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            // Dimiss top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.view.backgroundColor = self.initialColor
            }
        }
        
        
//        NSLayoutConstraint.deactivate([imageViewTopSuperViewConstraint] + [imageViewTopConstraint])
//        if (middleImageView.frame.minY >  0){
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            inistalMoveValue = visibleHeight/2
//            imageViewTopConstraint.constant = -inistalMoveValue
//            NSLayoutConstraint.activate([imageViewTopConstraint])
//        }else{
//            NSLayoutConstraint.activate([imageViewTopSuperViewConstraint])
//        }
//        let move = vc.panGestureRecognizer.translation(in: self.view);
//        debugPrint("move",move)
//        imageViewTopConstraint.constant = inistalMoveValue
    }
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition == .full {
            // Present top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.view.backgroundColor = .white
            }
        }
//        let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//        inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
//        imageViewTopSuperViewConstraint.constant = max(inistalMoveValue,0)
        
//        NSLayoutConstraint.deactivate([imageViewTopSuperViewConstraint] + [imageViewTopConstraint])
//        if (middleImageView.frame.minY >  0){
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            inistalMoveValue = visibleHeight/2
//            imageViewTopConstraint.constant = -inistalMoveValue
//            NSLayoutConstraint.activate([imageViewTopConstraint])
//        }else{
//            NSLayoutConstraint.activate([imageViewTopSuperViewConstraint])
//        }
//        let tran = vc.panGestureRecognizer.translation(in: self.view)
//        UIView.animate(withDuration: 0.25) {
//            self.imageViewTopConstraint.constant = tran.y
//        }
//        let move = vc.panGestureRecognizer.translation(in: self.view);
//        debugPrint("move",move)
//        imageViewTopConstraint.constant = inistalMoveValue + move.y
//        inistalMoveValue = inistalMoveValue + move.y
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
//        if vc.surfaceView.frame.minY > vc.originYOfSurface(for: .half) {
//            let progress = vc.surfaceView.frame.minY
            let progress = (vc.surfaceView.frame.minY - vc.originYOfSurface(for: .tip)) / (vc.originYOfSurface(for: .tip) - vc.originYOfSurface(for: .tip))
//            imageViewTopConstraint.constant = max(min(progress, 1.0), 0.0) * 17
//        } else {
//            imageViewTopConstraint.constant = -100
//        }
//        let tran = vc.panGestureRecognizer.translation(in: self.view)
//        UIView.animate(withDuration: 0.25) {
//            self.imageViewTopConstraint.constant = tran.y
//        }
        
//        let move = vc.panGestureRecognizer.translation(in: self.view);
//        if(move.y > 0){
//            inistalMoveValue = (move.y +  inistalMoveValue)
//        }else{
//            inistalMoveValue = (move.y -  inistalMoveValue)
//        }
//        NSLayoutConstraint.deactivate([imageViewTopSuperViewConstraint] + [imageViewTopConstraint])
//        if (middleImageView.frame.minY >  0){
//            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
//            inistalMoveValue = visibleHeight/2
//            imageViewTopConstraint.constant = -inistalMoveValue
//            NSLayoutConstraint.activate([imageViewTopConstraint])
//        }else{
//            NSLayoutConstraint.activate([imageViewTopSuperViewConstraint])
//        }
//        if (move.y > 0){
//            // Moving dwon
//
//        }else{
//            // Moving UP
//        }
        
//        if (middleImageView.frame.minY >  0){
            let visibleHeight = vc.surfaceView.frame.height - vc.surfaceView.frame.minY
            inistalMoveValue = vc.surfaceView.frame.minY - (visibleHeight/2)
            imageViewTopSuperViewConstraint.constant = max(inistalMoveValue,0)
//        }else{
//
//        }
        
        let percentage:CGFloat  = vc.surfaceView.frame.minY/self.view.frame.size.height
        topNavView.alpha = 1.0 - percentage
    }
}


class FloatingPanelHotelLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .tip
    }

    var topInteractionBuffer: CGFloat { return 0.0 }
    var bottomInteractionBuffer: CGFloat { return 0.0 }
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    var mm:CGFloat = 262.0
    init(middle:CGFloat) {
        mm = middle
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 0.0
        case .half: return mm
        default: return nil
        }
    }

    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
}


class FloatingPanelHotelBehavior: FloatingPanelBehavior {
    var velocityThreshold: CGFloat {
        return 15.0
    }

    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(to: targetPosition, with: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }

    private func timeingCurve(to: FloatingPanelPosition, with velocity: CGVector) -> UITimingCurveProvider {
        let damping = self.damping(with: velocity)
        return UISpringTimingParameters(dampingRatio: damping,
                                        frequencyResponse: 0.4,
                                        initialVelocity: velocity)
    }

    private func damping(with velocity: CGVector) -> CGFloat {
        switch velocity.dy {
        case ...(-velocityThreshold):
            return 0.7
        case velocityThreshold...:
            return 0.7
        default:
            return 1.0
        }
    }
}
