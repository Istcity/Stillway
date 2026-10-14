import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    var authStatus: CLAuthorizationStatus
    var authorization: CLAuthorizationStatus { authStatus }
    var currentLocation: CLLocation?
    var lastVisit: CLVisit?
    var lastError: String?

    var onVisit: ((CLVisit) -> Void)?
    var onRegionEnter: ((String) -> Void)?
    var onRegionExit: ((String) -> Void)?
    var onSignificantChange: ((CLLocation) -> Void)?

    private let manager = CLLocationManager()

    private override init() {
        authStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 500
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        requestAlwaysAuthorization()
    }

    func startAllServices() {
        manager.startMonitoringVisits()
        manager.startMonitoringSignificantLocationChanges()
    }

    func start() { startAllServices() }

    func stopAllServices() {
        manager.stopMonitoringVisits()
        manager.stopMonitoringSignificantLocationChanges()
    }

    func stop() { stopAllServices() }

    func startMonitoring(region: CLCircularRegion) {
        manager.startMonitoring(for: region)
    }

    func stopMonitoring(region: CLCircularRegion) {
        manager.stopMonitoring(for: region)
    }

    func stopAllGeofences() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            startAllServices()
        }
        // Persist upgrade path: when-in-use → ask Always once system allows.
        if authStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onSignificantChange?(location)
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        lastVisit = visit
        onVisit?(visit)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        onRegionEnter?(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        onRegionExit?(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
