//
//  WaypointImageViewController.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/12/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class WaypointImageViewController: ImageViewController {

    var waypoint: GPX.Waypoint? {
        didSet {
            imageURL = waypoint?.imageURL
            title = waypoint?.name
            updateEmbeddedMap()
        }
    }
    
    var smvc: SimpleMapViewController?
    
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
