import SwiftUI
import MapKit
import CoreLocation

struct LiveTrackingView: View {
    let flight: Flight
    var viewModel: FlightViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var simulator = FlightSimulator()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isUsingGPS: Bool = false
    @State private var showControls: Bool = true
    @State private var mapStyle: MapStyleOption = .hybrid
    @State private var showFullMap: Bool = false

    enum MapStyleOption: String, CaseIterable {
        case hybrid = "Satellite"
        case standard = "Standard"
    }

    // Active location: GPS or simulator
    private var activeLocation: CLLocation? {
        isUsingGPS ? viewModel.locationTracker.currentLocation : simulator.currentLocation
    }

    private var activeCoordinate: CLLocationCoordinate2D? {
        activeLocation?.coordinate
    }

    private var activeAltitude: Double {
        if isUsingGPS {
            return viewModel.locationTracker.currentAltitude
        }
        return simulator.altitude
    }

    private var activeSpeed: Double {
        if isUsingGPS {
            return viewModel.locationTracker.currentSpeed
        }
        return simulator.speed
    }

    private var activeHeading: Double {
        if isUsingGPS {
            return viewModel.locationTracker.currentHeading
        }
        return simulator.heading
    }

    private var activeProgress: Double {
        if isUsingGPS {
            guard let loc = viewModel.locationTracker.currentLocation else { return 0 }
            let depLoc = CLLocation(latitude: flight.departure.latitude, longitude: flight.departure.longitude)
            let arrLoc = CLLocation(latitude: flight.arrival.latitude, longitude: flight.arrival.longitude)
            let total = depLoc.distance(from: arrLoc)
            let traveled = depLoc.distance(from: loc)
            return min(1.0, max(0, traveled / total))
        }
        return simulator.progress
    }

    private var activeDistanceRemaining: Double {
        if isUsingGPS {
            return viewModel.locationTracker.distanceToDestination
        }
        return simulator.distanceRemaining
    }

    private var activeETA: Date? {
        if isUsingGPS {
            return viewModel.locationTracker.estimatedArrivalDate
        }
        return simulator.etaDate
    }

    // Route polyline (great circle)
    private var routeCoordinates: [CLLocationCoordinate2D] {
        FlightSimulator.greatCirclePoints(from: flight.departure.coordinate, to: flight.arrival.coordinate)
    }

    // Traveled portion of the route
    private var traveledCoordinates: [CLLocationCoordinate2D] {
        let steps = Int(activeProgress * 80)
        return Array(routeCoordinates.prefix(max(1, steps + 1)))
    }

    var body: some View {
        ZStack {
            // Full-screen map
            mapView
                .ignoresSafeArea()
                .onTapGesture {
                    showFullMap = true
                }

            // Overlays
            VStack(spacing: 0) {
                if showControls {
                    topBar
                }

                Spacer()

                if showControls {
                    bottomPanel
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showFullMap) {
            LiveTrackingFullMapView(
                flight: flight,
                activeCoordinate: activeCoordinate,
                activeHeading: activeHeading,
                activeProgress: activeProgress,
                routeCoordinates: routeCoordinates,
                traveledCoordinates: traveledCoordinates,
                mapStyle: mapStyle
            )
        }
        .onAppear {
            startTracking()
        }
        .onDisappear {
            simulator.stopSimulation()
            if isUsingGPS {
                viewModel.locationTracker.stopTracking()
            }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Full route (dashed)
            MapPolyline(coordinates: routeCoordinates)
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))

            // Traveled route (solid gradient)
            if traveledCoordinates.count > 1 {
                MapPolyline(coordinates: traveledCoordinates)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3)
                    )
            }

            // Departure marker
            Annotation("", coordinate: flight.departure.coordinate, anchor: .bottom) {
                airportMarker(iata: flight.departure.iata, color: .blue)
            }

            // Arrival marker
            Annotation("", coordinate: flight.arrival.coordinate, anchor: .bottom) {
                airportMarker(iata: flight.arrival.iata, color: .green)
            }

            // Aircraft / You are here marker
            if let coord = activeCoordinate {
                Annotation("", coordinate: coord) {
                    ZStack {
                        // Pulsing ring
                        Circle()
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 2)
                            .frame(width: 50, height: 50)

                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "airplane")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(activeHeading - 45))
                            .shadow(color: .cyan, radius: 4)
                    }
                }
            }
        }
        .mapStyle(mapStyle == .hybrid ? .hybrid(elevation: .realistic) : .standard(elevation: .flat))
        .onChange(of: activeCoordinate?.latitude) {
            updateCamera()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(flight.flightNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("\(flight.departure.iata) → \(flight.arrival.iata)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // GPS / Demo toggle
            HStack(spacing: 4) {
                Image(systemName: isUsingGPS ? "location.fill" : "play.circle.fill")
                    .font(.caption)
                Text(isUsingGPS ? "GPS" : "Demo")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isUsingGPS ? .green : .cyan)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .onTapGesture {
                toggleMode()
            }

            // Map style toggle
            Button {
                mapStyle = mapStyle == .hybrid ? .standard : .hybrid
            } label: {
                Image(systemName: mapStyle == .hybrid ? "map" : "globe.americas")
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * activeProgress)
                }
            }
            .frame(height: 3)

            VStack(spacing: 12) {
                // ETA Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ETA")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                        if let eta = activeETA {
                            Text(eta, style: .time)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                        } else {
                            Text("--:--")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("REMAINING")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(formatDistance(activeDistanceRemaining))
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("PROGRESS")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(Int(activeProgress * 100))%")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(.cyan)
                            .monospacedDigit()
                    }
                }

                // Telemetry row
                HStack(spacing: 0) {
                    telemetryItem(icon: "arrow.up.to.line", value: formatAltitude(activeAltitude), label: "ALT")
                    Divider().frame(height: 32).overlay(.white.opacity(0.1))
                    telemetryItem(icon: "speedometer", value: formatSpeed(activeSpeed), label: "SPEED")
                    Divider().frame(height: 32).overlay(.white.opacity(0.1))
                    telemetryItem(icon: "location.north.line.fill", value: String(format: "%.0f°", activeHeading), label: "HDG")
                    Divider().frame(height: 32).overlay(.white.opacity(0.1))
                    telemetryItem(
                        icon: "location.fill",
                        value: activeCoordinate.map { String(format: "%.2f, %.2f", $0.latitude, $0.longitude) } ?? "—",
                        label: "POS"
                    )
                }
                .padding(.vertical, 8)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                // Speed control (demo mode only)
                if !isUsingGPS && simulator.isSimulating {
                    HStack(spacing: 12) {
                        Text("Sim Speed")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))

                        ForEach([60.0, 120.0, 300.0, 600.0], id: \.self) { mult in
                            Button {
                                simulator.speedMultiplier = mult
                            } label: {
                                Text("\(Int(mult))x")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        simulator.speedMultiplier == mult
                                            ? Color.cyan.opacity(0.3)
                                            : Color.white.opacity(0.06),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(simulator.speedMultiplier == mult ? .cyan : .white.opacity(0.5))
                            }
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Telemetry Item

    private func telemetryItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Airport Marker

    private func airportMarker(iata: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(iata)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color, in: RoundedRectangle(cornerRadius: 6))
                .shadow(color: color.opacity(0.5), radius: 4)
            Image(systemName: "triangle.fill")
                .font(.system(size: 6))
                .foregroundStyle(color)
        }
    }

    // MARK: - Actions

    private func startTracking() {
        // Start in demo mode by default
        simulator.startSimulation(flight: flight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateCamera()
        }
    }

    private func toggleMode() {
        if isUsingGPS {
            // Switch to demo
            isUsingGPS = false
            viewModel.locationTracker.stopTracking()
            simulator.startSimulation(flight: flight)
        } else {
            // Switch to GPS
            simulator.stopSimulation()
            isUsingGPS = true
            viewModel.locationTracker.requestPermission()
            viewModel.locationTracker.startTracking(destination: flight.arrival.coordinate)
        }
    }

    private func updateCamera() {
        guard let coord = activeCoordinate else {
            // Fit to route
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (flight.departure.latitude + flight.arrival.latitude) / 2,
                    longitude: (flight.departure.longitude + flight.arrival.longitude) / 2
                ),
                span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
            )
            cameraPosition = .region(region)
            return
        }

        // Follow the aircraft with some look-ahead
        let lookAheadDistance: CLLocationDistance = activeAltitude * 5
        let headingRad = activeHeading * .pi / 180
        let lookAheadLat = coord.latitude + (lookAheadDistance / 111000) * cos(headingRad) * 0.3
        let lookAheadLon = coord.longitude + (lookAheadDistance / (111000 * cos(coord.latitude * .pi / 180))) * sin(headingRad) * 0.3

        let center = CLLocationCoordinate2D(
            latitude: (coord.latitude + lookAheadLat) / 2,
            longitude: (coord.longitude + lookAheadLon) / 2
        )

        // Zoom level based on altitude
        let spanDelta = max(2, min(40, activeAltitude / 1500))

        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
            ))
        }
    }

    // MARK: - Formatters

    private func formatDistance(_ meters: Double) -> String {
        if meters > 1000 {
            return String(format: "%.0f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    private func formatAltitude(_ meters: Double) -> String {
        let feet = meters * 3.28084
        if feet > 1000 {
            return String(format: "%.1fk ft", feet / 1000)
        }
        return String(format: "%.0f ft", feet)
    }

    private func formatSpeed(_ kmh: Double) -> String {
        return String(format: "%.0f km/h", kmh)
    }
}

// MARK: - Full-Screen Interactive Map

struct LiveTrackingFullMapView: View {
    let flight: Flight
    let activeCoordinate: CLLocationCoordinate2D?
    let activeHeading: Double
    let activeProgress: Double
    let routeCoordinates: [CLLocationCoordinate2D]
    let traveledCoordinates: [CLLocationCoordinate2D]
    let mapStyle: LiveTrackingView.MapStyleOption

    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition, interactionModes: .all) {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))

                if traveledCoordinates.count > 1 {
                    MapPolyline(coordinates: traveledCoordinates)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3)
                        )
                }

                Annotation("", coordinate: flight.departure.coordinate, anchor: .bottom) {
                    VStack(spacing: 2) {
                        Text(flight.departure.iata)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 6))
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                    }
                }

                Annotation("", coordinate: flight.arrival.coordinate, anchor: .bottom) {
                    VStack(spacing: 2) {
                        Text(flight.arrival.iata)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green, in: RoundedRectangle(cornerRadius: 6))
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.green)
                    }
                }

                if let coord = activeCoordinate {
                    Annotation("", coordinate: coord) {
                        ZStack {
                            Circle()
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 2)
                                .frame(width: 50, height: 50)
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "airplane")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(activeHeading - 45))
                                .shadow(color: .cyan, radius: 4)
                        }
                    }
                }
            }
            .mapStyle(mapStyle == .hybrid ? .hybrid(elevation: .realistic) : .standard(elevation: .flat))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 54)
            .padding(.leading, 16)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            fitToRoute()
        }
    }

    private func fitToRoute() {
        var coords = [flight.departure.coordinate, flight.arrival.coordinate]
        if let ac = activeCoordinate { coords.append(ac) }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (lats.max()! - lats.min()!) * 1.4,
            longitudeDelta: (lons.max()! - lons.min()!) * 1.4
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
