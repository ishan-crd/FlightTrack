import Foundation
import CoreLocation

enum FlightStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case boarding = "Boarding"
    case departed = "Departed"
    case inFlight = "In Flight"
    case landed = "Landed"
    case arrived = "Arrived"
    case delayed = "Delayed"
    case cancelled = "Cancelled"
    case diverted = "Diverted"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .scheduled: return "statusScheduled"
        case .boarding: return "statusBoarding"
        case .departed, .inFlight: return "statusInFlight"
        case .landed, .arrived: return "statusArrived"
        case .delayed: return "statusDelayed"
        case .cancelled: return "statusCancelled"
        case .diverted: return "statusDiverted"
        case .unknown: return "statusUnknown"
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .boarding: return "figure.walk"
        case .departed: return "airplane.departure"
        case .inFlight: return "airplane"
        case .landed: return "airplane.arrival"
        case .arrived: return "checkmark.circle.fill"
        case .delayed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .diverted: return "arrow.triangle.turn.up.right.diamond.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct Airport: Codable, Hashable {
    let iata: String
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Flight: Identifiable, Codable, Hashable {
    let id: UUID
    let flightNumber: String
    let airline: String
    let airlineLogo: String
    let departure: Airport
    let arrival: Airport
    let scheduledDeparture: Date
    let scheduledArrival: Date
    var actualDeparture: Date?
    var actualArrival: Date?
    var estimatedArrival: Date?
    var status: FlightStatus
    var gate: String?
    var terminal: String?
    var arrivalGate: String?
    var arrivalTerminal: String?
    var baggageBelt: String?
    var aircraftType: String?
    var currentLatitude: Double?
    var currentLongitude: Double?
    var altitude: Double?
    var speed: Double?
    var heading: Double?
    var progress: Double

    var currentCoordinate: CLLocationCoordinate2D? {
        guard let lat = currentLatitude, let lon = currentLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var isActive: Bool {
        [.boarding, .departed, .inFlight].contains(status)
    }

    var dynamicETA: Date? {
        estimatedArrival ?? scheduledArrival
    }

    var timeUntilDeparture: TimeInterval {
        scheduledDeparture.timeIntervalSinceNow
    }

    var formattedFlightNumber: String {
        flightNumber
    }

    var totalDistance: CLLocationDistance {
        let depLocation = CLLocation(latitude: departure.latitude, longitude: departure.longitude)
        let arrLocation = CLLocation(latitude: arrival.latitude, longitude: arrival.longitude)
        return depLocation.distance(from: arrLocation)
    }

    static func == (lhs: Flight, rhs: Flight) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(id: UUID = UUID(), flightNumber: String, airline: String, airlineLogo: String = "",
         departure: Airport, arrival: Airport, scheduledDeparture: Date, scheduledArrival: Date,
         actualDeparture: Date? = nil, actualArrival: Date? = nil, estimatedArrival: Date? = nil,
         status: FlightStatus = .scheduled, gate: String? = nil, terminal: String? = nil,
         arrivalGate: String? = nil, arrivalTerminal: String? = nil, baggageBelt: String? = nil,
         aircraftType: String? = nil, currentLatitude: Double? = nil, currentLongitude: Double? = nil,
         altitude: Double? = nil, speed: Double? = nil, heading: Double? = nil, progress: Double = 0) {
        self.id = id
        self.flightNumber = flightNumber
        self.airline = airline
        self.airlineLogo = airlineLogo
        self.departure = departure
        self.arrival = arrival
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.actualDeparture = actualDeparture
        self.actualArrival = actualArrival
        self.estimatedArrival = estimatedArrival
        self.status = status
        self.gate = gate
        self.terminal = terminal
        self.arrivalGate = arrivalGate
        self.arrivalTerminal = arrivalTerminal
        self.baggageBelt = baggageBelt
        self.aircraftType = aircraftType
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
        self.altitude = altitude
        self.speed = speed
        self.heading = heading
        self.progress = progress
    }
}
