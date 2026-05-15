import SwiftUI
import MapKit

struct FlightMapView: View {
    let flight: Flight
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Build the great-circle polyline points
    private var routeCoordinates: [CLLocationCoordinate2D] {
        let steps = 60
        var coords: [CLLocationCoordinate2D] = []
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let lat = flight.departure.latitude + t * (flight.arrival.latitude - flight.departure.latitude)
            let lon = flight.departure.longitude + t * (flight.arrival.longitude - flight.departure.longitude)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }

    private var currentCoord: CLLocationCoordinate2D {
        flight.currentCoordinate ?? LocationTracker.interpolatedPosition(
            from: flight.departure.coordinate,
            to: flight.arrival.coordinate,
            progress: flight.progress
        )
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(position: $cameraPosition) {
                // Route polyline
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, dash: [6, 4])
                    )

                // Departure airport marker
                Annotation(flight.departure.iata, coordinate: flight.departure.coordinate) {
                    AirportPin(iata: flight.departure.iata, isDeparture: true)
                }

                // Arrival airport marker
                Annotation(flight.arrival.iata, coordinate: flight.arrival.coordinate) {
                    AirportPin(iata: flight.arrival.iata, isDeparture: false)
                }

                // Aircraft position marker
                if flight.isActive {
                    Annotation("", coordinate: currentCoord) {
                        AircraftMarker(heading: flight.heading ?? 0)
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .onAppear {
                fitCamera()
            }

            // Overlay: altitude + speed
            if flight.isActive {
                flightStatsOverlay
                    .padding(16)
            }
        }
    }

    private var flightStatsOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let altitude = flight.altitude {
                statRow(icon: "arrow.up.right", label: "ALT", value: String(format: "%.0f m", altitude))
            }
            if let speed = flight.speed {
                statRow(icon: "speedometer", label: "SPD", value: String(format: "%.0f km/h", speed))
            }
            if let heading = flight.heading {
                statRow(icon: "location.north.line", label: "HDG", value: String(format: "%.0f°", heading))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    private func fitCamera() {
        // Fit map to show both airports + current position
        let coords = [flight.departure.coordinate, flight.arrival.coordinate, currentCoord]
        var region = MKCoordinateRegion()
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        region.center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        region.span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.4,
            longitudeDelta: (maxLon - minLon) * 1.4
        )
        cameraPosition = .region(region)
    }
}

// MARK: - Supporting Views

struct AirportPin: View {
    let iata: String
    let isDeparture: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(iata)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isDeparture ? Color.blue : Color.green, in: RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 3)

            Image(systemName: "triangle.fill")
                .font(.system(size: 6))
                .foregroundStyle(isDeparture ? Color.blue : Color.green)
        }
    }
}

struct AircraftMarker: View {
    let heading: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 36, height: 36)

            Image(systemName: "airplane")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(heading - 45))
        }
        .shadow(color: Color.blue.opacity(0.5), radius: 6)
    }
}
