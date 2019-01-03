# GeofenceAreaDetector
Simple app that allow you to track geofence of your device depends on wifi and navigation

Class `GeofenceAreaController` analyze delegate callbacks from `CLLocationManager` and `NetworkReachabilityController` to notify by delegate device location status.

To get information about device location you can subscribe your class for `GeofenceAreaControllerDelegate` and after call 
`geofenceAreaController.startMonitoring(geofenceArea: geofenceAreaModel)`

Model `GeofenceArea` holds coordinates, radius and wifi name

