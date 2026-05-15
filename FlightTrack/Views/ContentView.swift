import SwiftUI

struct ContentView: View {
    @State private var viewModel = FlightViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MyFlightsTab(viewModel: viewModel)
                .tabItem {
                    Label("My Flights", systemImage: "airplane.circle.fill")
                }
                .tag(0)

            SearchTab(viewModel: viewModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
        }
        .tint(Color.blue)
        .preferredColorScheme(.dark)
    }
}

// MARK: - My Flights Tab

struct MyFlightsTab: View {
    @Bindable var viewModel: FlightViewModel
    @State private var selectedFlight: Flight?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.10)
                    .ignoresSafeArea()

                if viewModel.trackedFlights.isEmpty {
                    emptyState
                } else {
                    flightsList
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.showAddFlight = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue, in: Circle())
                                .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Button {
                            viewModel.refreshAllFlights()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedFlight) { flight in
                FlightDetailView(flight: flight, viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAddFlight) {
                AddFlightView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.refreshAllFlights()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private var flightsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Last refreshed header
                if let refreshed = viewModel.lastRefreshed {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Updated \(refreshed, style: .relative) ago")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }

                ForEach(viewModel.trackedFlights) { flight in
                    FlightCardView(flight: flight) {
                        selectedFlight = flight
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.removeFlight(flight)
                            }
                        } label: {
                            Label("Remove Flight", systemImage: "trash")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 80) // room for FAB
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "airplane.departure")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.blue.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Flights Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Add a flight by tapping the + button\nto start tracking it.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.showAddFlight = true
            } label: {
                Label("Add a Flight", systemImage: "plus.circle.fill")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}

// MARK: - Search Tab

struct SearchTab: View {
    var viewModel: FlightViewModel
    @State private var query: String = ""
    @State private var selectedFlight: Flight?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.10)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("Flight number, airline...", text: $query)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .tint(.blue)
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                        if !query.isEmpty {
                            Button {
                                query = ""
                                viewModel.clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.1)))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    if viewModel.isSearching {
                        Spacer()
                        ProgressView("Searching...")
                            .tint(.white)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    } else if viewModel.searchResults.isEmpty && query.isEmpty {
                        searchPrompt
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { flight in
                                    FlightCardView(flight: flight) {
                                        selectedFlight = flight
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if viewModel.isTracked(flight) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .padding(8)
                                        } else {
                                            Button {
                                                viewModel.addFlight(flight)
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundStyle(.blue)
                                                    .font(.title3)
                                            }
                                            .padding(8)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedFlight) { flight in
                FlightDetailView(flight: flight, viewModel: viewModel)
            }
        }
    }

    private var searchPrompt: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "airplane.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.15))

                Text("Search for a flight")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.5))

                Text("Enter a flight number like EK215\nor AA100 to get started.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }

            // Quick suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("TRY THESE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.3))
                    .kerning(1.2)

                FlowLayout(spacing: 8) {
                    ForEach(["EK215", "SQ321", "AA100", "AI101", "BA142", "6E2341"], id: \.self) { suggestion in
                        Button {
                            query = suggestion
                            performSearch()
                        } label: {
                            Text(suggestion)
                                .font(.callout)
                                .fontWeight(.medium)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.08), in: Capsule())
                                .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.searchFlights(query: query)
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([subview])
                currentRowWidth = size.width + spacing
            } else {
                rows[rows.count - 1].append(subview)
                currentRowWidth += size.width + spacing
            }
        }
        return rows
    }
}
