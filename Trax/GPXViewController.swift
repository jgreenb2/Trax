//
//  ViewController.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/7/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
    }
    
    var gpxURL: NSURL? {
        didSet {
            if let url = gpxURL {
                clearWayPoints()
                GPX.parse(url) {
                    if let gpx = $0 {
                        self.handleWayPoints(gpx.waypoints)
                    }
                }
            }
        }
    }
    
    private func clearWayPoints() {
        if mapView?.annotations != nil {
            mapView.removeAnnotations(mapView.annotations as! [MKAnnotation])
        }
    }
    
    private func handleWayPoints(waypoints: [GPX.Waypoint]) {
        mapView.addAnnotations(waypoints)
        mapView.showAnnotations(waypoints, animated: true)
    }
    
    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "New Pin"
            mapView.addAnnotation(waypoint)
        }
    }
    
    struct Constants {
        static let AnnotationViewReuseIdentifier = "waypoints"
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let ShowImageSegue = "show image"
        static let EditWayPointSegue = "edit waypoint"
        static let EditWayPointPopoverWidth: CGFloat = 320
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.draggable = annotation is EditableWaypoint
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            
            if annotation is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            }
        }
        return view
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
                fetchImageForButton(waypoint.thumbnailURL!, destButton: thumbnailImageButton)
            }
        }
    }
    
    var imageURL: NSURL?
    
    func fetchImageForButton(url: NSURL, destButton: UIButton) {
        let qos = Int(QOS_CLASS_USER_INITIATED.value)
        imageURL = url
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        destButton.addSubview(spinner)
        spinner.startAnimating()

        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            if let imageData = NSData(contentsOfURL: url) {
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    spinner.stopAnimating()
                    spinner.removeFromSuperview()
                    if url == self.imageURL {
                        if let image = UIImage(data: imageData) {
                            destButton.setImage(image, forState: UIControlState.Normal)
                        } else {
                            destButton.setImage(nil, forState: UIControlState.Normal)
                        }
                    }
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if (control as? UIButton)?.buttonType == UIButtonType.DetailDisclosure {
            mapView.deselectAnnotation(view.annotation, animated: false)
            performSegueWithIdentifier(Constants.EditWayPointSegue, sender: view)
        } else if let waypoint = view.annotation as? GPX.Waypoint {
            if waypoint.imageURL != nil {
                performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
                if let ivc = segue.destinationViewController.contentViewController as? ImageViewController {
                    ivc.imageURL = waypoint.imageURL
                    ivc.title = waypoint.name
                }
            }
        } else if segue.identifier == Constants.EditWayPointSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? EditableWaypoint {
                if let ewvc = segue.destinationViewController.contentViewController as? EditWaypointViewController {
                    if let ppvc = ewvc.popoverPresentationController {
                        let coordinatePoint = mapView.convertCoordinate(waypoint.coordinate, toPointToView: mapView)
                        ppvc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForCoordinatePoint(coordinatePoint)
                        let minimumSize = ewvc.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                        ewvc.preferredContentSize.width = Constants.EditWayPointPopoverWidth
                        ewvc.preferredContentSize.height = minimumSize.height
                        ppvc.delegate = self
                    }
                    ewvc.waypointToEdit = waypoint
                }
            }
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.OverFullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navcon =  UINavigationController(rootViewController: controller.presentedViewController)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        visualEffectView.frame = navcon.view.bounds
        navcon.view.insertSubview(visualEffectView, atIndex: 0)
        return navcon
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        center.addObserverForName(GPXURL.Notification, object: appDelegate, queue: queue) { (notification) -> Void in
            if let url = notification?.userInfo?[GPXURL.Key] as? NSURL {
                self.gpxURL = url
            }
        }
        
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController
        } else {
            return self
        }
    }
}

extension MKAnnotationView {
    func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
        var popoverSourceRectCenter = coordinatePoint
        popoverSourceRectCenter.x -= frame.width/2 - centerOffset.x - calloutOffset.x
        popoverSourceRectCenter.y -= frame.height/2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectCenter, size: frame.size)
    }
}

