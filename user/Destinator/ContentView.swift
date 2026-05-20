/*
 Destinator iOS — ContentView
 Main container that manages screen navigation and the side menu overlay.
 This drives the 4-screen trip flow from the wireframes:
   Welcome → Destination → Arrival → New Route
*/

import SwiftUI

struct ContentView: View {
    @StateObject private var tripManager = TripManager()
    @State private var showMenu = false

    var body: some View {
        ZStack {
            // Main screen content
            Group {
                switch tripManager.currentScreen {
                case .welcome:
                    WelcomeView(showMenu: $showMenu) {
                        withAnimation { tripManager.currentScreen = .destination }
                    }

                case .destination:
                    DestinationView(showMenu: $showMenu,
                        onBack: { withAnimation { tripManager.currentScreen = .welcome } },
                        onNext: { withAnimation { tripManager.currentScreen = .arrival } }
                    )

                case .arrival:
                    ArrivalView(showMenu: $showMenu,
                        onBack: { withAnimation { tripManager.currentScreen = .destination } },
                        onNext: { withAnimation { tripManager.currentScreen = .newRoute } }
                    )

                case .newRoute:
                    NewRouteView(showMenu: $showMenu) {
                        tripManager.resetForNewTrip()
                        withAnimation { tripManager.currentScreen = .welcome }
                    }

                case .history:
                    TripHistoryView(showMenu: $showMenu) {
                        withAnimation { tripManager.currentScreen = .welcome }
                    }

                case .vehicle:
                    VehicleInfoView(showMenu: $showMenu) {
                        withAnimation { tripManager.currentScreen = .welcome }
                    }
                }
            }
            .environmentObject(tripManager)

            // Side menu overlay
            if showMenu {
                SideMenuView(isPresented: $showMenu) { screen in
                    withAnimation { tripManager.currentScreen = screen }
                }
                .environmentObject(tripManager)
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showMenu)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
