import Foundation

// MARK: - Known Airports

enum KnownAirports {
    static let JFK = Airport(iata: "JFK", name: "John F. Kennedy International Airport", city: "New York", latitude: 40.6413, longitude: -73.7781)
    static let LAX = Airport(iata: "LAX", name: "Los Angeles International Airport", city: "Los Angeles", latitude: 33.9425, longitude: -118.4081)
    static let LHR = Airport(iata: "LHR", name: "Heathrow Airport", city: "London", latitude: 51.4700, longitude: -0.4543)
    static let DXB = Airport(iata: "DXB", name: "Dubai International Airport", city: "Dubai", latitude: 25.2532, longitude: 55.3657)
    static let SIN = Airport(iata: "SIN", name: "Singapore Changi Airport", city: "Singapore", latitude: 1.3644, longitude: 103.9915)
    static let NRT = Airport(iata: "NRT", name: "Narita International Airport", city: "Tokyo", latitude: 35.7720, longitude: 140.3929)
    static let DEL = Airport(iata: "DEL", name: "Indira Gandhi International Airport", city: "New Delhi", latitude: 28.5562, longitude: 77.1000)
    static let BOM = Airport(iata: "BOM", name: "Chhatrapati Shivaji Maharaj International Airport", city: "Mumbai", latitude: 19.0896, longitude: 72.8656)
    static let CDG = Airport(iata: "CDG", name: "Charles de Gaulle Airport", city: "Paris", latitude: 49.0097, longitude: 2.5479)
    static let FRA = Airport(iata: "FRA", name: "Frankfurt Airport", city: "Frankfurt", latitude: 50.0379, longitude: 8.5622)
    static let SYD = Airport(iata: "SYD", name: "Sydney Airport", city: "Sydney", latitude: -33.9399, longitude: 151.1753)
    static let ORD = Airport(iata: "ORD", name: "O'Hare International Airport", city: "Chicago", latitude: 41.9742, longitude: -87.9073)
}

// MARK: - Sample Flights

enum SampleFlights {
    static var all: [Flight] {
        let now = Date()

        // Flight 1: In-flight (EK215 DXB -> JFK, 60% done)
        let ek215Dep = now.addingTimeInterval(-7 * 3600)
        let ek215Arr = now.addingTimeInterval(5 * 3600)
        // Interpolate position: 60% between DXB and JFK
        let ek215Lat = KnownAirports.DXB.latitude + 0.60 * (KnownAirports.JFK.latitude - KnownAirports.DXB.latitude)
        let ek215Lon = KnownAirports.DXB.longitude + 0.60 * (KnownAirports.JFK.longitude - KnownAirports.DXB.longitude)
        let ek215 = Flight(
            flightNumber: "EK215",
            airline: "Emirates",
            airlineLogo: "emirates",
            departure: KnownAirports.DXB,
            arrival: KnownAirports.JFK,
            scheduledDeparture: ek215Dep,
            scheduledArrival: ek215Arr,
            actualDeparture: ek215Dep.addingTimeInterval(5 * 60),
            estimatedArrival: ek215Arr.addingTimeInterval(10 * 60),
            status: .inFlight,
            gate: "C14",
            terminal: "3",
            arrivalGate: "B22",
            arrivalTerminal: "4",
            aircraftType: "Boeing 777-300ER",
            currentLatitude: ek215Lat,
            currentLongitude: ek215Lon,
            altitude: 11278,
            speed: 905,
            heading: 325,
            progress: 0.60
        )

        // Flight 2: Scheduled (SQ321 SIN -> LHR, departs in 3 hours)
        let sq321Dep = now.addingTimeInterval(3 * 3600)
        let sq321Arr = now.addingTimeInterval(17 * 3600)
        let sq321 = Flight(
            flightNumber: "SQ321",
            airline: "Singapore Airlines",
            airlineLogo: "singapore_airlines",
            departure: KnownAirports.SIN,
            arrival: KnownAirports.LHR,
            scheduledDeparture: sq321Dep,
            scheduledArrival: sq321Arr,
            status: .scheduled,
            gate: "F32",
            terminal: "3",
            arrivalGate: "D14",
            arrivalTerminal: "2",
            aircraftType: "Airbus A350-900",
            progress: 0.0
        )

        // Flight 3: Landed (AA100 JFK -> LAX, landed 30 min ago)
        let aa100Dep = now.addingTimeInterval(-6.5 * 3600)
        let aa100Arr = now.addingTimeInterval(-0.5 * 3600)
        let aa100 = Flight(
            flightNumber: "AA100",
            airline: "American Airlines",
            airlineLogo: "american_airlines",
            departure: KnownAirports.JFK,
            arrival: KnownAirports.LAX,
            scheduledDeparture: aa100Dep,
            scheduledArrival: aa100Arr.addingTimeInterval(15 * 60),
            actualDeparture: aa100Dep.addingTimeInterval(12 * 60),
            actualArrival: aa100Arr,
            status: .arrived,
            gate: "B7",
            terminal: "8",
            arrivalGate: "42",
            arrivalTerminal: "4",
            baggageBelt: "Belt 6",
            aircraftType: "Boeing 737-800",
            currentLatitude: KnownAirports.LAX.latitude,
            currentLongitude: KnownAirports.LAX.longitude,
            progress: 1.0
        )

        // Flight 4: Delayed (AI101 DEL -> BOM, was scheduled 1 hour ago, now delayed 2 hours)
        let ai101OrigDep = now.addingTimeInterval(-1 * 3600)
        let ai101NewDep = now.addingTimeInterval(1 * 3600)
        let ai101Arr = now.addingTimeInterval(3.5 * 3600)
        let ai101 = Flight(
            flightNumber: "AI101",
            airline: "Air India",
            airlineLogo: "air_india",
            departure: KnownAirports.DEL,
            arrival: KnownAirports.BOM,
            scheduledDeparture: ai101OrigDep,
            scheduledArrival: ai101OrigDep.addingTimeInterval(2.5 * 3600),
            estimatedArrival: ai101Arr,
            status: .delayed,
            gate: "22",
            terminal: "3",
            arrivalGate: "16",
            arrivalTerminal: "2",
            aircraftType: "Airbus A320",
            progress: 0.0
        )
        _ = ai101NewDep // suppress unused warning

        return [ek215, sq321, aa100, ai101]
    }
}

// MARK: - Mock Flight Generator

struct MockFlightGenerator {

    private struct FlightTemplate {
        let airline: String
        let logo: String
        let departure: Airport
        let arrival: Airport
        let durationHours: Double
        let aircraftType: String
    }

    private static let templates: [String: FlightTemplate] = [
        "AA": FlightTemplate(airline: "American Airlines", logo: "american_airlines",
                             departure: KnownAirports.JFK, arrival: KnownAirports.LAX,
                             durationHours: 6.0, aircraftType: "Boeing 737-800"),
        "EK": FlightTemplate(airline: "Emirates", logo: "emirates",
                             departure: KnownAirports.DXB, arrival: KnownAirports.JFK,
                             durationHours: 13.5, aircraftType: "Boeing 777-300ER"),
        "SQ": FlightTemplate(airline: "Singapore Airlines", logo: "singapore_airlines",
                             departure: KnownAirports.SIN, arrival: KnownAirports.LHR,
                             durationHours: 13.0, aircraftType: "Airbus A350-900"),
        "BA": FlightTemplate(airline: "British Airways", logo: "british_airways",
                             departure: KnownAirports.LHR, arrival: KnownAirports.JFK,
                             durationHours: 7.5, aircraftType: "Boeing 787-9"),
        "AI": FlightTemplate(airline: "Air India", logo: "air_india",
                             departure: KnownAirports.DEL, arrival: KnownAirports.LHR,
                             durationHours: 9.0, aircraftType: "Airbus A320"),
        "6E": FlightTemplate(airline: "IndiGo", logo: "indigo",
                             departure: KnownAirports.DEL, arrival: KnownAirports.BOM,
                             durationHours: 2.5, aircraftType: "Airbus A320neo"),
        "NH": FlightTemplate(airline: "ANA", logo: "ana",
                             departure: KnownAirports.NRT, arrival: KnownAirports.LAX,
                             durationHours: 10.5, aircraftType: "Boeing 787-9"),
        "LH": FlightTemplate(airline: "Lufthansa", logo: "lufthansa",
                             departure: KnownAirports.FRA, arrival: KnownAirports.JFK,
                             durationHours: 9.0, aircraftType: "Airbus A340-600"),
        "QF": FlightTemplate(airline: "Qantas", logo: "qantas",
                             departure: KnownAirports.SYD, arrival: KnownAirports.LAX,
                             durationHours: 14.5, aircraftType: "Airbus A380"),
        "UA": FlightTemplate(airline: "United Airlines", logo: "united",
                             departure: KnownAirports.ORD, arrival: KnownAirports.LHR,
                             durationHours: 8.5, aircraftType: "Boeing 767-300ER"),
    ]

    private static let allAirports: [Airport] = [
        KnownAirports.JFK, KnownAirports.LAX, KnownAirports.LHR, KnownAirports.DXB,
        KnownAirports.SIN, KnownAirports.NRT, KnownAirports.DEL, KnownAirports.BOM,
        KnownAirports.CDG, KnownAirports.FRA, KnownAirports.SYD, KnownAirports.ORD
    ]

    static func generate(from flightNumber: String) -> Flight {
        let upper = flightNumber.uppercased().trimmingCharacters(in: .whitespaces)
        let now = Date()

        // Extract airline code (1-2 letters + optional digit prefix like "6E")
        let airlineCode = extractAirlineCode(from: upper)

        if let template = templates[airlineCode] {
            let depTime = now.addingTimeInterval(-Double.random(in: 0...(template.durationHours * 3600)))
            let arrTime = depTime.addingTimeInterval(template.durationHours * 3600)
            let elapsed = now.timeIntervalSince(depTime)
            let totalDuration = template.durationHours * 3600
            let rawProgress = elapsed / totalDuration

            let status: FlightStatus
            let progress: Double
            if rawProgress < 0 {
                status = .scheduled
                progress = 0
            } else if rawProgress >= 1 {
                status = .arrived
                progress = 1
            } else {
                status = .inFlight
                progress = rawProgress
            }

            let currentLat = template.departure.latitude + progress * (template.arrival.latitude - template.departure.latitude)
            let currentLon = template.departure.longitude + progress * (template.arrival.longitude - template.departure.longitude)

            return Flight(
                flightNumber: upper.isEmpty ? airlineCode + "100" : upper,
                airline: template.airline,
                airlineLogo: template.logo,
                departure: template.departure,
                arrival: template.arrival,
                scheduledDeparture: depTime,
                scheduledArrival: arrTime,
                actualDeparture: status != .scheduled ? depTime.addingTimeInterval(Double.random(in: -300...600)) : nil,
                status: status,
                gate: randomGate(),
                terminal: randomTerminal(),
                arrivalGate: randomGate(),
                arrivalTerminal: randomTerminal(),
                aircraftType: template.aircraftType,
                currentLatitude: status == .inFlight ? currentLat : nil,
                currentLongitude: status == .inFlight ? currentLon : nil,
                altitude: status == .inFlight ? Double.random(in: 9000...12500) : nil,
                speed: status == .inFlight ? Double.random(in: 820...950) : nil,
                heading: status == .inFlight ? Double.random(in: 0...360) : nil,
                progress: progress
            )
        } else {
            return generateRandom(flightNumber: upper.isEmpty ? "XX100" : upper)
        }
    }

    private static func extractAirlineCode(from flightNumber: String) -> String {
        // Handle codes like "6E2341" (starts with digit then letter)
        var code = ""
        var i = flightNumber.startIndex
        // Collect leading digits+letters that form the airline code
        // Standard: 2 alpha (AA, EK, SQ, BA) or 1 digit + 1 alpha (6E)
        while i < flightNumber.endIndex {
            let ch = flightNumber[i]
            if ch.isLetter || (code.isEmpty && ch.isNumber) {
                code.append(ch)
                i = flightNumber.index(after: i)
                // If we have 2 chars and next is a digit, stop
                if code.count >= 2, i < flightNumber.endIndex, flightNumber[i].isNumber {
                    break
                }
                if code.count >= 2 && code.allSatisfy({ $0.isLetter }) {
                    break
                }
            } else {
                break
            }
        }
        return code
    }

    private static func generateRandom(flightNumber: String) -> Flight {
        let now = Date()
        let airports = allAirports.shuffled()
        let dep = airports[0]
        let arr = airports[1]
        let durationHours = Double.random(in: 2...14)
        let depTime = now.addingTimeInterval(-durationHours * 3600 * Double.random(in: 0...1))
        let arrTime = depTime.addingTimeInterval(durationHours * 3600)
        let elapsed = now.timeIntervalSince(depTime)
        let progress = max(0, min(1, elapsed / (durationHours * 3600)))

        let status: FlightStatus = progress >= 1 ? .arrived : (progress > 0 ? .inFlight : .scheduled)
        let currentLat = dep.latitude + progress * (arr.latitude - dep.latitude)
        let currentLon = dep.longitude + progress * (arr.longitude - dep.longitude)

        return Flight(
            flightNumber: flightNumber,
            airline: "Unknown Airline",
            airlineLogo: "",
            departure: dep,
            arrival: arr,
            scheduledDeparture: depTime,
            scheduledArrival: arrTime,
            status: status,
            gate: randomGate(),
            terminal: randomTerminal(),
            aircraftType: "Boeing 737-800",
            currentLatitude: status == .inFlight ? currentLat : nil,
            currentLongitude: status == .inFlight ? currentLon : nil,
            altitude: status == .inFlight ? Double.random(in: 9000...12000) : nil,
            speed: status == .inFlight ? Double.random(in: 820...950) : nil,
            heading: status == .inFlight ? Double.random(in: 0...360) : nil,
            progress: progress
        )
    }

    private static func randomGate() -> String {
        let letters = ["A", "B", "C", "D", "E", "F", "G"]
        return (letters.randomElement() ?? "A") + "\(Int.random(in: 1...40))"
    }

    private static func randomTerminal() -> String {
        return "\(Int.random(in: 1...8))"
    }
}
