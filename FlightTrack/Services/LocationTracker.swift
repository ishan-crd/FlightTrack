import Foundation
import CoreLocation
import Observation

@Observable
final class LocationTracker: NSObject {

    // MARK: - Observed properties (MainActor by default due to project settings)
    var currentLocation: CLLocation?
    var currentAltitude: Double = 0
    var currentSpeed: Double = 0
    var currentHeading: Double = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isTracking: Bool = false
    var estimatedArrivalDate: Date?
    var distanceToDestination: CLLocationDistance = 0

    private var locationManager: CLLocationManager?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var lastKnownLocation: CLLocation?

    // MARK: - Setup

    func requestPermission() {
        if locationManager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 100
            locationManager = manager
        }
        locationManager?.requestWhenInUseAuthorization()
    }

    func startTracking(destination: CLLocationCoordinate2D? = nil) {
        destinationCoordinate = destination
        isTracking = true
        if locationManager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 100
            locationManager = manager
        }
        locationManager?.startUpdatingLocation()
        locationManager?.startUpdatingHeading()
    }

    func stopTracking() {
        isTracking = false
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
    }

    func updateDestination(_ coordinate: CLLocationCoordinate2D) {
        destinationCoordinate = coordinate
        if let location = currentLocation ?? lastKnownLocation {
            recalculateETA(from: location)
        }
    }

    // MARK: - ETA Calculation

    private func recalculateETA(from location: CLLocation) {
        guard let dest = destinationCoordinate else { return }
        let destLocation = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
        let distance = location.distance(from: destLocation)
        distanceToDestination = distance

        // Use actual speed if available and reasonable, otherwise use typical cruise speed
        let speedMS: Double
        if location.speed > 50 { // > 50 m/s (~180 km/h) means we're airborne
            speedMS = location.speed
        } else if currentSpeed > 0 {
            speedMS = currentSpeed / 3.6 // convert km/h to m/s
        } else {
            speedMS = 250 // ~900 km/h typical cruise in m/s
        }

        guard speedMS > 0 else { return }
        let secondsRemaining = distance / speedMS
        estimatedArrivalDate = Date().addingTimeInterval(secondsRemaining)
    }

    // MARK: - Offline / Great-Circle ETA

    /// Calculate ETA offline using great-circle distance + known cruise speed
    static func offlineETA(
        from currentCoord: CLLocationCoordinate2D,
        to destinationCoord: CLLocationCoordinate2D,
        speedKmh: Double = 900
    ) -> Date {
        let current = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude)
        let destination = CLLocation(latitude: destinationCoord.latitude, longitude: destinationCoord.longitude)
        let distanceMeters = current.distance(from: destination)
        let speedMs = speedKmh / 3.6
        let seconds = distanceMeters / speedMs
        return Date().addingTimeInterval(seconds)
    }

    /// Calculate great-circle distance in km
    static func greatCircleDistanceKm(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLoc = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLoc.distance(from: toLoc) / 1000.0
    }

    /// Interpolate position along great-circle route
    static func interpolatedPosition(
        from departure: CLLocationCoordinate2D,
        to arrival: CLLocationCoordinate2D,
        progress: Double
    ) -> CLLocationCoordinate2D {
        let clamped = max(0, min(1, progress))
        let lat = departure.latitude + clamped * (arrival.latitude - departure.latitude)
        let lon = departure.longitude + clamped * (arrival.longitude - departure.longitude)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - CLLocationManagerDelegate (nonisolated to satisfy Swift 6 concurrency)

extension LocationTracker: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.lastKnownLocation = location
            self.currentAltitude = location.altitude
            if location.speed >= 0 {
                self.currentSpeed = location.speed * 3.6 // convert m/s to km/h
            }
            self.recalculateETA(from: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.currentHeading = heading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle — use last known location for offline ETA
    }
}
