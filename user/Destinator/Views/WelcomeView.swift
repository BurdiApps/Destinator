/*
 Destinator iOS — Screen 1: Welcome
 Shows the map and a "Scan Miles" button to begin a trip.
*/

import SwiftUI
import MapKit
import CoreLocation

struct WelcomeView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onNext: () -> Void

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.8260, longitude: -111.7897),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack(spacing: 0) {
            NavBarView(
                onClose: { /* no-op on first screen */ },
                onMenu: { showMenu = true }
            )

            VStack(spacing: 16) {
                Text("Welcome")
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

                ActionButton(label: "Scan Miles") {
                    tripManager.startTrip()
                    onNext()
                }
                .padding(.bottom, 16)
            }

            // Bottom pink bar
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
