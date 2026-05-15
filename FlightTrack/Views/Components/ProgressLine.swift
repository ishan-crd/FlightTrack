import SwiftUI

struct ProgressLine: View {
    let progress: Double         // 0.0 - 1.0
    var isActive: Bool = false

    private let lineHeight: CGFloat = 2
    private let dotSize: CGFloat = 6
    private let planeSize: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let clampedProgress = max(0, min(1, progress))
            let planeX = totalWidth * clampedProgress

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(height: lineHeight)

                // Filled portion
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.2, green: 0.78, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, planeX), height: lineHeight)

                // Departure dot
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: dotSize, height: dotSize)
                    .offset(x: -dotSize / 2)

                // Arrival dot
                Circle()
                    .fill(.white.opacity(clampedProgress >= 1 ? 1.0 : 0.3))
                    .frame(width: dotSize, height: dotSize)
                    .offset(x: totalWidth - dotSize / 2)

                // Airplane icon at current position
                if clampedProgress > 0 && clampedProgress < 1 {
                    Image(systemName: "airplane")
                        .font(.system(size: planeSize, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-45))
                        .offset(x: planeX - planeSize / 2, y: -planeSize / 2 - 4)
                        .shadow(color: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.6), radius: 4)
                        .scaleEffect(isActive ? 1.0 : 0.85)
                        .animation(isActive ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isActive)
                }
            }
        }
        .frame(height: planeSize + lineHeight + 8)
    }
}

struct DetailedProgressLine: View {
    let flight: Flight

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    var body: some View {
        VStack(spacing: 8) {
            ProgressLine(progress: flight.progress, isActive: flight.isActive)

            HStack {
                Text(flight.departure.iata)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                if flight.isActive {
                    Text("\(Int(flight.progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text(flight.arrival.iata)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
