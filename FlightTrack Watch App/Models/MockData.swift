import Foundation

struct MockFlightGenerator {

    // MARK: - Known Airports

    static let airports: [String: Airport] = [
        "JFK": Airport(iata: "JFK", name: "John F. Kennedy International", city: "New York", latitude: 40.6413, longitude: -73.7781),
        "LAX": Airport(iata: "LAX", name: "Los Angeles International", city: "Los Angeles", latitude: 33.9425, longitude: -118.4081),
        "ORD": Airport(iata: "ORD", name: "O'Hare International", city: "Chicago", latitude: 41.9742, longitude: -87.9073),
        "ATL": Airport(iata: "ATL", name: "Hartsfield-Jackson Atlanta", city: "Atlanta", latitude: 33.6407, longitude: -84.4277),
        "DFW": Airport(iata: "DFW", name: "Dallas/Fort Worth International", city: "Dallas", latitude: 32.8998, longitude: -97.0403),
        "DEN": Airport(iata: "DEN", name: "Denver International", city: "Denver", latitude: 39.8561, longitude: -104.6737),
        "SFO": Airport(iata: "SFO", name: "San Francisco International", city: "San Francisco", latitude: 37.6213, longitude: -122.3790),
        "SEA": Airport(iata: "SEA", name: "Seattle-Tacoma International", city: "Seattle", latitude: 47.4502, longitude: -122.3088),
        "MIA": Airport(iata: "MIA", name: "Miami International", city: "Miami", latitude: 25.7959, longitude: -80.2870),
        "BOS": Airport(iata: "BOS", name: "Boston Logan International", city: "Boston", latitude: 42.3656, longitude: -71.0096),
        "LHR": Airport(iata: "LHR", name: "Heathrow Airport", city: "London", latitude: 51.4700, longitude: -0.4543),
        "CDG": Airport(iata: "CDG", name: "Charles de Gaulle Airport", city: "Paris", latitude: 49.0097, longitude: 2.5478),
        "FRA": Airport(iata: "FRA", name: "Frankfurt Airport", city: "Frankfurt", latitude: 50.0379, longitude: 8.5622),
        "AMS": Airport(iata: "AMS", name: "Amsterdam Airport Schiphol", city: "Amsterdam", latitude: 52.3105, longitude: 4.7683),
        "DXB": Airport(iata: "DXB", name: "Dubai International", city: "Dubai", latitude: 25.2532, longitude: 55.3657),
        "NRT": Airport(iata: "NRT", name: "Narita International", city: "Tokyo", latitude: 35.7647, longitude: 140.3864),
        "SYD": Airport(iata: "SYD", name: "Sydney Kingsford Smith", city: "Sydney", latitude: -33.9399, longitude: 151.1753),
        "SIN": Airport(iata: "SIN", name: "Singapore Changi", city: "Singapore", latitude: 1.3644, longitude: 103.9915),
        "HKG": Airport(iata: "HKG", name: "Hong Kong International", city: "Hong Kong", latitude: 22.3080, longitude: 113.9185),
        "YYZ": Airport(iata: "YYZ", name: "Toronto Pearson International", city: "Toronto", latitude: 43.6777, longitude: -79.6248),
        "BOM": Airport(iata: "BOM", name: "Chhatrapati Shivaji Maharaj", city: "Mumbai", latitude: 19.0896, longitude: 72.8656),
        "DEL": Airport(iata: "DEL", name: "Indira Gandhi International", city: "New Delhi", latitude: 28.5562, longitude: 77.1000),
    ]

    // MARK: - Flight Database

    static let flightDatabase: [String: (dep: String, arr: String, airline: String, duration: TimeInterval)] = [
        "AA100": ("JFK", "LAX", "American Airlines", 5.75 * 3600),
        "AA101": ("LAX", "JFK", "American Airlines", 5.25 * 3600),
        "AA200": ("JFK", "LHR", "American Airlines", 7.0 * 3600),
        "AA201": ("LHR", "JFK", "American Airlines", 8.0 * 3600),
        "UA500": ("SFO", "ORD", "United Airlines", 4.25 * 3600),
        "UA501": ("ORD", "SFO", "United Airlines", 4.5 * 3600),
        "UA900": ("IAD", "FRA", "United Airlines", 8.5 * 3600),
        "DL400": ("ATL", "LAX", "Delta Air Lines", 4.75 * 3600),
        "DL401": ("LAX", "ATL", "Delta Air Lines", 4.25 * 3600),
        "DL100": ("JFK", "CDG", "Delta Air Lines", 7.5 * 3600),
        "SW1234": ("DEN", "LAX", "Southwest Airlines", 2.5 * 3600),
        "SW5678": ("LAX", "DEN", "Southwest Airlines", 2.75 * 3600),
        "BA178": ("JFK", "LHR", "British Airways", 7.0 * 3600),
        "BA179": ("LHR", "JFK", "British Airways", 8.25 * 3600),
        "EK201": ("DXB", "JFK", "Emirates", 13.5 * 3600),
        "EK202": ("JFK", "DXB", "Emirates", 12.0 * 3600),
        "EK500": ("DXB", "LHR", "Emirates", 7.5 * 3600),
        "SQ25":  ("SIN", "JFK", "Singapore Airlines", 18.5 * 3600),
        "SQ26":  ("JFK", "SIN", "Singapore Airlines", 18.75 * 3600),
        "LH400": ("FRA", "JFK", "Lufthansa", 8.5 * 3600),
        "LH401": ("JFK", "FRA", "Lufthansa", 7.5 * 3600),
        "QF12":  ("SYD", "LAX", "Qantas", 14.0 * 3600),
        "QF11":  ("LAX", "SYD", "Qantas", 14.75 * 3600),
        "NH109": ("NRT", "JFK", "All Nippon Airways", 14.0 * 3600),
        "NH110": ("JFK", "NRT", "All Nippon Airways", 13.5 * 3600),
        "AI191": ("DEL", "JFK", "Air India", 15.5 * 3600),
        "AI192": ("JFK", "DEL", "Air India", 14.0 * 3600),
        "AI119": ("DEL", "BOM", "Air India", 2.0 * 3600),
        "6E301": ("DEL", "BOM", "IndiGo", 2.0 * 3600),
        "6E302": ("BOM", "DEL", "IndiGo", 2.0 * 3600),
    ]

    // MARK: - Status Distribution for Simulation

    private static let statusOptions: [(FlightStatus, Double)] = [
        (.scheduled, 0.25),
        (.boarding, 0.10),
        (.departed, 0.10),
        (.inFlight, 0.25),
        (.landed, 0.10),
        (.arrived, 0.10),
        (.delayed, 0.07),
        (.cancelled, 0.03),
    ]

    // MARK: - Generator

    static func generate(for query: String) -> [Flight] {
        let uppercased = query.uppercased().trimmingCharacters(in: .whitespaces)

        // Direct match
        if let data = flightDatabase[uppercased] {
            return [makeFlight(number: uppercased, depCode: data.dep, arrCode: data.arr, airline: data.airline, duration: data.duration)]
        }

        // Prefix / partial match - return up to 5 results
        let matches = flightDatabase.filter { key, _ in
            key.hasPrefix(uppercased) || key.contains(uppercased)
        }
        if !matches.isEmpty {
            return matches.prefix(5).map { key, data in
                makeFlight(number: key, depCode: data.dep, arrCode: data.arr, airline: data.airline, duration: data.duration)
            }.sorted { $0.flightNumber < $1.flightNumber }
        }

        // Airline prefix match (e.g. "BA", "EK")
        let airlineMatches = flightDatabase.filter { key, _ in
            key.hasPrefix(uppercased.prefix(2))
        }
        if !airlineMatches.isEmpty {
            return airlineMatches.prefix(5).map { key, data in
                makeFlight(number: key, depCode: data.dep, arrCode: data.arr, airline: data.airline, duration: data.duration)
            }.sorted { $0.flightNumber < $1.flightNumber }
        }

        // Fallback: generate a plausible flight
        return [makeFallbackFlight(query: uppercased)]
    }

    // MARK: - Helpers

    private static func makeFlight(number: String, depCode: String, arrCode: String, airline: String, duration: TimeInterval) -> Flight {
        let dep = airports[depCode] ?? airports["JFK"]!
        let arr = airports[arrCode] ?? airports["LAX"]!

        let now = Date()
        let scheduledDep = Calendar.current.date(byAdding: .hour, value: Int.random(in: -6...6), to: now)!
        let scheduledArr = scheduledDep.addingTimeInterval(duration)

        let status = pickStatus(scheduledDep: scheduledDep, now: now)
        let progress = computeProgress(status: status, dep: scheduledDep, arr: scheduledArr, now: now)

        var actualDep: Date? = nil
        var estimatedArr: Date? = nil
        var currentLat: Double? = nil
        var currentLon: Double? = nil
        var altitude: Double? = nil
        var speed: Double? = nil
        var heading: Double? = nil
        var gate: String? = nil
        var terminal: String? = nil
        var arrivalGate: String? = nil
        var baggageBelt: String? = nil

        gate = ["A\(Int.random(in: 1...30))", "B\(Int.random(in: 1...20))", "C\(Int.random(in: 1...15))"].randomElement()!
        terminal = ["1", "2", "3", "4", "B", "C", "D"].randomElement()!

        if [.departed, .inFlight, .landed, .arrived].contains(status) {
            actualDep = scheduledDep.addingTimeInterval(Double.random(in: -300...1800))
        }

        if status == .delayed {
            let delay = Double.random(in: 1800...7200)
            estimatedArr = scheduledArr.addingTimeInterval(delay)
        }

        if status == .inFlight {
            let interpLat = dep.latitude + (arr.latitude - dep.latitude) * progress
            let interpLon = dep.longitude + (arr.longitude - dep.longitude) * progress
            currentLat = interpLat + Double.random(in: -0.5...0.5)
            currentLon = interpLon + Double.random(in: -0.5...0.5)
            altitude = Double.random(in: 33000...41000)
            speed = Double.random(in: 480...560)
            let dLat = arr.latitude - dep.latitude
            let dLon = arr.longitude - dep.longitude
            heading = (atan2(dLon, dLat) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        }

        if [.landed, .arrived].contains(status) {
            arrivalGate = ["D\(Int.random(in: 1...20))", "E\(Int.random(in: 1...15))", "F\(Int.random(in: 1...10))"].randomElement()!
            baggageBelt = "\(Int.random(in: 1...12))"
        }

        return Flight(
            flightNumber: number,
            airline: airline,
            airlineLogo: "",
            departure: dep,
            arrival: arr,
            scheduledDeparture: scheduledDep,
            scheduledArrival: scheduledArr,
            actualDeparture: actualDep,
            actualArrival: nil,
            estimatedArrival: estimatedArr,
            status: status,
            gate: gate,
            terminal: terminal,
            arrivalGate: arrivalGate,
            arrivalTerminal: nil,
            baggageBelt: baggageBelt,
            aircraftType: pickAircraftType(airline: airline),
            currentLatitude: currentLat,
            currentLongitude: currentLon,
            altitude: altitude,
            speed: speed,
            heading: heading,
            progress: progress
        )
    }

    private static func makeFallbackFlight(query: String) -> Flight {
        let dep = airports.values.randomElement()!
        var arr: Airport
        repeat { arr = airports.values.randomElement()! } while arr.iata == dep.iata

        let now = Date()
        let scheduledDep = Calendar.current.date(byAdding: .hour, value: Int.random(in: -3...3), to: now)!
        let scheduledArr = scheduledDep.addingTimeInterval(Double.random(in: 2 * 3600...14 * 3600))
        let status = pickStatus(scheduledDep: scheduledDep, now: now)
        let progress = computeProgress(status: status, dep: scheduledDep, arr: scheduledArr, now: now)

        return Flight(
            flightNumber: query.isEmpty ? "XX999" : query,
            airline: "FlightTrack Air",
            airlineLogo: "",
            departure: dep,
            arrival: arr,
            scheduledDeparture: scheduledDep,
            scheduledArrival: scheduledArr,
            status: status,
            gate: "A\(Int.random(in: 1...20))",
            terminal: "\(Int.random(in: 1...4))",
            aircraftType: "Boeing 737",
            progress: progress
        )
    }

    private static func pickStatus(scheduledDep: Date, now: Date) -> FlightStatus {
        let offset = now.timeIntervalSince(scheduledDep)
        if offset < -3600 { return .scheduled }
        if offset < -900 { return Bool.random() ? .scheduled : .delayed }
        if offset < 0 { return Bool.random() ? .boarding : .delayed }
        if offset < 600 { return .departed }
        if offset < 4 * 3600 { return .inFlight }
        return Bool.random() ? .landed : .arrived
    }

    private static func computeProgress(status: FlightStatus, dep: Date, arr: Date, now: Date) -> Double {
        switch status {
        case .scheduled, .boarding, .delayed: return 0
        case .departed: return Double.random(in: 0.01...0.05)
        case .inFlight:
            let total = arr.timeIntervalSince(dep)
            let elapsed = now.timeIntervalSince(dep)
            return max(0.05, min(0.95, elapsed / total))
        case .landed: return Double.random(in: 0.97...0.99)
        case .arrived: return 1.0
        case .cancelled, .diverted, .unknown: return 0
        }
    }

    private static func pickAircraftType(airline: String) -> String {
        let types = ["Boeing 737", "Boeing 777", "Boeing 787", "Airbus A320", "Airbus A330", "Airbus A350", "Airbus A380"]
        return types.randomElement()!
    }

    // MARK: - Sample Tracked Flights

    static var sampleFlights: [Flight] {
        [
            makeFlight(number: "AA100", depCode: "JFK", arrCode: "LAX", airline: "American Airlines", duration: 5.75 * 3600),
            makeFlight(number: "BA178", depCode: "JFK", arrCode: "LHR", airline: "British Airways", duration: 7.0 * 3600),
            makeFlight(number: "EK201", depCode: "DXB", arrCode: "JFK", airline: "Emirates", duration: 13.5 * 3600),
        ]
    }
}
