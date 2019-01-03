//
//  NetworkReachabilityController.swift
//  GeofenceAreaDetector
//
//  Created by Roman Bobelyuk on 12/25/18.
//  Copyright © 2018 Roman Bobelyuk. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

public enum ReachabilityStatus {
    case unknown
    case reachableViaWiFi
    case unreachableViaWiFi
}

public protocol NetworkReachabilityDelegate: AnyObject {

    func networkReachabilityStatusChanged(status: ReachabilityStatus)
    
}

public class NetworkReachabilityController: NSObject {
    
    var reachabilityStatus : ReachabilityStatus
    weak var delegate : NetworkReachabilityDelegate?
    let reachability = Reachability()!
    override init() {
        reachabilityStatus = .unknown
    }
    
    deinit {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    func startObserving(){
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(notification:)), name: .reachabilityChanged, object: reachability)
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }
    }
    
    @objc func checkForReachability(notification: Notification){
        guard let reachability = notification.object as? Reachability else{
            return
        }
        
        if reachability.connection == .wifi {
            print("Reachable via WiFi")
            delegate?.networkReachabilityStatusChanged(status: .reachableViaWiFi)
        }else{
            delegate?.networkReachabilityStatusChanged(status: .unreachableViaWiFi)
            print("Not reachable or reachable via Cellular")
        }
    }
    
    class func getWiFiSsid() -> String? {
        #if targetEnvironment(simulator)
        // It's not possible to get wifi name on simulators
        return wifiNameForSimulator
        #endif
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
    
//    class func fetchSSIDInfo() -> String {
//        var currentSSID = ""
//        if let interfaces = CNCopySupportedInterfaces() {
//            for i in 0..<CFArrayGetCount(interfaces) {
//                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
//                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
//                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
//                if let interfaceData = unsafeInterfaceData as? [String: AnyObject] {
//                    currentSSID = interfaceData["SSID"] as! String
//                    let BSSID = interfaceData["BSSID"] as! String
//                    let SSIDDATA = interfaceData["SSIDDATA"] as! String
//                    debugPrint("ssid=\(currentSSID), BSSID=\(BSSID), SSIDDATA=\(SSIDDATA)")
//                }
//            }
//        }
//        return currentSSID
//    }
}
