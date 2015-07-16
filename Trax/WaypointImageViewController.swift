//
//  WaypointImageViewController.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/12/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class WaypointImageViewController: ImageViewController {
    /**
        When set, waypoint also sets an imageURL if one exists, a title based on the waypoint name
        and then updates the embedded map view
    
        - SeeAlso: `updateEmbeddedMap()`
    */
    var waypoint: GPX.Waypoint? {
        didSet {
            imageURL = waypoint?.imageURL
            title = waypoint?.name
            updateEmbeddedMap()
        }
    }
    
    var smvc: SimpleMapViewController?
    /**
        Configures the embedded mapView controller
    */
    func updateEmbeddedMap() {
        if let mapView = smvc?.mapView {
            mapView.mapType = .Hybrid
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(waypoint!)
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embed map" {
            smvc = segue.destinationViewController.contentViewController as? SimpleMapViewController
            updateEmbeddedMap()
        }
    }
}
