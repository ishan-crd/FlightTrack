import SwiftUI

struct WatchFlightCardView: View {

    let flight: Flight

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top row: flight number + status indicator
            HStack(alignment: .center, spacing: 6) {
                Text(flight.flightNumber)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            // Route row
            HStack(spacing: 4) {
                Text(flight.departure.iata)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)

                Image(systemName: "arrow.right")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(flight.arrival.iata)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
            }

            // Time row
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)

                Text(timeFormatter.string(from: flight.scheduledDeparture))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)

                if let gate = flight.gate {
                    Text("·")
                        .foregroundStyle(.secondary)
                        .font(.system(.caption))

                    Image(systemName: "door.right.hand.open")
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)

                    Text(gate)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .containerBackground(flight.status.displayColor.opacity(0.08), for: .tabView)
    }

    private var statusBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: flight.status.icon)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
            Text(shortStatus)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(flight.status.displayColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(flight.status.displayColor.opacity(0.15), in: Capsule())
    }

    private var shortStatus: String {
        switch flight.status {
        case .scheduled: return "Sched"
        case .boarding: return "Board"
        case .departed: return "Dep"
        case .inFlight: return "Flying"
        case .landed: return "Land"
        case .arrived: return "Arr"
        case .delayed: return "Delay"
        case .cancelled: return "Cxl"
        case .diverted: return "Div"
        case .unknown: return "?"
        }
    }
}
