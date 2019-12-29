//
//  ViewController.swift
//  ImageGallery
//
//  Created by Ramesh R C on 19.12.19.
//  Copyright © 2019 Ramesh R C. All rights reserved.
//

import UIKit
import FloatingPanel
import MapKit

class ViewController: UIViewController {

    var fpc: FloatingPanelController!
    var galleryDetailsVC: GalleryDetailsViewController!
    var initialColor: UIColor = .black
    @IBOutlet var middleImageView: UIView!
    @IBOutlet var topNavView: UIView!
    var imageViewTopConstraint: NSLayoutConstraint!
    var imageViewTopSuperViewConstraint: NSLayoutConstraint!
    var inistalMoveValue:CGFloat = -100
    let ppp = FloatingPanelHotelBehavior()
    @IBOutlet weak var mapView: MKMapView!
    var xpostion: CGFloat = 0.0
    var isLock:Bool = false
    var panelHotelLayout:FloatingPanelHotelLayout?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        initialColor = view.backgroundColor!
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 0.0
        fpc.surfaceView.shadowHidden = true
        fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)
        fpc.surfaceView.clipsToBounds = true
        fpc.view.clipsToBounds = true
        fpc.surfaceView.grabberHandle.isHidden = true
        galleryDetailsVC = storyboard?.instantiateViewController(withIdentifier: "GalleryDetailsViewController") as? GalleryDetailsViewController

        // Set a content view controller
        fpc.set(contentViewController: galleryDetailsVC)
        fpc.track(scrollView: galleryDetailsVC.viewContent)
        fpc.addPanel(toParent: self, belowView: nil, animated: false)
        galleryDetailsVC.hitView.mapView = self.mapView
        if let _ = galleryDetailsVC.setLockStatus{
            galleryDetailsVC.setLockStatus = { isLock in
                self.isLock = isLock
            }
        }
        galleryDetailsVC.addImageView()
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
}

    extension ViewController : FloatingPanelControllerDelegate{
        func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
            panelHotelLayout = FloatingPanelHotelLayout(middle: self.view.frame.height/2, topBuffer: 200)
            return panelHotelLayout
        }

        func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
            return FloatingPanelHotelBehavior()
        }
//        func floatingPanelShouldBeginDragging(_ vc: FloatingPanelController) -> Bool {
//            debugPrint("isLock",isLock)
//            return !isLock
//        }
        func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {
//            self.doViewImageMove(vc)
//            if (vc.position == .full){
//                galleryDetailsVC.toogleConstraint(isWindowAlign:true,diffValue: 0)
//            }else if (vc.position == .half){ galleryDetailsVC.toogleConstraint(isWindowAlign:true,diffValue: 0)
//            }
//            else if (vc.position == .tip){ galleryDetailsVC.toogleConstraint(isWindowAlign:true,diffValue: 500)
//            }
            
//            let diff = 414 -  vc.surfaceView.frame.minY
//            var ppdiff:CGFloat = -50
//            if(diff < galleryDetailsVC.viewPicture.frame.height){
////                galleryDetailsVC.viewPicture.transform = CGAffineTransform(translationX: 0, y: -diff)
//                ppdiff = diff
//            }
//            if (diff < 0){
////                galleryDetailsVC.viewPicture.transform = CGAffineTransform(translationX: 0, y: -50)
//                ppdiff = -50
//            }
//            if(vc.position == .half ||
//                vc.position == .full){
//                galleryDetailsVC.toogleConstraint(isWindowAlign:true,diffValue: ppdiff)
//            }else{
//                galleryDetailsVC.toogleConstraint(isWindowAlign:false,diffValue: ppdiff)
//            }
            
            
            
            
            
            
//            if(vc.position == .full){
//                isLock = true
//            }
//            debugPrint("vc.surfaceView.frame.minY",vc.surfaceView.frame.minY)
//            if vc.surfaceView.frame.minY == 0 {
////                galleryDetailsVC.viewContent.isUserInteractionEnabled = true
//
////                let diff = self.view.frame.height - galleryDetailsVC.viewContent.frame.minY
////                debugPrint("galleryDetailsVC.viewContent.frame.minY",galleryDetailsVC.viewContent.frame.minY)
////                debugPrint("translation",vc.panGestureRecognizer.translation(in: self.view))
////                galleryDetailsVC.viewContent.transform = CGAffineTransform(scaleX: 0, y: -diff)
//            }else{
////                galleryDetailsVC.viewContent.transform = CGAffineTransform(scaleX: 0, y: 0)
//            }
        }
//        func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
//            if(vc.position == .full){
//                galleryDetailsVC.activeDrag = true
//            }
//        }
        func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
            panelHotelLayout?.initialTranslationY =  galleryDetailsVC.imageViewConstraintValue()
        }
        func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        }
        func floatingPanelDidMove(_ vc: FloatingPanelController) {
//            self.doViewImageMove(vc)
        }
        
        func doViewImageMove(_ vc: FloatingPanelController){
            let translation = vc.panGestureRecognizer.translation(in: self.view)
            let velocity = vc.panGestureRecognizer.velocity(in:  self.view)
            
            let dy = (panelHotelLayout?.initialTranslationY ?? 0) - abs(translation.y)
                //abs(translation.y) - (panelHotelLayout?.initialTranslationY ?? 0)
//            debugPrint("dy",dy)
//            debugPrint("velocity",velocity.y)
//            debugPrint("translation.y",translation.y)
//            debugPrint("perce Y:",translation.y / vc.surfaceView.frame.height)
            let diff_1 = 500 -  vc.surfaceView.frame.minY
            let diff = 500 -  abs(translation.y)
            var ppdiff:CGFloat = -50
            if(diff < galleryDetailsVC.viewPicture.frame.height){
//                galleryDetailsVC.viewPicture.transform = CGAffineTransform(translationX: 0, y: -diff)
                ppdiff = diff
            }
            if (diff < 0){
//                galleryDetailsVC.viewPicture.transform = CGAffineTransform(translationX: 0, y: -50)
                ppdiff = -50
            }
//            debugPrint("ppdiff",diff)
            let ddd = diff_1 - 500
            debugPrint("diff_1",diff_1)
            debugPrint("ddd",ddd)
            galleryDetailsVC.viewPicture.transform = CGAffineTransform(translationX: 0, y:  vc.surfaceView.frame.minY)
            
//            galleryDetailsVC.toogleConstraint(isWindowAlign:true,diffValue: vc.surfaceView.frame.minY)
        }
        
    }


class FloatingPanelHotelLayout: FloatingPanelLayout {
    var initialTranslationY: CGFloat = 0
    var positionReference: FloatingPanelLayoutReference {
        return .fromSuperview
    }
    var initialPosition: FloatingPanelPosition {
        return .tip
    }

    var topInteractionBuffer: CGFloat { return self.topBuffer }
    var bottomInteractionBuffer: CGFloat { return 0.0 }
    var mm:CGFloat = 262.0
    var topBuffer:CGFloat = 200
    
    init(middle:CGFloat,topBuffer:CGFloat) {
        self.mm = middle
        self.topBuffer = topBuffer
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return -self.topBuffer
        case .half: return UIScreen.main.bounds.height
        case .tip: return 500 // Visible + ToolView
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




protocol LayoutGuideProvider {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}
extension UILayoutGuide: LayoutGuideProvider {}

class CustomLayoutGuide: LayoutGuideProvider {
    let topAnchor: NSLayoutYAxisAnchor
    let bottomAnchor: NSLayoutYAxisAnchor
    init(topAnchor: NSLayoutYAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) {
        self.topAnchor = topAnchor
        self.bottomAnchor = bottomAnchor
    }
}

extension UIViewController {
    var layoutInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: topLayoutGuide.length,
                                left: 0.0,
                                bottom: bottomLayoutGuide.length,
                                right: 0.0)
        }
    }

    var layoutGuide: LayoutGuideProvider {
        if #available(iOS 11.0, *) {
            return view!.safeAreaLayoutGuide
        } else {
            return CustomLayoutGuide(topAnchor: topLayoutGuide.bottomAnchor,
                                     bottomAnchor: bottomLayoutGuide.topAnchor)
        }
    }
}
