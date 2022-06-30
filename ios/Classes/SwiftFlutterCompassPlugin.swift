import CoreLocation
import CoreMotion
import Flutter
import simd
import UIKit

public class SwiftFlutterCompassPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
    private var eventSink: FlutterEventSink?
    private var location = CLLocationManager()
    private var motion = CMMotionManager()

    private var trueHeading: CLLocationDirection?
    private var headingAccuracy: CLLocationDirection?
    private var headingForCameraMode: CLLocationDirection?
    private var magneticHeading: CLLocationDirection?
    private var trueHeadingValue: String?
    private var trueHeadingText: String?
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    private var altitude: CLLocationDistance = 0
    
    private var latitudeCoordinateDirection: String?
    private var longitudeCoordinateDirection: String?
    
    private var latitudeDMS: String = ""
    private var longitudeDMS: String = ""
    
    init(channel: FlutterEventChannel) {
        super.init()
        location.delegate = self
        location.headingFilter = 1
        location.desiredAccuracy = kCLLocationAccuracyBest
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical)
        channel.setStreamHandler(self)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name: "soer/flutter_compass", binaryMessenger: registrar.messenger())
        _ = SwiftFlutterCompassPlugin(channel: channel)
    }

    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError?
    {
        self.eventSink = eventSink
        if CLLocationManager.headingAvailable() {
            location.startUpdatingHeading()
        }
        location.startUpdatingLocation()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        location.stopUpdatingHeading()
        location.stopUpdatingLocation()
        return nil
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return print("没有位置") }
        let coordinate = location.coordinate
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        
        altitude = location.altitude
        
        longitudeDMS = location.longitudeDMS
        latitudeDMS = location.latitudeDMS
        
        longitudeCoordinateDirection = location.longitudeCoordinateDirection
        latitudeCoordinateDirection = location.latitudeCoordinateDirection
        
        eventSink?(stream())
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
    private func stream() -> NSDictionary {
        var data: [String: Any] = [:]
        if let trueHeading = trueHeading {
            data["trueHeading"] = trueHeading
        }
        if let headingForCameraMode = headingForCameraMode {
            data["headingForCameraMode"] = headingForCameraMode
        }
        if let headingAccuracy = headingAccuracy {
            data["headingAccuracy"] = headingAccuracy
        }
        if let magneticHeading = magneticHeading {
            data["magneticHeading"] = magneticHeading
        }
        
        data["latitude"] = latitude
        data["longitude"] = longitude
        data["altitude"] = altitude
        data["longitudeDMS"] = longitudeDMS
        data["latitudeDMS"] = latitudeDMS
        
        if let latitudeCoordinateDirection = latitudeCoordinateDirection {
            data["latitudeCoordinateDirection"] = latitudeCoordinateDirection
        }
        if let longitudeCoordinateDirection = longitudeCoordinateDirection {
            data["longitudeCoordinateDirection"] = longitudeCoordinateDirection
        }
        if let trueHeadingText = trueHeadingText {
            data["trueHeadingText"] = trueHeadingText
        }
        if let trueHeadingValue = trueHeadingValue {
            data["trueHeadingValue"] = trueHeadingValue
        }
        return NSDictionary(dictionary: data)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy > 0, newHeading.trueHeading > 0 {
            var headingForCameraMode = newHeading.trueHeading
            // If device orientation data is available, use it to calculate the heading out the the
            // back of the device (rather than out the top of the device).
            if let data = motion.deviceMotion?.attitude {
                // Re-map the device orientation matrix such that the Z axis (out the back of the device)
                // always reads -90deg off magnetic north. All rotation matrices use + rotation to mean
                // counter-clockwise.
                let r1 = double3x3(rows: [
                    simd_double3(0, 0, 1),
                    simd_double3(0, 1, 0),
                    simd_double3(-1, 0, 0)
                ]) // -90 around the Y axis
                let r2 = double3x3(rows: [
                    simd_double3(0, -1, 0),
                    simd_double3(1, 0, 0),
                    simd_double3(0, 0, 1)
                ]) // -90 around the Z axis
                let R = double3x3(rows: [
                    simd_double3(data.rotationMatrix.m11, data.rotationMatrix.m12, data.rotationMatrix.m13),
                    simd_double3(data.rotationMatrix.m21, data.rotationMatrix.m22, data.rotationMatrix.m23),
                    simd_double3(data.rotationMatrix.m31, data.rotationMatrix.m32, data.rotationMatrix.m33)
                ])
                let T = r2 * r1 * R
                // Calculate yaw from R and add 90deg.
                let yaw = atan2(T[0, 1], T[1, 1]) + Double.pi / 2
                headingForCameraMode = (yaw + Double.pi * 2).truncatingRemainder(dividingBy: Double.pi * 2) * 180.0 / Double.pi
            }
            let cardinalValue = cardinalValue(from: newHeading.trueHeading)
            trueHeadingValue = cardinalValue.0
            trueHeadingText = cardinalValue.1
            trueHeading = newHeading.trueHeading
            self.headingForCameraMode = headingForCameraMode
            headingAccuracy = newHeading.headingAccuracy
            magneticHeading = newHeading.magneticHeading
            eventSink?(stream())
        }
    }

    private func cardinalValue(from heading: CLLocationDirection) -> (String, String) {
        switch heading {
        case 0 ..< 22.5:
            return ("N", "北")
        case 22.5 ..< 67.5:
            return ("NE", "东北")
        case 67.5 ..< 112.5:
            return ("E", "东")
        case 112.5 ..< 157.5:
            return ("SE", "东南")
        case 157.5 ..< 202.5:
            return ("S", "南")
        case 202.5 ..< 247.5:
            return ("SW", "西南")
        case 247.5 ..< 292.5:
            return ("W", "西")
        case 292.5 ..< 337.5:
            return ("NW", "西北")
        case 337.5 ... 360.0:
            return ("N", "北")
        default:
            return ("", "")
        }
    }
}

extension CLLocation {
    var dms: String { latitudeDMS + " " + longitudeDMS }
    var latitudeCoordinateDirection: String {
        let (degrees, _, _) = coordinate.latitude.dms
        return degrees >= 0 ? "N" : "S"
    }

    var longitudeCoordinateDirection: String {
        let (degrees, _, _) = coordinate.latitude.dms
        return degrees >= 0 ? "E" : "W"
    }

    var latitudeDMS: String {
        let (degrees, minutes, seconds) = coordinate.latitude.dms
        return String(format: "%d°%d'%d\"", abs(degrees), minutes, seconds)
    }

    var longitudeDMS: String {
        let (degrees, minutes, seconds) = coordinate.longitude.dms
        return String(format: "%d°%d'%d\"", abs(degrees), minutes, seconds)
    }
}
                       
extension BinaryFloatingPoint {
    var dms: (degrees: Int, minutes: Int, seconds: Int) {
        var seconds = Int(self * 3600)
        let degrees = seconds / 3600
        seconds = abs(seconds % 3600)
        return (degrees, seconds / 60, seconds % 60)
    }
}
