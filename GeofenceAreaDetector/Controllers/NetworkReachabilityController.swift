//
//  NetworkReachabilityController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/25/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import Reachability

public enum ReachabilityStatus {
    case unknown
    case reachableViaWiFi
    case unreachableViaWiFi
}

public protocol NetworkReachabilityDelegate {

    func networkReachabilityStatusChanged(status: ReachabilityStatus)
    
}

public class NetworkReachabilityController {
    
    var reachabilityStatus : ReachabilityStatus
    var delegate : NetworkReachabilityDelegate?
    let reachability = Reachability()!
    init() {
        self.reachabilityStatus = .unknown
        NotificationCenter.default.addObserver(self, selector:Selector(("checkForReachability:")), name: NSNotification.Name.reachabilityChanged, object: reachability)

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }
    }
    
    deinit {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
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
    
    func checkForReachability(notification: Notification){
        
        guard let reachability = notification.object as? Reachability else{
            return
        }
        
        if reachability.connection == .wifi {
            delegate?.networkReachabilityStatusChanged(status: .reachableViaWiFi)
            print("Reachable via WiFi")
        }else{
            delegate?.networkReachabilityStatusChanged(status: .unreachableViaWiFi)
            print("Not reachable or reachable via Cellular")
        }
    }
}
