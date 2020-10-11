//
//  ViewController2.swift
//  FloatingPanelTableView
//
//  Created by Ramesh R C on 31.03.20.
//  Copyright © 2020 Ramesh R C. All rights reserved.
//

import UIKit
import MapKit

class ViewController2: UIViewController {

    @IBOutlet weak var redView: PictureAreaView!
    @IBOutlet weak var hitView: HitView!
    @IBOutlet weak var segementView: RCSegmentView!{
        didSet{
            segementView.delegate = self
        }
    }
    @IBOutlet weak var viewWhiteAlpha: UIView!{
        didSet{
            viewWhiteAlpha.alpha = 0
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
extension ViewController2 : RCSegmentViewDelegate{
    func setController() -> [RCSegmentSlide] {
        guard let vc3 = storyboard?.instantiateViewController(withIdentifier: "ViewController3") as? ViewController3 else { return [] }
        let segmentSlide = RCSegmentSlide(buttonTitle: "Sample", vc: vc3)
        return [segmentSlide,segmentSlide]
    }
    
    func didDisplayViewController(vc: UIViewController, at index: Int) {
        //
    }
    
    func updateConfig() -> RCSegmentButtonConfig {
        var config = RCSegmentButtonConfig()
        config.selectorViewColor = UIColor.blue
        config.selectorTextColor = UIColor.white
        config.bottomViewColor = UIColor.clear
        return config
    }
    
    
}

class ViewController3: UIViewController {

    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.dataSource =  self
            tableView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.post(name: .FloatingTrackScrollView,object: self.tableView)
        // Do any additional setup after loading the view.
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
extension ViewController3 : UITableViewDelegate, UITableViewDataSource,UIScrollViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = "Aasdsfs fs asds"
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        debugPrint("scrollViewDidScroll")
    }
}


class PictureAreaView:UIView{
}
class HitView:UIView{
    weak var mapView: MKMapView!
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return mapView.hitTest(point, with: event)
    }
}
