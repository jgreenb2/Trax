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
    /**
        the url for the GPX file  
      
        Note: when a new url is set we clear the old waypoints
        and then add new ones based on the GPX data at the url
    */
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
    /**
        Removes waypoint annotations from the map
    */
    private func clearWayPoints() {
        if mapView?.annotations != nil {
            mapView.removeAnnotations(mapView.annotations as [MKAnnotation])
        }
    }
    /**
        adds and displays waypoint annotations on the map
        - Parameter waypoints: an array of GPX waypoints
    */
    private func handleWayPoints(waypoints: [GPX.Waypoint]) {
        mapView.addAnnotations(waypoints)
        mapView.showAnnotations(waypoints, animated: true)
    }
    /**
        drops a new pin representing a waypoint in response to
        a long-press on the map
        - Parameter sender: the gesture recognizer associated with this action
    */
    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "New Pin"
            mapView.addAnnotation(waypoint)
        }
    }
    
    // MARK: -- Constants
    /**
        a struct containing internal GPX constants
    */
    struct Constants {
        static let AnnotationViewReuseIdentifier = "waypoints"
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let ShowImageSegue = "show image"
        static let EditWayPointSegue = "edit waypoint"
        static let EditWayPointPopoverWidth: CGFloat = 320
    }
    
    // add an annotation view to the map
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // attempt to dequeue an existing view to use for the annotation
        var view:MKAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        
        if view == nil {
            // unlike table views, these aren't automatically created if there isn't a reusable one, so it's like Android:
            // we have to make a new view manually
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            // just reuse an existing view
            view.annotation = annotation
        }
        
        // we want to be able to move the pin
        view.draggable = annotation is EditableWaypoint
        
        // if a thumbnailURL exists we fetch and display its contents in the left callout of the annotation
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            
            // if this is an annotation we created display an info/edit button in the right callout
            if annotation is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure)
            }
        }
        return view
    }
    
    // called when annotation is selected
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let url = waypoint.thumbnailURL {
                if view.leftCalloutAccessoryView == nil {
                    // a thumbnail must have been added since the waypoint was created
                    view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
                }
                if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
                    fetchImageForButton(url, destButton: thumbnailImageButton)
                }
            }
        }
    }
    
    var imageURL: NSURL?
    /**
        fetches an image stored at a url and sets it as the image for a button
        - Parameter url: the url where the image is stored
        - Parameter destButton: the button where the image is to be displayed
        - Note: the image is fetched asynchronously and a spinner is shown in
            place of the button image until the data is available.
    */
    func fetchImageForButton(url: NSURL, destButton: UIButton) {
        let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
        imageURL = url
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        destButton.addSubview(spinner)
        spinner.center = destButton.center
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
    
    // show either the waypoint image or the edit waypoint screen depending on where the user tapped
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
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
                if let wivc = segue.destinationViewController.contentViewController as? WaypointImageViewController {
                    wivc.waypoint = waypoint
                } else if let ivc = segue.destinationViewController.contentViewController as? ImageViewController {
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
    
    // adapt from popover to full screen on iPhone (or any horizontally compact system)
    // do no adaptation (remain a popover) on a horizontally regular system
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return UIModalPresentationStyle.OverFullScreen
        } else {
            return UIModalPresentationStyle.None
        }
    }

    // when we adapt from Popover to OverFullScreen, we embed in a UINavigationController
    // so that it's possible to dismiss the controller if needed
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
        
        // set a url if a file is dropped onto the app
        center.addObserverForName(GPXURL.Notification, object: appDelegate, queue: queue) { (notification) -> Void in
            if let url = notification.userInfo?[GPXURL.Key] as? NSURL {
                self.gpxURL = url
            }
        }
        
        // gpxURL is a hardcoded test URL
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }
}


extension UIViewController {
    /**
        If the view controller is embedded in a UINavigationController
        return the visible controller in the Navcon. Otherwise just return
        self
        - Returns: the view controller
    */
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController!
        } else {
            return self
        }
    }
}

extension MKAnnotationView {
    /**
        Calculates an enclosing rectangle around an MKAnnotationView.
        Useful for anchoring a popover to an MKAnnotationView
        - Returns: the enclosing CGRect
    */
    func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
        var popoverSourceRectCenter = coordinatePoint
        popoverSourceRectCenter.x -= frame.width/2 - centerOffset.x - calloutOffset.x
        popoverSourceRectCenter.y -= frame.height/2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectCenter, size: frame.size)
    }
}

