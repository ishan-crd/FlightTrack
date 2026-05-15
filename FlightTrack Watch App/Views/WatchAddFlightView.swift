import SwiftUI

struct WatchAddFlightView: View {

    @Bindable var viewModel: WatchFlightViewModel
    @State private var query: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // Search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(.body, design: .rounded))

                        TextField("Flight no.", text: $query)
                            .font(.system(.body, design: .rounded))
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

                    // Search button
                    Button {
                        performSearch()
                    } label: {
                        HStack {
                            if viewModel.isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass.circle.fill")
                            }
                            Text(viewModel.isSearching ? "Searching..." : "Search")
                        }
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSearching)

                    // Error
                    if let error = viewModel.searchError {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Results
                    if !viewModel.searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Results")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 2)

                            ForEach(viewModel.searchResults) { flight in
                                resultRow(flight)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
            .navigationTitle("Add Flight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func resultRow(_ flight: Flight) -> some View {
        let alreadyTracked = viewModel.isTracking(flight)

        Button {
            if !alreadyTracked {
                viewModel.addFlight(flight)
                dismiss()
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.flightNumber)
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Text(flight.departure.iata)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(.caption2))
                        Text(flight.arrival.iata)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(.secondary)

                    Text(flight.airline)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                if alreadyTracked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(.footnote))
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                        .font(.system(.footnote))
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(alreadyTracked)
    }

    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.search(query: trimmed)
    }
}
