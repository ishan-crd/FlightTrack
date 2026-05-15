import Foundation
import Observation

@Observable
final class WatchFlightViewModel {

    // MARK: - Sub-services

    let flightService = WatchFlightService()
    let locationTracker = WatchLocationTracker()

    // MARK: - UI State

    var showAddFlight: Bool = false
    var selectedFlight: Flight? = nil
    var isRefreshing: Bool = false

    // MARK: - Derived

    var trackedFlights: [Flight] { flightService.trackedFlights }
    var searchResults: [Flight] { flightService.searchResults }
    var isSearching: Bool { flightService.isSearching }
    var searchError: String? { flightService.searchError }

    // MARK: - Search

    func search(query: String) {
        Task {
            await flightService.search(query: query)
        }
    }

    func clearSearch() {
        flightService.clearSearch()
    }

    // MARK: - Flight Management

    func addFlight(_ flight: Flight) {
        flightService.addFlight(flight)
        showAddFlight = false
    }

    func removeFlight(_ flight: Flight) {
        flightService.removeFlight(flight)
        if selectedFlight?.id == flight.id {
            selectedFlight = nil
        }
    }

    func removeFlight(at offsets: IndexSet) {
        flightService.removeFlight(at: offsets)
    }

    func isTracking(_ flight: Flight) -> Bool {
        flightService.isTracking(flight)
    }

    // MARK: - Refresh

    func refreshAll() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            await flightService.refreshAll()
            isRefreshing = false
        }
    }

    func refresh(flight: Flight) {
        Task {
            await flightService.refresh(flight: flight)
        }
    }

    // MARK: - Location

    func startLocationTracking() {
        locationTracker.requestAuthorization()
        locationTracker.startTracking()
    }

    func stopLocationTracking() {
        locationTracker.stopTracking()
    }

    /// Returns a GPS-assisted ETA for the given flight, or the stored ETA if location is unavailable.
    func offlineETA(for flight: Flight) -> Date? {
        guard flight.isActive else { return nil }
        return locationTracker.computeOfflineETA(for: flight)
    }

    // MARK: - Formatting Helpers

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formattedDuration(from: Date, to: Date) -> String {
        let interval = to.timeIntervalSince(from)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    func formattedAltitude(_ feet: Double) -> String {
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: Int(feet)), number: .decimal)
        return "\(formatted) ft"
    }

    func formattedSpeed(_ knots: Double) -> String {
        return "\(Int(knots)) kts"
    }

    func timeRemainingString(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "Arrived" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
