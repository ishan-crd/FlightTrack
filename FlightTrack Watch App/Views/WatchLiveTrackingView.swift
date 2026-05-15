import SwiftUI
import MapKit

struct WatchLiveTrackingView: View {
    let flight: Flight
    @State private var simulator = WatchFlightSimulator()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showFullMap: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Mini map
                mapSection

                // ETA
                etaSection

                // Telemetry
                telemetrySection

                // Progress
                progressSection

                // Stop button
                Button(role: .destructive) {
                    simulator.stopSimulation()
                    dismiss()
                } label: {
                    Label("Stop Tracking", systemImage: "stop.circle")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Live")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFullMap) {
            WatchLiveTrackingFullMapView(
                flight: flight,
                simulator: simulator
            )
        }
        .onAppear {
            simulator.speedMultiplier = 120
            simulator.startSimulation(flight: flight)
        }
        .onDisappear {
            simulator.stopSimulation()
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            // Route
            MapPolyline(coordinates: [flight.departure.coordinate, flight.arrival.coordinate])
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            // Departure
            Annotation("", coordinate: flight.departure.coordinate) {
                Circle().fill(.blue).frame(width: 10, height: 10)
            }

            // Arrival
            Annotation("", coordinate: flight.arrival.coordinate) {
                Circle().fill(.green).frame(width: 10, height: 10)
            }

            // Aircraft
            if let coord = simulator.currentCoordinate {
                Annotation("", coordinate: coord) {
                    ZStack {
                        Circle().fill(.cyan.opacity(0.3)).frame(width: 24, height: 24)
                        Image(systemName: "airplane")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(simulator.heading - 45))
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls { }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    showFullMap = true
                }
        }
        .onChange(of: simulator.progress) {
            updateCamera()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updateCamera()
            }
        }
    }

    // MARK: - ETA

    private var etaSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ETA")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                if let eta = simulator.etaDate {
                    Text(timeFormatter.string(from: eta))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                } else {
                    Text("--:--")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("REMAINING")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(formatDistance(simulator.distanceRemaining))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Telemetry

    private var telemetrySection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Image(systemName: "arrow.up.to.line")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                Text(formatAltitude(simulator.altitude))
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                Text("ALT")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 24)

            VStack(spacing: 2) {
                Image(systemName: "speedometer")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f", simulator.speed))
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                Text("km/h")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 24)

            VStack(spacing: 2) {
                Image(systemName: "location.north.fill")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f°", simulator.heading))
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                Text("HDG")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text(flight.departure.iata)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                Spacer()
                Text("\(Int(simulator.progress * 100))%")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.cyan)
                Spacer()
                Text(flight.arrival.iata)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.cyan)
                        .frame(width: geo.size.width * simulator.progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func updateCamera() {
        guard let coord = simulator.currentCoordinate else { return }
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
            ))
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        meters > 1000 ? String(format: "%.0f km", meters / 1000) : String(format: "%.0f m", meters)
    }

    private func formatAltitude(_ meters: Double) -> String {
        let feet = meters * 3.28084
        return feet > 1000 ? String(format: "%.0fk", feet / 1000) : String(format: "%.0f", feet)
    }
}

// MARK: - Full-Screen Interactive Map (Watch)

struct WatchLiveTrackingFullMapView: View {
    let flight: Flight
    let simulator: WatchFlightSimulator

    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            MapPolyline(coordinates: [flight.departure.coordinate, flight.arrival.coordinate])
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            Annotation("", coordinate: flight.departure.coordinate) {
                Circle().fill(.blue).frame(width: 10, height: 10)
            }

            Annotation("", coordinate: flight.arrival.coordinate) {
                Circle().fill(.green).frame(width: 10, height: 10)
            }

            if let coord = simulator.currentCoordinate {
                Annotation("", coordinate: coord) {
                    ZStack {
                        Circle().fill(.cyan.opacity(0.3)).frame(width: 24, height: 24)
                        Image(systemName: "airplane")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(simulator.heading - 45))
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .ignoresSafeArea()
        .onAppear {
            fitToRoute()
        }
    }

    private func fitToRoute() {
        var coords = [flight.departure.coordinate, flight.arrival.coordinate]
        if let ac = simulator.currentCoordinate { coords.append(ac) }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(2.0, (lats.max()! - lats.min()!) * 1.3),
            longitudeDelta: max(2.0, (lons.max()! - lons.min()!) * 1.3)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
