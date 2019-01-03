//
//  GeofenceAreaController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/24/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import CoreLocation

public protocol GeofenceAreaControllerDelegate: AnyObject {
    
    func geofenceAreaControllerDidExitRegion(_ controller: GeofenceAreaController)
    func geofenceAreaControllerDidEnterRegion(_ controller: GeofenceAreaController)
    func geofenceAreaController(_ controller: GeofenceAreaController, didFailedWithReason: String)

}

enum DeviceLocationStatus {
    case deviceLocationStatusUnknown
    case deviceLocationStatusInside
    case deviceLocationStatusOutside
}

public class GeofenceAreaController: NSObject, CLLocationManagerDelegate, NetworkReachabilityDelegate {
    
    var locationManager = CLLocationManager()
    var fakeLocationManager = CLLocationManager() // For testing purposes
    var currentWiFiName = String()
    var currentRegion : CLRegion?
    var deviceLocationStatus : DeviceLocationStatus?
    let reachabilityController = NetworkReachabilityController()
    weak var delegate: GeofenceAreaControllerDelegate?

    override init() {
        super.init()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = 2
        reachabilityController.delegate = self

        deviceLocationStatus = .deviceLocationStatusUnknown
    }
    
    func startMonitoring(geofenceArea: GeofenceArea) {
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            delegate?.geofenceAreaController(self, didFailedWithReason: "Geofencing is not supported on this device!")
            return
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            delegate?.geofenceAreaController(self, didFailedWithReason:"You should grant permission to access the device location")
        }
        reachabilityController.startObserving()
        
        let fenceRegion = region(with: geofenceArea)
        currentWiFiName = geofenceArea.wifiName
        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: fenceRegion)
    }
    
    func stopMonitoring(geofenceArea: GeofenceArea) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geofenceArea.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func getDeviceCoordianates() -> CLLocationCoordinate2D? {
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                return locationManager.location?.coordinate
        }
        return nil
    }
    
    // MARK: Monitoring changes from CLLocationManagerDelegate and NetworkReachabilityDelegate
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion){
        print("region: \(region) registered")
        currentRegion = region
        manager.requestState(for: region)
    }
    
    private func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if deviceLocationStatus != .deviceLocationStatusInside && region is CLCircularRegion{
            deviceLocationStatus = .deviceLocationStatusInside
            delegate?.geofenceAreaControllerDidEnterRegion(self)
        }
    }
    
    private func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if deviceLocationStatus != .deviceLocationStatusOutside && region is CLCircularRegion{
            print("Device did exit region, will check wifi reachability")
            if NetworkReachabilityController.getWiFiSsid() != currentWiFiName{
                print("Device is not connected to wifi named:\(currentWiFiName)")
                deviceLocationStatus = .deviceLocationStatusOutside
                delegate?.geofenceAreaControllerDidExitRegion(self)
            }
        }
    }
    
    private func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
      
        if region is CLCircularRegion {
            
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
        delegate?.geofenceAreaController(self, didFailedWithReason: error.localizedDescription)
    }
    
    public func networkReachabilityStatusChanged(status: ReachabilityStatus){
        
        switch status {
        case .reachableViaWiFi:
            
            if deviceLocationStatus != .deviceLocationStatusInside && NetworkReachabilityController.getWiFiSsid() == currentWiFiName{
                print("Device is connected to WiFi, we can assume that device status is inside area")
                deviceLocationStatus = .deviceLocationStatusInside
                delegate?.geofenceAreaControllerDidEnterRegion(self)
            }
        case .unreachableViaWiFi:
            
            if deviceLocationStatus != .deviceLocationStatusOutside {
                print("Device is unreachable via WiFi we are trying to determine state by location")
                if let region = currentRegion {
                    locationManager.requestState(for: region)
                }
            }
        case .unknown:
            print("Something weird is going on with determining wifi reachability")
        }
    }
    
    // MMARK: private helpers
    private func region(with geofenceArea: GeofenceArea) -> CLCircularRegion {
        let region = CLCircularRegion(center: geofenceArea.coordinate, radius: geofenceArea.radius, identifier: geofenceArea.identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}




