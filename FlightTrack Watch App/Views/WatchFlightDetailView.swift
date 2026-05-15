import SwiftUI

struct WatchFlightDetailView: View {

    let flight: Flight
    @Bindable var viewModel: WatchFlightViewModel
    @State private var showMap: Bool = false
    @State private var showLiveTracking: Bool = false

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // Status banner
                statusSection

                // Route summary
                routeSection

                // Departure details
                airportSection(
                    label: "Departure",
                    airport: flight.departure,
                    scheduledTime: flight.scheduledDeparture,
                    actualTime: flight.actualDeparture,
                    gate: flight.gate,
                    terminal: flight.terminal,
                    systemIcon: "airplane.departure"
                )

                // Progress bar
                if flight.status != .cancelled && flight.status != .unknown {
                    progressSection
                }

                // In-flight telemetry
                if flight.status == .inFlight {
                    telemetrySection
                }

                // Arrival details
                airportSection(
                    label: "Arrival",
                    airport: flight.arrival,
                    scheduledTime: flight.scheduledArrival,
                    actualTime: flight.actualArrival,
                    gate: flight.arrivalGate,
                    terminal: flight.arrivalTerminal,
                    systemIcon: "airplane.arrival"
                )

                // Baggage
                if let belt = flight.baggageBelt {
                    baggageSection(belt: belt)
                }

                // Live tracking button
                if flight.isActive {
                    liveTrackButton
                }

                // Map button
                mapButton

                // Remove button
                removeButton
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .navigationTitle(flight.flightNumber)
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(flight.status.displayColor.opacity(0.06), for: .navigation)
        .sheet(isPresented: $showMap) {
            WatchFlightMapView(flight: flight)
        }
        .sheet(isPresented: $showLiveTracking) {
            WatchLiveTrackingView(flight: flight)
        }
        .onAppear {
            viewModel.refresh(flight: flight)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: flight.status.icon)
                .font(.system(size: 20, design: .rounded).weight(.semibold))
                .foregroundStyle(flight.status.displayColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(flight.status.rawValue)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(flight.status.displayColor)

                Text(flight.airline)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let aircraft = flight.aircraftType {
                Text(aircraft)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Route Section

    private var routeSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(flight.departure.iata)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(flight.departure.city)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Image(systemName: "airplane")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(flight.status.displayColor)
                .frame(width: 28)

            VStack(spacing: 2) {
                Text(flight.arrival.iata)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(flight.arrival.city)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Airport Section

    @ViewBuilder
    private func airportSection(label: String, airport: Airport, scheduledTime: Date, actualTime: Date?, gate: String?, terminal: String?, systemIcon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: systemIcon)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.name)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(.caption2))
                        Text(timeFormatter.string(from: scheduledTime))
                            .font(.system(.caption, design: .rounded).weight(.medium))

                        if let actual = actualTime {
                            Text("→")
                                .font(.system(.caption2))
                                .foregroundStyle(.secondary)
                            Text(timeFormatter.string(from: actual))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let t = terminal {
                        Label("T\(t)", systemImage: "building")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    if let g = gate {
                        Label(g, systemImage: "door.right.hand.open")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(flight.progress * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(flight.status.displayColor)
                        .frame(width: geo.size.width * flight.progress, height: 6)
                }
            }
            .frame(height: 6)

            // ETA
            HStack {
                Text("ETA")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if let eta = flight.dynamicETA {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(timeFormatter.string(from: eta))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                        Text(viewModel.timeRemainingString(to: eta))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Telemetry Section

    private var telemetrySection: some View {
        HStack(spacing: 0) {
            if let altitude = flight.altitude {
                telemetryCell(
                    icon: "arrow.up.to.line",
                    value: "\(Int(altitude / 1000))k",
                    unit: "ft"
                )
            }

            if flight.altitude != nil && flight.speed != nil {
                Divider().frame(height: 30)
            }

            if let speed = flight.speed {
                telemetryCell(
                    icon: "speedometer",
                    value: "\(Int(speed))",
                    unit: "kts"
                )
            }

            if flight.speed != nil && flight.heading != nil {
                Divider().frame(height: 30)
            }

            if let heading = flight.heading {
                telemetryCell(
                    icon: "location.north.fill",
                    value: "\(Int(heading))°",
                    unit: "hdg"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func telemetryCell(icon: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.bold))
            Text(unit)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Baggage Section

    private func baggageSection(belt: String) -> some View {
        HStack {
            Label("Baggage Belt", systemImage: "bag.fill")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(belt)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Live Track Button

    private var liveTrackButton: some View {
        Button {
            showLiveTracking = true
        } label: {
            Label("Live Track", systemImage: "location.fill.viewfinder")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.cyan)
    }

    // MARK: - Map Button

    private var mapButton: some View {
        Button {
            showMap = true
        } label: {
            Label("View Map", systemImage: "map.fill")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue.opacity(0.8))
    }

    // MARK: - Remove Button

    private var removeButton: some View {
        Button(role: .destructive) {
            viewModel.removeFlight(flight)
        } label: {
            Label("Remove", systemImage: "trash")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}
