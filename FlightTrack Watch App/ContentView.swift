import SwiftUI

struct ContentView: View {

    @Environment(WatchFlightViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.trackedFlights.isEmpty {
                    emptyState
                } else {
                    flightList
                }
            }
            .navigationTitle("Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddFlight = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: Bindable(viewModel).showAddFlight) {
                WatchAddFlightView(viewModel: viewModel)
            }
        }
        .onAppear {
            // Pre-populate sample flights on first launch
            let key = "watch.has.launched"
            if !UserDefaults.standard.bool(forKey: key) {
                UserDefaults.standard.set(true, forKey: key)
                for flight in MockFlightGenerator.sampleFlights {
                    viewModel.addFlight(flight)
                }
            }
        }
    }

    // MARK: - Subviews

    private var flightList: some View {
        List {
            ForEach(viewModel.trackedFlights) { flight in
                NavigationLink {
                    WatchFlightDetailView(flight: flight, viewModel: viewModel)
                } label: {
                    WatchFlightCardView(flight: flight)
                }
                .listItemTint(.clear)
            }
            .onDelete { offsets in
                viewModel.removeFlight(at: offsets)
            }

            addButton
        }
        .listStyle(.carousel)
        .refreshable {
            viewModel.refreshAll()
            try? await Task.sleep(nanoseconds: 800_000_000)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Flights")
                .font(.system(.headline, design: .rounded))

            Text("Tap + to track a flight")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.showAddFlight = true
            } label: {
                Label("Add Flight", systemImage: "plus.circle.fill")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 4)
        }
        .padding()
    }

    private var addButton: some View {
        Button {
            viewModel.showAddFlight = true
        } label: {
            Label("Add Flight", systemImage: "plus.circle.fill")
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .frame(maxWidth: .infinity)
        }
        .listItemTint(.blue)
        .padding(.vertical, 2)
    }
}
