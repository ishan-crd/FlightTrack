import Foundation
import CoreLocation
import Observation

@Observable
final class WatchLocationTracker: NSObject {

    // MARK: - Observable State

    var currentLocation: CLLocation? = nil
    var currentAltitude: Double? = nil
    var currentSpeed: Double? = nil
    var isTracking: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private

    private let locationManager = CLLocationManager()

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .airborne
        locationManager.distanceFilter = 50
    }

    // MARK: - Control

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    // MARK: - ETA Computation

    /// Compute an offline ETA based on current GPS position and flight route.
    /// Returns nil if location or flight data is insufficient.
    func computeOfflineETA(for flight: Flight) -> Date? {
        guard let current = currentLocation else { return flight.estimatedArrival ?? flight.scheduledArrival }

        let arrivalLocation = CLLocation(
            latitude: flight.arrival.latitude,
            longitude: flight.arrival.longitude
        )

        let remainingDistanceMeters = current.distance(from: arrivalLocation)

        // Use reported GPS speed first, then flight's stored speed, then typical cruise (250 m/s)
        let speedMs: Double
        if let gpsSpeed = currentSpeed, gpsSpeed > 50 {
            speedMs = gpsSpeed
        } else if let flightSpeed = flight.speed, flightSpeed > 0 {
            // flight.speed is in knots; 1 knot = 0.514444 m/s
            speedMs = flightSpeed * 0.514444
        } else {
            speedMs = 250.0
        }

        guard speedMs > 0 else { return flight.estimatedArrival ?? flight.scheduledArrival }

        let secondsRemaining = remainingDistanceMeters / speedMs
        return Date().addingTimeInterval(secondsRemaining)
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchLocationTracker: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            currentAltitude = location.altitude > 0 ? location.altitude * 3.28084 : nil // convert to feet
            currentSpeed = location.speed > 0 ? location.speed : nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                if isTracking {
                    manager.startUpdatingLocation()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently fail on watch - GPS may not always be available
        Task { @MainActor in
            if isTracking {
                // Keep isTracking true - will resume when location available
            }
        }
    }
}
