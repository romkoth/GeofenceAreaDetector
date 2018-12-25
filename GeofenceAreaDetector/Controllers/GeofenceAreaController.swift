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

enum DeviceLocationStatus {
    case deviceLocationStatusUnknown
    case deviceLocationStatusInside
    case deviceLocationStatusOutside
}

public class GeofenceAreaController: NSObject, CLLocationManagerDelegate, NetworkReachabilityDelegate {
    
    var locationManager = CLLocationManager()
    var currentWiFiName = String()
    var currentRegion : CLRegion?
    var deviceLocationStatus : DeviceLocationStatus?
    var reachabilityController = NetworkReachabilityController()
    var delegate: GeofenceAreaControllerDelegate?

     init(geofenceArea: GeofenceArea) {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        reachabilityController.delegate = self
        deviceLocationStatus = .deviceLocationStatusUnknown
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
        currentWiFiName = geofenceArea.wifiName
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
        
        if deviceLocationStatus != .deviceLocationStatusInside && region is CLCircularRegion{
            deviceLocationStatus = .deviceLocationStatusInside
            currentRegion = region
            delegate?.geofenceAreaController(self, didEnterRegion: region)
        }
    }
    
    private func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if deviceLocationStatus != .deviceLocationStatusOutside && region is CLCircularRegion{
            print("Device did exit region, will check wifi reachability")
            if NetworkReachabilityController.getWiFiSsid() != currentWiFiName{
                print("Device is not connected to wifi named: ", currentWiFiName)
                deviceLocationStatus = .deviceLocationStatusOutside
                delegate?.geofenceAreaController(self, didExitRegion: region)
            }
        }
    }
    
    private func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
      
        if region is CLCircularRegion{
            
            currentRegion = region
            
            switch state {
            case .unknown:
                deviceLocationStatus = .deviceLocationStatusUnknown
            case .inside:
                deviceLocationStatus = .deviceLocationStatusInside
            case .outside:
                deviceLocationStatus = .deviceLocationStatusOutside
            }
        }
        
    }
    
    private func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        deviceLocationStatus = .deviceLocationStatusUnknown
        delegate?.geofenceAreaController(self, didReceiveError: error.localizedDescription)
    }
    
    public func networkReachabilityStatusChanged(status: ReachabilityStatus){
        
        switch status {
        case .reachableViaWiFi:
            
            if deviceLocationStatus != .deviceLocationStatusInside && NetworkReachabilityController.getWiFiSsid() == currentWiFiName{
                print("Device is connected to WiFi, we can assume that device status is inside and send last saved region")
                deviceLocationStatus = .deviceLocationStatusInside
                if let region = currentRegion {
                    delegate?.geofenceAreaController(self, didEnterRegion: region)
                }
            }
        case .unreachableViaWiFi:
            
            if deviceLocationStatus != .deviceLocationStatusOutside {
                print("Device is unreachable via WiFi we are trying to determine state")
                if let region = currentRegion {
                    locationManager.requestState(for: region)
                }
            }
        case .unknown:
            print("Something weird is going on")
        }
    }


}




