import Foundation
import CoreLocation
import Observation

@Observable
final class FlightSimulator {

    // MARK: - State

    var isSimulating: Bool = false
    var currentLocation: CLLocation?
    var progress: Double = 0
    var altitude: Double = 0
    var speed: Double = 0
    var heading: Double = 0
    var distanceRemaining: Double = 0
    var etaDate: Date?
    var elapsedTime: TimeInterval = 0

    // MARK: - Config

    private var departure: CLLocationCoordinate2D = .init()
    private var arrival: CLLocationCoordinate2D = .init()
    private var totalDistanceMeters: Double = 0
    private var cruiseSpeedMs: Double = 250 // ~900 km/h
    private var cruiseAltitudeMeters: Double = 11000
    private var simulationTask: Task<Void, Never>?
    private var startTime: Date?

    // Simulation speed multiplier (1x = real-time, 60x = 1 min = 1 sec)
    var speedMultiplier: Double = 120

    // MARK: - Start / Stop

    func startSimulation(flight: Flight) {
        stopSimulation()

        departure = flight.departure.coordinate
        arrival = flight.arrival.coordinate
        totalDistanceMeters = CLLocation(latitude: departure.latitude, longitude: departure.longitude)
            .distance(from: CLLocation(latitude: arrival.latitude, longitude: arrival.longitude))
        cruiseSpeedMs = (flight.speed ?? 900) / 3.6 // km/h to m/s
        cruiseAltitudeMeters = flight.altitude ?? 11000

        // Compute heading from departure to arrival
        heading = Self.bearingBetween(from: departure, to: arrival)

        isSimulating = true
        progress = 0
        startTime = Date()
        elapsedTime = 0

        simulationTask = Task {
            await runSimulation()
        }
    }

    func stopSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
        isSimulating = false
    }

    // MARK: - Simulation Loop

    private func runSimulation() async {
        let tickInterval: TimeInterval = 0.5 // update every 0.5s
        let totalFlightTimeReal = totalDistanceMeters / cruiseSpeedMs // real seconds for the flight
        let totalFlightTimeSim = totalFlightTimeReal / speedMultiplier // compressed

        while !Task.isCancelled && progress < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64(tickInterval * 1_000_000_000))
            guard !Task.isCancelled else { break }

            let now = Date()
            elapsedTime = now.timeIntervalSince(startTime ?? now)
            progress = min(1.0, elapsedTime / totalFlightTimeSim)

            // Interpolate position along great-circle
            let currentCoord = Self.interpolateGreatCircle(from: departure, to: arrival, fraction: progress)

            // Simulate realistic altitude profile (climb, cruise, descend)
            altitude = simulatedAltitude(at: progress)

            // Simulate speed (slower during climb/descend)
            speed = simulatedSpeed(at: progress) * 3.6 // m/s to km/h

            // Update heading based on current position to destination
            heading = Self.bearingBetween(from: currentCoord, to: arrival)

            // Distance remaining
            let currentLoc = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude)
            let arrivalLoc = CLLocation(latitude: arrival.latitude, longitude: arrival.longitude)
            distanceRemaining = currentLoc.distance(from: arrivalLoc)

            // ETA based on remaining distance and current speed
            let currentSpeedMs = simulatedSpeed(at: progress)
            if currentSpeedMs > 0 {
                let secondsLeft = distanceRemaining / currentSpeedMs
                etaDate = Date().addingTimeInterval(secondsLeft / speedMultiplier)
            }

            // Build a CLLocation with all the data
            currentLocation = CLLocation(
                coordinate: currentCoord,
                altitude: altitude,
                horizontalAccuracy: 10,
                verticalAccuracy: 10,
                course: heading,
                speed: simulatedSpeed(at: progress),
                timestamp: now
            )
        }

        if !Task.isCancelled {
            // Flight complete
            progress = 1.0
            currentLocation = CLLocation(latitude: arrival.latitude, longitude: arrival.longitude)
            distanceRemaining = 0
            altitude = 0
            speed = 0
        }
    }

    // MARK: - Altitude Profile

    private func simulatedAltitude(at progress: Double) -> Double {
        // Climb: 0-10%, Cruise: 10-85%, Descend: 85-100%
        if progress < 0.10 {
            // Climbing
            let climbProgress = progress / 0.10
            return cruiseAltitudeMeters * easeInOut(climbProgress)
        } else if progress < 0.85 {
            // Cruise with slight variation
            let variation = sin(progress * 20) * 100
            return cruiseAltitudeMeters + variation
        } else {
            // Descending
            let descendProgress = (progress - 0.85) / 0.15
            return cruiseAltitudeMeters * (1 - easeInOut(descendProgress))
        }
    }

    private func simulatedSpeed(at progress: Double) -> Double {
        // Slower during climb/descend, full speed during cruise
        if progress < 0.08 {
            let t = progress / 0.08
            return cruiseSpeedMs * (0.3 + 0.7 * easeInOut(t))
        } else if progress < 0.88 {
            return cruiseSpeedMs
        } else {
            let t = (progress - 0.88) / 0.12
            return cruiseSpeedMs * (1.0 - 0.6 * easeInOut(t))
        }
    }

    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    // MARK: - Great Circle Interpolation

    static func interpolateGreatCircle(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        fraction f: Double
    ) -> CLLocationCoordinate2D {
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180

        let d = 2 * asin(sqrt(
            pow(sin((lat2 - lat1) / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2)
        ))

        guard d > 0 else { return start }

        let a = sin((1 - f) * d) / sin(d)
        let b = sin(f * d) / sin(d)

        let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
        let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
        let z = a * sin(lat1) + b * sin(lat2)

        let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
        let lon = atan2(y, x) * 180 / .pi

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    static func bearingBetween(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    static func greatCirclePoints(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        steps: Int = 80
    ) -> [CLLocationCoordinate2D] {
        (0...steps).map { i in
            interpolateGreatCircle(from: start, to: end, fraction: Double(i) / Double(steps))
        }
    }
}
