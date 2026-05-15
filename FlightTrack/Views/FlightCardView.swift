import SwiftUI

struct FlightCardView: View {
    let flight: Flight
    var onTap: (() -> Void)? = nil

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    private var cardGradient: LinearGradient {
        switch flight.status {
        case .inFlight, .departed:
            return LinearGradient(
                colors: [Color(red: 0.05, green: 0.12, blue: 0.28), Color(red: 0.04, green: 0.09, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .boarding:
            return LinearGradient(
                colors: [Color(red: 0.05, green: 0.20, blue: 0.30), Color(red: 0.03, green: 0.12, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .delayed:
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.14, blue: 0.04), Color(red: 0.14, green: 0.10, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cancelled:
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.06, blue: 0.06), Color(red: 0.15, green: 0.04, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .arrived, .landed:
            return LinearGradient(
                colors: [Color(red: 0.06, green: 0.18, blue: 0.10), Color(red: 0.04, green: 0.12, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.10, blue: 0.15), Color(red: 0.07, green: 0.07, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 0) {
                // Header: airline + flight number + status
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.airline)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(flight.flightNumber)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    StatusBadge(status: flight.status)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)

                // Main content: departure → arrival
                HStack(alignment: .center, spacing: 0) {
                    // Departure
                    CompactAirportTimeView(
                        airport: flight.departure,
                        time: flight.actualDeparture ?? flight.scheduledDeparture,
                        alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Center: progress + aircraft
                    VStack(spacing: 4) {
                        if flight.isActive {
                            Text("\(Int(flight.progress * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.5))
                        } else if let aircraftType = flight.aircraftType {
                            Text(aircraftType)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .lineLimit(1)
                        }

                        ProgressLine(progress: flight.progress, isActive: flight.isActive)
                            .frame(width: 90)
                    }
                    .frame(maxWidth: .infinity)

                    // Arrival
                    CompactAirportTimeView(
                        airport: flight.arrival,
                        time: flight.estimatedArrival ?? flight.scheduledArrival,
                        alignment: .trailing
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Footer: gate info
                if flight.gate != nil || flight.terminal != nil || flight.baggageBelt != nil {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)

                    HStack(spacing: 16) {
                        if let terminal = flight.terminal, let gate = flight.gate {
                            Label("T\(terminal) • Gate \(gate)", systemImage: "door.right.hand.open")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        if let belt = flight.baggageBelt {
                            Label(belt, systemImage: "suitcase.rolling")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        } else if let arrGate = flight.arrivalGate {
                            Label("Arr Gate \(arrGate)", systemImage: "door.left.hand.open")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .background(cardGradient, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
