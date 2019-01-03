//
//  ViewController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/24/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import UIKit
import CoreLocation

let wifiNameForSimulator = "simulatorWiFiName" // For testing purposes

class ViewController: UIViewController, GeofenceAreaControllerDelegate {
   
    let radius: CLLocationDistance = CLLocationDistance(10.0)
    let identifier = NSUUID().uuidString
    let geofenceAreaController = GeofenceAreaController()

    @IBOutlet weak var bottomLabel: UILabel!
    @IBAction func setLocationAction(_ sender: UIButton) {
        
        if let coordinates = geofenceAreaController.getDeviceCoordianates(){
            let geofenceArea = GeofenceArea(coordinate:coordinates, radius: radius, wifiName: wifiNameForSimulator, identifier: identifier)
            geofenceAreaController.startMonitoring(geofenceArea: geofenceArea)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        geofenceAreaController.delegate = self
    }

    //MARK: GeofenceAreaControllerDelegate
    func geofenceAreaControllerDidExitRegion(_ controller: GeofenceAreaController){
        self.view.backgroundColor = .red
        self.bottomLabel.text = "Device is outside the area"
    }
    
    func geofenceAreaControllerDidEnterRegion(_ controller: GeofenceAreaController){
        self.view.backgroundColor = .green
        self.bottomLabel.text = "Device is in the area"
    }
    
    func geofenceAreaController(_ controller: GeofenceAreaController, didFailedWithReason: String){
        self.bottomLabel.text = didFailedWithReason
    }
}

