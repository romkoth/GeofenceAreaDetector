//
//  GeofenceAreaController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/24/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import CoreLocation

public protocol GeofenceAreaControllerDelegate {
    
    func geofenceAreaController(_ controller: GeofenceAreaController, didExitRegion: CLRegion)
    func geofenceAreaController(_ controller: GeofenceAreaController, didEnterRegion: CLRegion)
    func geofenceAreaController(_ controller: GeofenceAreaController, didReceiveError: String)

}

public class GeofenceAreaController: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var currentwifiName = String()
    var delegate: GeofenceAreaControllerDelegate?

     init(geofenceArea: GeofenceArea) {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        startMonitoring(geofenceArea: geofenceArea)
    }
    
    private func startMonitoring(geofenceArea: GeofenceArea) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            delegate?.geofenceAreaController(self, didReceiveError: "Geofencing is not supported on this device!")
            return
        }

        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            delegate?.geofenceAreaController(self, didReceiveError:"You should grant permission to access the device location")
        }

        let fenceRegion = region(with: geofenceArea)
        currentwifiName = geofenceArea.wifiName
        locationManager.startMonitoring(for: fenceRegion)
    }
    
   private func region(with geofenceArea: GeofenceArea) -> CLCircularRegion {
        let region = CLCircularRegion(center: geofenceArea.coordinate, radius: geofenceArea.radius, identifier: geofenceArea.identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    
   private func stopMonitoring(geofenceArea: GeofenceArea) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geofenceArea.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    
    // MARK: monitoring changes
   private func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            delegate?.geofenceAreaController(self, didEnterRegion: region)
        }
    }
    
   private func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            if NetworkReachabilityController.getWiFiSsid() != currentwifiName{
                delegate?.geofenceAreaController(self, didExitRegion: region)
            }
        }
    }
    
   private func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.geofenceAreaController(self, didReceiveError: error.localizedDescription)
    }

}




