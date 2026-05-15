import SwiftUI

struct AirportTimeView: View {
    let airport: Airport
    let scheduledTime: Date
    let actualTime: Date?
    var gate: String?
    var terminal: String?
    var alignment: HorizontalAlignment = .leading
    var showLabels: Bool = true

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    private var isDelayed: Bool {
        guard let actual = actualTime else { return false }
        return actual.timeIntervalSince(scheduledTime) > 5 * 60
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            // IATA code - large
            Text(airport.iata)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // City name
            Text(airport.city)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            // Scheduled time
            Text(timeFormatter.string(from: scheduledTime))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(isDelayed ? .white.opacity(0.5) : .white)
                .strikethrough(isDelayed)

            // Actual time (if different)
            if let actual = actualTime, isDelayed {
                Text(timeFormatter.string(from: actual))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.0))
            }

            // Gate / Terminal
            if showLabels {
                HStack(spacing: 8) {
                    if let terminal = terminal {
                        Label {
                            Text("T\(terminal)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "building.2")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                    }

                    if let gate = gate {
                        Label {
                            Text("Gate \(gate)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "door.right.hand.open")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
    }
}

struct CompactAirportTimeView: View {
    let airport: Airport
    let time: Date
    var alignment: HorizontalAlignment = .leading

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(airport.iata)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(timeFormatter.string(from: time))
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
            Text(airport.city)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
        }
    }
}
