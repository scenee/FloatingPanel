//
//  GalleryDetailsViewController.swift
//  FloatingPanel
//
//  Created by Ramesh R C on 19.12.19.
//  Copyright © 2019 scenee. All rights reserved.
//

import UIKit
import MapKit

class GalleryDetailsViewController: UIViewController {

    @IBOutlet weak var viewContent: UITableView!{
        didSet{
//            viewContent.delegate = self
        }
    }
    @IBOutlet weak var viewPicture: UIView!
    @IBOutlet weak var viewNav: UIView!{
        didSet{
            viewNav.alpha = 0
        }
    }
    @IBOutlet weak var viewDrag: UIView!
    private var initialTranslationY: CGFloat = 0
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var hitView: HitView!
    @IBOutlet weak var lblTitle: UILabel!
    var gesture:UIPanGestureRecognizer?
    var activeDrag:Bool = false{
        didSet{
            guard let gestureEvent = gesture,
            let viewObj = viewDrag else{
                return
            }
            gesture?.isEnabled = activeDrag
//            if(activeDrag){
//                viewObj.addGestureRecognizer(gestureEvent)
//            }else{
//                viewObj.removeGestureRecognizer(gestureEvent)
//            }
        }
    }
    var shouldScroll:Bool?{
        didSet{
            viewContent.isScrollEnabled = shouldScroll ?? false
//            viewContent.panGestureRecognizer.isEnabled = shouldScroll ?? false
        }
    }
    
    //    @IBOutlet weak var scrollView: UIScrollView!
    
//    override func viewDidLayoutSubviews() {
//        if (self.topConstraint.constant == 0){
////            self.activeDrag = true
//            self.shouldScroll = false
//            self.activeDrag = false
//        }
//
//        if (self.topConstraint.constant == -200){
////            self.activeDrag = true
//            self.shouldScroll = true
//            self.activeDrag = true
//        }
//    }
    var setLockStatus: ((_ isLock: Bool) -> Void)?

    @IBOutlet var topViewImage: NSLayoutConstraint!
    var topViewImageWindow: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewPicture.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        viewPicture.layer.cornerRadius = 24
                
//        gesture = UIPanGestureRecognizer(target: self, action: #selector(wasDragged(gestureRecognizer:)))
//        viewDrag.addGestureRecognizer(gesture!)
        
//        let gestureTableView = UIPanGestureRecognizer(target: self, action: #selector(tableviewDrag(gestureRecognizer:)))
//        viewContent.addGestureRecognizer(gestureTableView)
        
        
//        activeDrag = false
//        shouldScroll = false
//        viewDrag.isUserInteractionEnabled = false
        // Do any additional setup after loading the view.
        self.lblTitle.text = ""
    }
    override func viewDidLayoutSubviews() {
        if let pomint = viewContent.superview?.superview?.convert(hitView.frame.origin, to: nil){
            if(pomint.y >= 0){
                self.viewPicture.transform = CGAffineTransform(translationX: 0, y:  pomint.y)
            }
        }
    }
    
    @IBAction func btnTapped(_ sender: Any) {
        
        let refreshAlert = UIAlertController(title: "Refresh", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    func doTransform(offSet:CGRect) {
        let currentY = viewPicture.frame.minY
        let perc = viewPicture.frame.height / offSet.minY
        
//        viewPicture.transform = CGAffineTransform(translationX: 0, y: -currentY*perc)
//        let heightValue = 414-offSet.minY
//        viewPicture.transform = CGAffineTransform(translationX: 0, y: -heightValue)
//        debugPrint("currentY",currentY)
//        debugPrint("perc",perc)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func shouldActiveDrag() -> Bool {
        return topConstraint.constant != 0
    }
    @objc func tableviewDrag(gestureRecognizer: UIPanGestureRecognizer) {
        
//        switch gestureRecognizer.state {
//        case .began:
            debugPrint("velocity",gestureRecognizer.velocity(in: self.view))
            let dragVelocity = gestureRecognizer.velocity(in: self.view)
            if(dragVelocity.y < 0 && self.topConstraint.constant <= 0){
                self.activeDrag = true
                self.wasDragged(gestureRecognizer: gestureRecognizer)
            }
//            break
//        case .ended, .cancelled, .failed , .changed: break
//        default:break
//        }
    }
    @objc func wasDragged(gestureRecognizer: UIPanGestureRecognizer) {
        // Ensure it's a horizontal drag
//        let velocity = gestureRecognizer.velocity(in: self.view)
//        if (velocity.y > 0 && self.topConstraint.constant == 0){
//            activeDrag = false
//        }
        
        
        let translation = gestureRecognizer.translation(in: self.view)
        switch gestureRecognizer.state {
        case .began:
            initialTranslationY = topConstraint.constant
            break
        case .changed:
            let dy = translation.y + initialTranslationY
//            debugPrint("dy",dy)
            // 5
            if (abs(dy) <= 200){
                self.topConstraint.constant = min(dy,0)
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    options: UIView.AnimationOptions.curveEaseOut,
                    animations: {
                        self.view.layoutIfNeeded()
                },completion: { _ in})
                
            }
            if dy == 0{
                activeDrag = false
            }
        case .ended, .cancelled, .failed:
            self.adjustTheDragView()
            break
        default:
            break
        }
    }

    func adjustTheDragView(){
        switch self.topConstraint.constant {
        case -100 ... 0:
            self.topConstraint.constant = 0
            self.activeDrag = false
            self.setLockStatus?(false)
        default:
            self.topConstraint.constant = -200
            self.activeDrag = true
            self.setLockStatus?(true)
        }
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: UIView.AnimationOptions.curveEaseOut,
            animations: {
                self.view.layoutIfNeeded()
        },completion: { _ in})
        
        
        let percentage =  self.topConstraint.constant / 200
        let dim = abs(0 - abs(percentage))
        debugPrint("dim",dim)
        
        let opts : UIView.AnimationOptions = .transitionCrossDissolve
        UIView.transition(with: self.lblTitle, duration: 0.75, options: opts, animations: {
            self.viewNav.alpha = dim
            self.lblTitle.text = "Well this sample text"
        }, completion: { _ in
            self.activeDrag = false
        })
    }
    
    func addImageView()  {
        guard let topView = UIApplication.shared.windows.first?.rootViewController?.view
            else {
            print("No root view on which to draw")
            return
        }
//        let viewImage = UIView(frame: CGRect.zero)
//        self.view.insertSubview(viewImage, aboveSubview: hitView)
//        viewImage.translatesAutoresizingMaskIntoConstraints = false
//
//        viewImage.heightAnchor.constraint(equalToConstant: 200).isActive = true
//        viewImage.widthAnchor.constraint(equalTo: topView.widthAnchor).isActive = true
//        viewImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0).isActive = true
//        viewImage.topAnchor.constraint(equalTo: topView.topAnchor, constant: 0).isActive = true
        NSLayoutConstraint.deactivate([topViewImage])
        topViewImageWindow = viewPicture.topAnchor.constraint(equalTo: topView.topAnchor, constant: 0)
        topViewImageWindow.isActive = true
        viewPicture.transform = CGAffineTransform(translationX: 0, y: 500)
//        viewImage.backgroundColor = UIColor.green
    }
    
    func toogleConstraint(isWindowAlign:Bool,diffValue:CGFloat) {
        topViewImageWindow.constant = diffValue < 0 ? 0 : max(abs(diffValue),0)
        self.viewPicture.layoutIfNeeded()
//        UIView.animate(
//            withDuration: 0.1,
//            delay: 0,
//            options: UIView.AnimationOptions.curveEaseOut,
//            animations: {
//
//        },completion: { _ in})
        
//        NSLayoutConstraint.deactivate([topViewImageWindow,topViewImage])
//        if(isWindowAlign){
//            NSLayoutConstraint.activate([topViewImageWindow])
//            topViewImageWindow.constant = diffValue
////            self.viewPicture.transform = CGAffineTransform(translationX: 0, y:  )
//        }else{
//            NSLayoutConstraint.activate([topViewImage])
//            topViewImage.constant = max(diffValue,0)
////            self.viewPicture.transform = CGAffineTransform(translationX: 0, y: diffValue)
//        }
    }
    
    func imageViewConstraintValue()-> CGFloat {
        return  topViewImageWindow.constant
//        if(topViewImageWindow.isActive){
//            return topViewImageWindow.constant
//        }else if(topViewImage.isActive){
//            return topViewImage.constant
//        }
//        return 0
    }
}

//extension GalleryDetailsViewController :UITableViewDelegate,  UIScrollViewDelegate{
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        debugPrint("velocity",scrollView.panGestureRecognizer.velocity(in: self.view))
//        let dragVelocity = scrollView.panGestureRecognizer.velocity(in: self.view)
//        if(dragVelocity.y >= 0){
//            self.shouldScroll = false
//            self.activeDrag = true
//        }
//    }
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        debugPrint("touchesBegan")
//    }
//}


class HitView:UIView{
    weak var mapView: MKMapView!
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return mapView.hitTest(point, with: event)
//        let hitView = super.hitTest(point, with: event)
//        debugPrint("hitView",hitView)
//        if hitView == self { return mapView }
//        return hitView

    }
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        // Only check the subviews that are visible and respond to touches
//        let candidates = subviews.filter {
//            (view: UIView) -> Bool in
//            return !view.isHidden && view.isUserInteractionEnabled && view.alpha >= 0.01
//        }
//        // Check from front to back
//        for view in candidates.reversed() {
//            // Convert to the subview's local coordinate system
//            let p = convert(point, toView:view)
//            if !view.point(inside: p, with: event) {
//                // Not inside the subview, keep looking
//                continue
//            }
//            // If the subview can find a hit target, return that
//            if let target = view.hitTest(p, with: event) {
//                return target
//            }
//        }
//        // No subview found a hit target if we reach this point
//        return nil
//    }
}
