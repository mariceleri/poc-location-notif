import UIKit
import Foundation
import Flutter
import CoreLocation
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    var places: [Place] = []
    let locationManager = CLLocationManager()
    let radius = 500.0
    
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      initPlatformSpecific()
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let notifChannel = FlutterMethodChannel(name: "sample.fd.notif", binaryMessenger: controller.binaryMessenger)
      
      notifChannel.setMethodCallHandler({
          [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          guard call.method == "setNotif" else {
              result(FlutterMethodNotImplemented)
              return
          }
          
          let jsonString = call.arguments as! String
          let data: NSData = jsonString.data(using: String.Encoding.utf8)! as NSData
          self?.places = try! JSONDecoder().decode([Place].self, from: data as Data)
      })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    func initPlatformSpecific() {
        locationManager.delegate = self
        requestPermission()
//        setCustomNotif()
    }
    
    func requestPermission() {
        requestLocationPermission()
        requestNotifPermission()
    }
    
    func requestNotifPermission() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted, error) in
                if granted {
                    print("yes")
                } else {
                    print("no")
                    return
                }
            }
        } else {}
    }
    
    func requestLocationPermission() {
        let bundle = Bundle.main
        // need to check if service is enabled too
        if (bundle.object(forInfoDictionaryKey:"NSLocationAlwaysUsageDescription") != nil) {
            
            locationManager.requestAlwaysAuthorization()
        } else if (bundle.object(forInfoDictionaryKey:"NSLocationWhenInUseUsageDescription") != nil) {
            locationManager.requestWhenInUseAuthorization()
        }
        
        if #available(iOS 14.0, *) {
            if (locationManager.authorizationStatus == .authorizedWhenInUse){
                locationManager.allowsBackgroundLocationUpdates = true
            }
        }
        
    }
    
    func setCustomNotif() {
        print("set notification here")
        if #available(iOS 10.0, *) {
            
            let content = UNMutableNotificationContent()
            content.title = "Hello from FD"
            content.subtitle = "You have places nearby"
            
            let request = UNNotificationRequest(identifier: "fd.id.03", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            // Fallback on earlier versions
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location changed status : \(status)")
        if(status == .authorizedWhenInUse || status == .authorizedAlways){
            manager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locations = \(locations.last?.coordinate.latitude ?? 0) \(locations.last?.coordinate.longitude ?? 0)")
        let latitude = locations.last?.coordinate.latitude ?? 0
        let longitude = locations.last?.coordinate.longitude ?? 0
        if hasNearbyPlaces(currentLat: latitude, currentLon: longitude) {
            setCustomNotif()
        }
    }
    
    func hasNearbyPlaces(currentLat: Double, currentLon: Double) -> Bool {
        var nearbyPlaces: [Place] = []
        for place in places {
            let distance = haversine(lat1: currentLat, lon1: currentLon, lat2: place.latitude, lon2: place.longitude)
            if(distance < radius) {
                nearbyPlaces.append(place)
            }
        }
        // return to dart nearby places value
        return !nearbyPlaces.isEmpty
    }
    
    func haversine(lat1:Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let lat1rad = lat1 * Double.pi/180
        let lon1rad = lon1 * Double.pi/180
        let lat2rad = lat2 * Double.pi/180
        let lon2rad = lon2 * Double.pi/180
        
        let dLat = lat2rad - lat1rad
        let dLon = lon2rad - lon1rad
        let a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1rad) * cos(lat2rad)
        let c = 2 * asin(sqrt(a))
        let R = 6372.8
        
        return R * c
    }
}
