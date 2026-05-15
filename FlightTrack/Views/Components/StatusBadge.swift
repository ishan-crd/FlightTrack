import SwiftUI

struct StatusBadge: View {
    let status: FlightStatus
    var compact: Bool = false

    private var badgeColor: Color {
        switch status {
        case .scheduled: return .blue
        case .boarding: return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .departed: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .inFlight: return Color(red: 0.0, green: 0.78, blue: 0.48)
        case .landed: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .arrived: return Color(red: 0.18, green: 0.72, blue: 0.36)
        case .delayed: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .cancelled: return Color(red: 0.95, green: 0.27, blue: 0.27)
        case .diverted: return Color(red: 0.8, green: 0.3, blue: 0.9)
        case .unknown: return Color.gray
        }
    }

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            Image(systemName: status.icon)
                .font(compact ? .caption2 : .caption)
                .fontWeight(.semibold)
            if !compact {
                Text(status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(badgeColor.opacity(0.15), in: Capsule())
        .overlay(Capsule().strokeBorder(badgeColor.opacity(0.3), lineWidth: 0.5))
    }
}
