import Foundation
import Observation
import CoreLocation

@Observable
final class FlightViewModel {

    // MARK: - State

    var trackedFlights: [Flight] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var searchResults: [Flight] = []
    var isSearching: Bool = false
    var searchQuery: String = ""
    var selectedFlight: Flight?
    var showAddFlight: Bool = false
    var lastRefreshed: Date?

    // MARK: - Dependencies

    private let dataStore: FlightDataStore
    private let apiService: any FlightAPIServiceProtocol
    let locationTracker: LocationTracker

    // MARK: - Timers

    private var refreshTask: Task<Void, Never>?

    // MARK: - Init

    init(
        dataStore: FlightDataStore = FlightDataStore(),
        apiService: any FlightAPIServiceProtocol = MockFlightAPIService(),
        locationTracker: LocationTracker = LocationTracker()
    ) {
        self.dataStore = dataStore
        self.apiService = apiService
        self.locationTracker = locationTracker
        self.trackedFlights = sortedFlights(dataStore.trackedFlights)
        startPeriodicRefresh()
    }

    // MARK: - Sorted Flights

    /// Active first, then upcoming (sorted by departure), then past (sorted by arrival desc)
    private func sortedFlights(_ flights: [Flight]) -> [Flight] {
        let now = Date()
        let active = flights.filter { $0.isActive }.sorted { $0.scheduledDeparture < $1.scheduledDeparture }
        let upcoming = flights.filter { !$0.isActive && $0.scheduledDeparture > now }
            .sorted { $0.scheduledDeparture < $1.scheduledDeparture }
        let past = flights.filter { !$0.isActive && $0.scheduledDeparture <= now && !$0.isActive }
            .sorted { $0.scheduledArrival > $1.scheduledArrival }
        return active + upcoming + past
    }

    // MARK: - Flight Management

    func addFlight(_ flight: Flight) {
        dataStore.addFlight(flight)
        syncFromStore()
        startLocationTrackingIfNeeded()
    }

    func removeFlight(_ flight: Flight) {
        dataStore.removeFlight(flight)
        syncFromStore()
    }

    func removeFlight(at offsets: IndexSet) {
        dataStore.removeFlight(at: offsets)
        syncFromStore()
    }

    func isTracked(_ flight: Flight) -> Bool {
        trackedFlights.contains(where: { $0.id == flight.id })
    }

    private func syncFromStore() {
        trackedFlights = sortedFlights(dataStore.trackedFlights)
    }

    // MARK: - Search

    func searchFlights(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let results = try await apiService.searchFlight(query: trimmed)
                searchResults = results
            } catch {
                errorMessage = error.localizedDescription
                searchResults = []
            }
            isSearching = false
        }
    }

    func lookupPNR(pnr: String) {
        let trimmed = pnr.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let results = try await apiService.lookupPNR(pnr: trimmed)
                searchResults = results
            } catch {
                errorMessage = error.localizedDescription
                searchResults = []
            }
            isSearching = false
        }
    }

    func clearSearch() {
        searchResults = []
        searchQuery = ""
        errorMessage = nil
    }

    // MARK: - Refresh

    func refreshAllFlights() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            var updated: [Flight] = []
            for flight in dataStore.trackedFlights {
                if let refreshed = try? await apiService.getFlightStatus(flightNumber: flight.flightNumber) {
                    // Preserve the local ID so the flight card doesn't flicker
                    let merged = Flight(
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
                    updated.append(merged)
                    dataStore.updateFlight(merged)
                } else {
                    updated.append(flight)
                }
            }
            syncFromStore()
            lastRefreshed = Date()
            isLoading = false
        }
    }

    func refreshFlight(_ flight: Flight) {
        Task {
            guard let refreshed = try? await apiService.getFlightStatus(flightNumber: flight.flightNumber) else { return }
            let merged = Flight(
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
            dataStore.updateFlight(merged)
            syncFromStore()
        }
    }

    // MARK: - Periodic Refresh

    private func startPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                refreshAllFlights()
            }
        }
    }

    // MARK: - Location Tracking

    private func startLocationTrackingIfNeeded() {
        let activeFlights = trackedFlights.filter { $0.isActive }
        guard !activeFlights.isEmpty else { return }
        locationTracker.requestPermission()

        if let firstActive = activeFlights.first, let dest = firstActive.currentCoordinate {
            locationTracker.startTracking(destination: dest)
        } else if let firstActive = activeFlights.first {
            locationTracker.startTracking(destination: firstActive.arrival.coordinate)
        }
    }

    // MARK: - Computed ETA

    /// Returns offline ETA for a flight using GPS or great-circle interpolation
    func computedETA(for flight: Flight) -> Date? {
        // If we have a live estimated arrival, use it
        if let eta = flight.estimatedArrival { return eta }

        // Try GPS-based ETA if we're tracking this flight
        if flight.isActive, let gpsETA = locationTracker.estimatedArrivalDate {
            return gpsETA
        }

        // Fallback: great-circle from current position (interpolated)
        if flight.isActive, let currentCoord = flight.currentCoordinate {
            return LocationTracker.offlineETA(
                from: currentCoord,
                to: flight.arrival.coordinate,
                speedKmh: flight.speed ?? 900
            )
        }

        return flight.scheduledArrival
    }

    deinit {
        refreshTask?.cancel()
    }
}
