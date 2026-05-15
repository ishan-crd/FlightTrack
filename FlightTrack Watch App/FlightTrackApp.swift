import SwiftUI

@main
struct FlightTrack_Watch_AppApp: App {

    @State private var viewModel = WatchFlightViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
