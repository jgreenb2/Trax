//
//  ViewController.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/7/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate {

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
    
    struct Constants {
        static let AnnotationViewReuseIdentifier = "waypoints"
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let Segue = "show image"
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIImageView(frame: Constants.LeftCalloutFrame)
            }
            if waypoint.imageURL != nil {
                view.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            }
        }
        return view
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let thumbnailImageView = view.leftCalloutAccessoryView as? UIImageView {
                if let imageData = NSData(contentsOfURL: waypoint.thumbnailURL!) { // fix! by making async
                    if let image = UIImage(data: imageData) {
                        thumbnailImageView.image = image
                    }
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        performSegueWithIdentifier(Constants.Segue, sender: view)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
                if let ivc = segue.destinationViewController as? ImageViewController {
                    ivc.imageURL = waypoint.imageURL
                    ivc.title = waypoint.name
                }
            }
        }
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

