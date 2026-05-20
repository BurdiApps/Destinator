/*
 Destinator iOS — Screen 2: What's Your Destination?
 User enters destination, map shows route preview, "Send ETA" starts navigation.
*/

import SwiftUI
import MapKit

struct DestinationView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var destination = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.8260, longitude: -111.7897),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        VStack(spacing: 0) {
            NavBarView(
                onClose: onBack,
                onMenu: { showMenu = true }
            )

            VStack(spacing: 16) {
                Text("What's Your Destination?")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Destination text field
                TextField("Enter address or place name", text: $destination)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)

                MapDisplayView(
                    region: $region,
                    annotations: tripManager.currentAnnotations
                )
                .frame(maxHeight: .infinity)

                ActionButton(label: "Send ETA") {
                    tripManager.setDestination(destination)
                    onNext()
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
