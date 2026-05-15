import Foundation
import SwiftUI
import Observation

@Observable
final class WatchFlightService {

    // MARK: - Published State

    var trackedFlights: [Flight] = []
    var searchResults: [Flight] = []
    var isSearching: Bool = false
    var searchError: String? = nil

    // MARK: - Persistence

    private let persistenceKey = "watch.tracked.flights"

    init() {
        loadFromDisk()
    }

    // MARK: - Search

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        searchError = nil

        // Simulate network latency
        try? await Task.sleep(nanoseconds: 600_000_000)

        let results = MockFlightGenerator.generate(for: trimmed)
        searchResults = results
        isSearching = false
    }

    func clearSearch() {
        searchResults = []
        searchError = nil
        isSearching = false
    }

    // MARK: - Tracking

    func addFlight(_ flight: Flight) {
        guard !trackedFlights.contains(where: { $0.id == flight.id || $0.flightNumber == flight.flightNumber }) else { return }
        trackedFlights.insert(flight, at: 0)
        saveToDisk()
    }

    func removeFlight(_ flight: Flight) {
        trackedFlights.removeAll { $0.id == flight.id }
        saveToDisk()
    }

    func removeFlight(at offsets: IndexSet) {
        trackedFlights.remove(atOffsets: offsets)
        saveToDisk()
    }

    func isTracking(_ flight: Flight) -> Bool {
        trackedFlights.contains { $0.id == flight.id || $0.flightNumber == flight.flightNumber }
    }

    // MARK: - Refresh

    func refreshAll() async {
        guard !trackedFlights.isEmpty else { return }

        var updated: [Flight] = []
        for flight in trackedFlights {
            // Re-generate with same flight number to simulate a refresh
            if let refreshed = MockFlightGenerator.generate(for: flight.flightNumber).first {
                updated.append(Flight(
                    id: flight.id,
                    flightNumber: refreshed.flightNumber,
                    airline: refreshed.airline,
                    airlineLogo: refreshed.airlineLogo,
                    departure: refreshed.departure,
                    arrival: refreshed.arrival,
                    scheduledDeparture: refreshed.scheduledDeparture,
                    scheduledArrival: refreshed.scheduledArrival,
                    actualDeparture: refreshed.actualDeparture,
                    actualArrival: refreshed.actualArrival,
                    estimatedArrival: refreshed.estimatedArrival,
                    status: refreshed.status,
                    gate: refreshed.gate,
                    terminal: refreshed.terminal,
                    arrivalGate: refreshed.arrivalGate,
                    arrivalTerminal: refreshed.arrivalTerminal,
                    baggageBelt: refreshed.baggageBelt,
                    aircraftType: refreshed.aircraftType,
                    currentLatitude: refreshed.currentLatitude,
                    currentLongitude: refreshed.currentLongitude,
                    altitude: refreshed.altitude,
                    speed: refreshed.speed,
                    heading: refreshed.heading,
                    progress: refreshed.progress
                ))
            } else {
                updated.append(flight)
            }
        }
        trackedFlights = updated
        saveToDisk()
    }

    func refresh(flight: Flight) async {
        guard let index = trackedFlights.firstIndex(where: { $0.id == flight.id }) else { return }
        if let refreshed = MockFlightGenerator.generate(for: flight.flightNumber).first {
            trackedFlights[index] = Flight(
                id: flight.id,
                flightNumber: refreshed.flightNumber,
                airline: refreshed.airline,
                airlineLogo: refreshed.airlineLogo,
                departure: refreshed.departure,
                arrival: refreshed.arrival,
                scheduledDeparture: refreshed.scheduledDeparture,
                scheduledArrival: refreshed.scheduledArrival,
                actualDeparture: refreshed.actualDeparture,
                actualArrival: refreshed.actualArrival,
                estimatedArrival: refreshed.estimatedArrival,
                status: refreshed.status,
                gate: refreshed.gate,
                terminal: refreshed.terminal,
                arrivalGate: refreshed.arrivalGate,
                arrivalTerminal: refreshed.arrivalTerminal,
                baggageBelt: refreshed.baggageBelt,
                aircraftType: refreshed.aircraftType,
                currentLatitude: refreshed.currentLatitude,
                currentLongitude: refreshed.currentLongitude,
                altitude: refreshed.altitude,
                speed: refreshed.speed,
                heading: refreshed.heading,
                progress: refreshed.progress
            )
            saveToDisk()
        }
    }

    // MARK: - Persistence

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(trackedFlights) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let flights = try? JSONDecoder().decode([Flight].self, from: data) else {
            return
        }
        trackedFlights = flights
    }
}
