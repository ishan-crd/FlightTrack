import SwiftUI

enum AddFlightMode: String, CaseIterable {
    case flightNumber = "Flight Number"
    case pnr = "PNR / Booking Ref"
}

struct AddFlightView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: FlightViewModel

    @State private var mode: AddFlightMode = .flightNumber
    @State private var inputText: String = ""
    @State private var isFocused: Bool = false

    private var placeholder: String {
        switch mode {
        case .flightNumber: return "e.g. EK215, AA100, SQ321"
        case .pnr: return "e.g. ABC123, XYZ789"
        }
    }

    private var searchButtonTitle: String {
        viewModel.isSearching ? "Searching..." : "Search"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode picker
                    Picker("Mode", selection: $mode) {
                        ForEach(AddFlightMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .onChange(of: mode) {
                        viewModel.clearSearch()
                        inputText = ""
                    }

                    // Search field
                    HStack(spacing: 12) {
                        Image(systemName: mode == .flightNumber ? "airplane" : "ticket")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 20)

                        TextField(placeholder, text: $inputText)
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .foregroundStyle(.white)
                            .font(.body)
                            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
                            .submitLabel(.search)
                            .onSubmit { performSearch() }

                        if !inputText.isEmpty {
                            Button {
                                inputText = ""
                                viewModel.clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Search button
                    Button {
                        performSearch()
                    } label: {
                        HStack {
                            if viewModel.isSearching {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(searchButtonTitle)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.blue.opacity(0.3)
                                : Color.blue,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSearching)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Error message
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.0))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    // Results
                    if viewModel.searchResults.isEmpty && !viewModel.isSearching && viewModel.errorMessage == nil {
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { flight in
                                    FlightCardView(flight: flight) {
                                        addAndDismiss(flight)
                                    }
                                    .padding(.horizontal, 20)
                                    .overlay(alignment: .topTrailing) {
                                        if viewModel.isTracked(flight) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .padding(.top, 8)
                                                .padding(.trailing, 30)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            viewModel.clearSearch()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: mode == .flightNumber ? "airplane.circle" : "ticket")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.15))
            Text("Search for a \(mode == .flightNumber ? "flight number" : "booking reference")")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func performSearch() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .flightNumber:
            viewModel.searchFlights(query: trimmed)
        case .pnr:
            viewModel.lookupPNR(pnr: trimmed)
        }
    }

    private func addAndDismiss(_ flight: Flight) {
        viewModel.addFlight(flight)
        dismiss()
    }
}
