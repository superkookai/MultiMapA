//
//  Location.swift
//  MultiMapA
//
//  Created by Weerawut on 1/1/2569 BE.
//

import MapKit

struct Location: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let country: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension Location {
    //Define own hash value (Swift does include all properties to be hashed
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
