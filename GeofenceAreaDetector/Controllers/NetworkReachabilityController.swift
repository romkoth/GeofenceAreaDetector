//
//  NetworkReachabilityController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/25/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

public protocol NetworkReachabilityDelegate {
    
    //func networkReachability(didLostConnection: )
    
}

class NetworkReachabilityController {
    
    class func getWiFiSsid() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
}
