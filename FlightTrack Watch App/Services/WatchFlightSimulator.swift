import Foundation
import CoreLocation
import Observation

@Observable
final class WatchFlightSimulator {

    var isSimulating: Bool = false
    var currentCoordinate: CLLocationCoordinate2D?
    var progress: Double = 0
    var altitude: Double = 0
    var speed: Double = 0
    var heading: Double = 0
    var distanceRemaining: Double = 0
    var etaDate: Date?

    private var departure: CLLocationCoordinate2D = .init()
    private var arrival: CLLocationCoordinate2D = .init()
    private var totalDistanceMeters: Double = 0
    private var cruiseSpeedMs: Double = 250
    private var cruiseAltitudeMeters: Double = 11000
    private var simulationTask: Task<Void, Never>?
    private var startTime: Date?
    var speedMultiplier: Double = 120

    func startSimulation(flight: Flight) {
        stopSimulation()
        departure = flight.departure.coordinate
        arrival = flight.arrival.coordinate
        totalDistanceMeters = CLLocation(latitude: departure.latitude, longitude: departure.longitude)
            .distance(from: CLLocation(latitude: arrival.latitude, longitude: arrival.longitude))
        cruiseSpeedMs = (flight.speed ?? 900) / 3.6
        cruiseAltitudeMeters = flight.altitude ?? 11000
        heading = bearingBetween(from: departure, to: arrival)
        isSimulating = true
        progress = 0
        startTime = Date()
        simulationTask = Task { await runSimulation() }
    }

    func stopSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
        isSimulating = false
    }

    private func runSimulation() async {
        let tickInterval: TimeInterval = 1.0
        let totalFlightTimeSim = (totalDistanceMeters / cruiseSpeedMs) / speedMultiplier

        while !Task.isCancelled && progress < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
            guard !Task.isCancelled else { break }

            let elapsed = Date().timeIntervalSince(startTime ?? Date())
            progress = min(1.0, elapsed / totalFlightTimeSim)

            let coord = interpolateGreatCircle(from: departure, to: arrival, fraction: progress)
            currentCoordinate = coord

            // Altitude profile
            if progress < 0.10 {
                altitude = cruiseAltitudeMeters * (progress / 0.10)
            } else if progress < 0.85 {
                altitude = cruiseAltitudeMeters
            } else {
                altitude = cruiseAltitudeMeters * (1 - (progress - 0.85) / 0.15)
            }

            speed = cruiseSpeedMs * 3.6
            heading = bearingBetween(from: coord, to: arrival)

            let currentLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let arrivalLoc = CLLocation(latitude: arrival.latitude, longitude: arrival.longitude)
            distanceRemaining = currentLoc.distance(from: arrivalLoc)

            if cruiseSpeedMs > 0 {
                let secondsLeft = distanceRemaining / cruiseSpeedMs
                etaDate = Date().addingTimeInterval(secondsLeft / speedMultiplier)
            }
        }

        if !Task.isCancelled {
            progress = 1.0
            currentCoordinate = arrival
            distanceRemaining = 0
            altitude = 0
            speed = 0
        }
    }

    private func interpolateGreatCircle(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, fraction f: Double) -> CLLocationCoordinate2D {
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180
        let d = 2 * asin(sqrt(pow(sin((lat2 - lat1) / 2), 2) + cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2)))
        guard d > 0 else { return start }
        let a = sin((1 - f) * d) / sin(d)
        let b = sin(f * d) / sin(d)
        let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
        let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
        let z = a * sin(lat1) + b * sin(lat2)
        return CLLocationCoordinate2D(latitude: atan2(z, sqrt(x * x + y * y)) * 180 / .pi, longitude: atan2(y, x) * 180 / .pi)
    }

    private func bearingBetween(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
