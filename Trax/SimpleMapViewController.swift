//
//  SimpleMapViewController.swift
//  Trax
//
//  This class exists only to provide an accessible
//  outlet to an MKMapView. This reference will be inset into
//  the image display of an annotation as embed segue
//
//  see: WaypointImageViewController.swift
//
//  Created by Jeff Greenberg on 7/12/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import MapKit

class SimpleMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

}
