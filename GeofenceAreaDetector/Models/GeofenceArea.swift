//
//  GeofenceArea.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/24/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import CoreLocation

class GeofenceArea: NSObject {
    
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var wifiName: String
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, wifiName: String, identifier:String) {
        self.coordinate = coordinate
        self.radius = radius
        self.wifiName = wifiName
        self.identifier = identifier
    }
}
