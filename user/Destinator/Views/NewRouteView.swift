/*
 Destinator iOS — Screen 4: New Route?
 After confirming arrival, offer to start another trip or go home.
*/

import SwiftUI
import MapKit

struct NewRouteView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onNewRoute: () -> Void

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.8260, longitude: -111.7897),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack(spacing: 0) {
            NavBarView(
                onClose: { /* stays on this screen */ },
                onMenu: { showMenu = true }
            )

            VStack(spacing: 16) {
                Text("New Route?")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                MapDisplayView(
                    region: $region,
                    annotations: tripManager.currentAnnotations
                )
                .frame(maxHeight: .infinity)

                // Trip history count
                if !tripManager.completedTrips.isEmpty {
                    Text("\(tripManager.completedTrips.count) trip(s) logged today")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                ActionButton(label: "New Route?") {
                    tripManager.resetForNewTrip()
                    onNewRoute()
                }
                .padding(.bottom, 16)
            }

            Rectangle()
                .fill(AppTheme.backgroundPink)
                .frame(height: 40)
        }
        .background(AppTheme.screenBackground)
        .onAppear {
            if let loc = tripManager.currentLocation {
                region.center = loc
            }
        }
    }
}
