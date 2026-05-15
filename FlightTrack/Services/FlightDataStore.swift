import Foundation
import SwiftUI
import Observation

@Observable
final class FlightDataStore {

    // MARK: - State

    var trackedFlights: [Flight] = []

    // MARK: - Private

    private let userDefaultsKey = "FlightTrack.trackedFlights"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - Public API

    func addFlight(_ flight: Flight) {
        guard !trackedFlights.contains(where: { $0.id == flight.id }) else { return }
        trackedFlights.append(flight)
        save()
    }

    func removeFlight(_ flight: Flight) {
        trackedFlights.removeAll { $0.id == flight.id }
        save()
    }

    func removeFlight(at offsets: IndexSet) {
        trackedFlights.remove(atOffsets: offsets)
        save()
    }

    func updateFlight(_ flight: Flight) {
        if let index = trackedFlights.firstIndex(where: { $0.id == flight.id }) {
            trackedFlights[index] = flight
            save()
        }
    }

    func containsFlight(withNumber flightNumber: String) -> Bool {
        trackedFlights.contains { $0.flightNumber.uppercased() == flightNumber.uppercased() }
    }

    func clearAll() {
        trackedFlights.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try encoder.encode(trackedFlights)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("[FlightDataStore] Failed to save flights: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // First launch: seed with sample flights
            trackedFlights = SampleFlights.all
            return
        }
        do {
            trackedFlights = try decoder.decode([Flight].self, from: data)
        } catch {
            print("[FlightDataStore] Failed to load flights: \(error)")
            trackedFlights = SampleFlights.all
        }
    }
}
