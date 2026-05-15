import SwiftUI
import MapKit

struct WatchFlightMapView: View {

    let flight: Flight

    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Annotations

    private var departureCoordinate: CLLocationCoordinate2D {
        flight.departure.coordinate
    }

    private var arrivalCoordinate: CLLocationCoordinate2D {
        flight.arrival.coordinate
    }

    private var aircraftCoordinate: CLLocationCoordinate2D? {
        flight.currentCoordinate
    }

    // MARK: - Route Polyline

    private var routeCoordinates: [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = [departureCoordinate]
        if let aircraft = aircraftCoordinate {
            points.append(aircraft)
        }
        points.append(arrivalCoordinate)
        return points
    }

    // MARK: - Camera Region

    private var routeRegion: MKCoordinateRegion {
        let lats = routeCoordinates.map { $0.latitude }
        let lons = routeCoordinates.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion(
                center: departureCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(2.0, (maxLat - minLat) * 1.3),
            longitudeDelta: max(2.0, (maxLon - minLon) * 1.3)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Map(position: $cameraPosition) {
            // Route polyline
            MapPolyline(coordinates: routeCoordinates)
                .stroke(
                    flight.status.displayColor.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 4])
                )

            // Departure marker
            Annotation(flight.departure.iata, coordinate: departureCoordinate) {
                airportMarker(iata: flight.departure.iata, color: .green)
            }

            // Arrival marker
            Annotation(flight.arrival.iata, coordinate: arrivalCoordinate) {
                airportMarker(iata: flight.arrival.iata, color: .red)
            }

            // Aircraft marker (in-flight only)
            if let aircraft = aircraftCoordinate, flight.isActive {
                Annotation(flight.flightNumber, coordinate: aircraft) {
                    aircraftMarker
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .navigationTitle("Route")
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(.black, for: .navigation)
        .onAppear {
            cameraPosition = .region(routeRegion)
        }
        .overlay(alignment: .bottomLeading) {
            legendOverlay
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func airportMarker(iata: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            Text(iata)
                .font(.system(size: 5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var aircraftMarker: some View {
        ZStack {
            Circle()
                .fill(.blue)
                .frame(width: 22, height: 22)
            Image(systemName: "airplane")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(flight.heading ?? 0))
        }
        .shadow(radius: 2)
    }

    private var legendOverlay: some View {
        VStack(alignment: .leading, spacing: 3) {
            legendRow(color: .green, label: flight.departure.iata)
            legendRow(color: .red, label: flight.arrival.iata)
            if flight.isActive {
                legendRow(color: .blue, label: flight.flightNumber)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(6)
    }

    @ViewBuilder
    private func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}
