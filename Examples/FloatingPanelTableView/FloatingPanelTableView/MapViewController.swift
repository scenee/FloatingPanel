//
//  MapViewController.swift
//  FloatingPanelTableView
//
//  Created by Ramesh R C on 26.03.20.
//  Copyright © 2020 Ramesh R C. All rights reserved.
//
import UIKit
import FloatingPanel
import MapKit

class MapViewController: UIViewController {

    var fpc: FloatingPanelController!
    var galleryDetailsVC: ViewController2!
    let ppp = FloatingPanelHotelBehavior()
    @IBOutlet weak var mapView: MKMapView!
    var xpostion: CGFloat = 0.0
    var isLock:Bool = false
    var panelHotelLayout:FloatingPanelHotelLayout?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
        galleryDetailsVC = storyboard?.instantiateViewController(withIdentifier: "ViewController2") as? ViewController2

        // Set a content view controller
        fpc.set(contentViewController: galleryDetailsVC)
        fpc.addPanel(toParent: self, belowView: nil, animated: false)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//            self.fpc.track(scrollView: self.galleryDetailsVC.tableView)
//        })
        
        NotificationCenter.default.removeObserver(self, name: .FloatingTrackScrollView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTrackScrollView),
                                               name: .FloatingTrackScrollView, object: nil)
        
        self.moveAnimation()
        galleryDetailsVC.hitView.mapView = mapView
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    @objc private func setTrackScrollView(_ notification: NSNotification){
        guard let trackView = notification.object as? UITableView else {
            return
        }
        fpc.track(scrollView: nil)
        fpc.track(scrollView: trackView)
    }
 
    func moveAnimation(){
        let a = UIScreen.main.bounds.height - 200
        let b =  max(0, fpc.surfaceView.frame.minY / a)
        let hRedView = CGFloat(350) // Get from object
        let trans = b * hRedView
        debugPrint("trans",trans)
        debugPrint("b:",b)
        galleryDetailsVC.redView.transform = CGAffineTransform(translationX: 0, y: trans)
    }
}

extension MapViewController : FloatingPanelControllerDelegate{
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        panelHotelLayout = FloatingPanelHotelLayout(middle: self.view.frame.height/2, topBuffer: 200)
        return panelHotelLayout
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return FloatingPanelHotelBehavior()
    }
    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {
        self.animate(vc)
    }
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        debugPrint("floatingPanelWillBeginDragging")
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        self.animate(vc)
    }
    func floatingPanelDidViewLayout(_ vc: FloatingPanelController) {
        self.animate(vc)
    }
    
    func animate(_ vc: FloatingPanelController){
        let a = UIScreen.main.bounds.height - (UIScreen.main.bounds.height / 2 )
        let b =  max(0, vc.surfaceView.frame.minY / a)
        let b1 =  vc.surfaceView.frame.minY / a
        if(b1 < 0){
            galleryDetailsVC.viewWhiteAlpha.alpha = (abs(b1))
        }else{
            galleryDetailsVC.viewWhiteAlpha.alpha = 0
        }
        let hRedView = CGFloat(350/2) // Get from object
        let trans = b * hRedView
        galleryDetailsVC.redView.transform = CGAffineTransform(translationX: 0, y: trans)
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
    var topBuffer:CGFloat = 314
    
    init(middle:CGFloat,topBuffer:CGFloat) {
        self.mm = middle
        self.topBuffer = 350 //topBuffer
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return -self.topBuffer
        case .half: return UIScreen.main.bounds.height
        case .tip: return UIScreen.main.bounds.height / 2  // Visible + ToolView
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

extension MapViewController {
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

extension Notification.Name {
    static let FloatingTrackScrollView = Notification.Name("FloatingTrackScrollView")
}
