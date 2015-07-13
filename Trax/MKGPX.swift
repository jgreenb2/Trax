//
//  MKGPX.swift
//  Trax
//
//  Created by Jeff Greenberg on 7/8/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import MapKit

class EditableWaypoint: GPX.Waypoint {
    override var coordinate: CLLocationCoordinate2D {
        get { return super.coordinate }
        set {
            longitude = newValue.longitude
            latitude = newValue.latitude
        }
    }
    override var thumbnailURL: NSURL? { return imageURL }
    override var imageURL: NSURL? { return links.first?.url }

}

extension GPX.Waypoint: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    var title: String? {return name}
    var subtitle: String? {return info}

    var  thumbnailURL: NSURL? { return getImageURLofType("thumbnail") }
    var imageURL: NSURL? { return getImageURLofType("large") }
        
    private func getImageURLofType(type: String) -> NSURL? {
        for link in links {
            if link.type == type {
                return link.url
            }
        }
        return nil
    }
}
