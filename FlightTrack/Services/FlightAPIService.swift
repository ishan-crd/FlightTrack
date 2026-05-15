import Foundation

// MARK: - Errors

enum FlightAPIError: LocalizedError {
    case notFound
    case networkError(Error)
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .notFound: return "Flight not found."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse: return "Invalid response from server."
        case .rateLimited: return "Too many requests. Please try again later."
        }
    }
}

// MARK: - Protocol

protocol FlightAPIServiceProtocol: Sendable {
    func searchFlight(query: String) async throws -> [Flight]
    func getFlightStatus(flightNumber: String) async throws -> Flight?
    func lookupPNR(pnr: String) async throws -> [Flight]
}

// MARK: - Mock Implementation

final class MockFlightAPIService: FlightAPIServiceProtocol {

    func searchFlight(query: String) async throws -> [Flight] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        // Check if query matches any sample flight number
        let sampleFlights = SampleFlights.all
        let matchedSamples = sampleFlights.filter {
            $0.flightNumber.lowercased().contains(trimmed.lowercased())
        }
        if !matchedSamples.isEmpty {
            return matchedSamples
        }

        // Generate a mock flight from the query
        let generated = MockFlightGenerator.generate(from: trimmed)
        return [generated]
    }

    func getFlightStatus(flightNumber: String) async throws -> Flight? {
        try await Task.sleep(nanoseconds: 600_000_000)

        let trimmed = flightNumber.trimmingCharacters(in: .whitespaces).uppercased()
        guard !trimmed.isEmpty else { return nil }

        // Check sample flights first
        if let match = SampleFlights.all.first(where: { $0.flightNumber.uppercased() == trimmed }) {
            return match
        }

        return MockFlightGenerator.generate(from: trimmed)
    }

    func lookupPNR(pnr: String) async throws -> [Flight] {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let trimmed = pnr.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count >= 5 else {
            throw FlightAPIError.notFound
        }

        // Generate 1-2 flights for the PNR (simulate multi-segment booking)
        let flight1 = MockFlightGenerator.generate(from: "EK" + String(trimmed.prefix(3)))
        var flight2 = MockFlightGenerator.generate(from: "EK" + String(trimmed.suffix(3)))

        // Make flight2 depart after flight1 arrives
        if flight1.scheduledArrival > flight2.scheduledDeparture {
            let offset = flight1.scheduledArrival.timeIntervalSince(flight2.scheduledDeparture) + 3600
            flight2 = Flight(
                id: flight2.id,
                flightNumber: flight2.flightNumber,
                airline: flight2.airline,
                airlineLogo: flight2.airlineLogo,
                departure: flight2.departure,
                arrival: flight2.arrival,
                scheduledDeparture: flight2.scheduledDeparture.addingTimeInterval(offset),
                scheduledArrival: flight2.scheduledArrival.addingTimeInterval(offset),
                status: .scheduled,
                gate: flight2.gate,
                terminal: flight2.terminal,
                arrivalGate: flight2.arrivalGate,
                arrivalTerminal: flight2.arrivalTerminal,
                aircraftType: flight2.aircraftType,
                progress: 0
            )
        }

        return [flight1, flight2]
    }
}

// MARK: - Live AviationStack Implementation (stubbed for future use)

final class AviationStackAPIService: FlightAPIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.aviationstack.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func searchFlight(query: String) async throws -> [Flight] {
        let url = URL(string: "\(baseURL)/flights?access_key=\(apiKey)&flight_iata=\(query)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FlightAPIError.invalidResponse
        }
        return try parseFlightsFromAviationStack(data: data)
    }

    func getFlightStatus(flightNumber: String) async throws -> Flight? {
        let results = try await searchFlight(query: flightNumber)
        return results.first
    }

    func lookupPNR(pnr: String) async throws -> [Flight] {
        // AviationStack does not support PNR lookup; fall back to mock
        let mock = MockFlightAPIService()
        return try await mock.lookupPNR(pnr: pnr)
    }

    private func parseFlightsFromAviationStack(data: Data) throws -> [Flight] {
        // Full parsing would decode AviationStack JSON schema.
        // Stubbed — returns empty for now.
        return []
    }
}
