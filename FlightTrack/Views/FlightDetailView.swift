import SwiftUI
import MapKit

struct FlightDetailView: View {
    let flight: Flight
    var viewModel: FlightViewModel
    @State private var showFullMap: Bool = false
    @State private var showLiveTracking: Bool = false
    @State private var isRefreshing: Bool = false

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    private var headerGradient: LinearGradient {
        switch flight.status {
        case .inFlight, .departed:
            return LinearGradient(colors: [Color(red: 0.0, green: 0.22, blue: 0.55), Color(red: 0.0, green: 0.12, blue: 0.35)], startPoint: .top, endPoint: .bottom)
        case .boarding:
            return LinearGradient(colors: [Color(red: 0.0, green: 0.30, blue: 0.55), Color(red: 0.0, green: 0.15, blue: 0.35)], startPoint: .top, endPoint: .bottom)
        case .delayed:
            return LinearGradient(colors: [Color(red: 0.45, green: 0.28, blue: 0.0), Color(red: 0.25, green: 0.15, blue: 0.0)], startPoint: .top, endPoint: .bottom)
        case .cancelled:
            return LinearGradient(colors: [Color(red: 0.45, green: 0.10, blue: 0.10), Color(red: 0.25, green: 0.05, blue: 0.05)], startPoint: .top, endPoint: .bottom)
        case .arrived, .landed:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.35, blue: 0.15), Color(red: 0.03, green: 0.18, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.18), Color(red: 0.06, green: 0.06, blue: 0.12)], startPoint: .top, endPoint: .bottom)
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Content sections
                    VStack(spacing: 16) {
                        // Airport times section
                        airportSection

                        // Progress section (only for active flights)
                        if flight.isActive || flight.status == .landed || flight.status == .arrived {
                            progressSection
                        }

                        // Live Tracking button (for active flights)
                        if flight.isActive {
                            liveTrackingButton
                        }

                        // Map section
                        mapSection

                        // Flight info
                        flightInfoSection

                        // Baggage info
                        if flight.baggageBelt != nil || flight.arrivalTerminal != nil {
                            baggageSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .refreshable {
                await refreshFlight()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(flight.flightNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(flight.airline)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshFlight() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.white.opacity(0.7))
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullMap) {
            NavigationStack {
                FlightMapView(flight: flight)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("\(flight.departure.iata) → \(flight.arrival.iata)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showFullMap = false }
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showLiveTracking) {
            LiveTrackingView(flight: flight, viewModel: viewModel)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            headerGradient

            VStack(spacing: 12) {
                // Airline + date
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.airline)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text(dateFormatter.string(from: flight.scheduledDeparture))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    StatusBadge(status: flight.status)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Large route display
                HStack(alignment: .center, spacing: 0) {
                    Text(flight.departure.iata)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: "airplane")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(formattedDuration)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text(flight.arrival.iata)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28)

                // ETA row for active flights
                if flight.isActive {
                    let eta = viewModel.computedETA(for: flight)
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                        Text("ETA \(eta.map { timeFormatter.string(from: $0) } ?? "--:--")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 4)
                }
            }
            .padding(.bottom, 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - Airport Section

    private var airportSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Departure
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("DEPARTURE")
                AirportTimeView(
                    airport: flight.departure,
                    scheduledTime: flight.scheduledDeparture,
                    actualTime: flight.actualDeparture,
                    gate: flight.gate,
                    terminal: flight.terminal,
                    alignment: .leading
                )
            }

            Spacer()

            // Arrival
            VStack(alignment: .trailing, spacing: 6) {
                sectionLabel("ARRIVAL")
                AirportTimeView(
                    airport: flight.arrival,
                    scheduledTime: flight.scheduledArrival,
                    actualTime: flight.actualArrival ?? flight.estimatedArrival,
                    gate: flight.arrivalGate,
                    terminal: flight.arrivalTerminal,
                    alignment: .trailing
                )
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("FLIGHT PROGRESS")
            DetailedProgressLine(flight: flight)
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Map Section

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("ROUTE MAP")
                Spacer()
                Button {
                    showFullMap = true
                } label: {
                    Text("Expand")
                        .font(.caption)
                        .foregroundStyle(Color.blue)
                }
            }

            FlightMapView(flight: flight)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showFullMap = true
                        }
                }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Flight Info Section

    private var flightInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("FLIGHT DETAILS")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let aircraft = flight.aircraftType {
                    infoCell(icon: "airplane.circle", title: "Aircraft", value: aircraft)
                }
                if let altitude = flight.altitude {
                    infoCell(icon: "arrow.up.right", title: "Altitude", value: String(format: "%.0f m", altitude))
                }
                if let speed = flight.speed {
                    infoCell(icon: "speedometer", title: "Speed", value: String(format: "%.0f km/h", speed))
                }
                if let heading = flight.heading {
                    infoCell(icon: "location.north.line", title: "Heading", value: String(format: "%.0f°", heading))
                }
                let distKm = flight.totalDistance / 1000
                infoCell(icon: "arrow.left.and.right", title: "Distance", value: String(format: "%.0f km", distKm))
                infoCell(icon: "clock", title: "Duration", value: formattedDuration)
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Baggage Section

    private var baggageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("BAGGAGE & ARRIVAL")

            HStack(spacing: 16) {
                if let belt = flight.baggageBelt {
                    infoCell(icon: "suitcase.rolling", title: "Baggage Belt", value: belt)
                }
                if let terminal = flight.arrivalTerminal {
                    infoCell(icon: "building.2", title: "Terminal", value: terminal)
                }
                if let gate = flight.arrivalGate {
                    infoCell(icon: "door.left.hand.open", title: "Arr. Gate", value: gate)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }

    // MARK: - Live Tracking Button

    private var liveTrackingButton: some View {
        Button {
            showLiveTracking = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "location.fill.viewfinder")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Live Flight Tracking")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text("See your real-time position, altitude & ETA")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.15, blue: 0.30), Color(red: 0.0, green: 0.08, blue: 0.20)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.cyan.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.4))
            .kerning(1.2)
    }

    private func infoCell(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(Color.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(10)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private var formattedDuration: String {
        let interval = flight.scheduledArrival.timeIntervalSince(flight.scheduledDeparture)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func refreshFlight() async {
        isRefreshing = true
        viewModel.refreshFlight(flight)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}
