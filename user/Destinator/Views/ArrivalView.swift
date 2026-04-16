/*
 Destinator iOS — Screen 3: You have arrived!
 Shows arrival confirmation with trip summary. "Confirm Arrival" logs the trip.
*/

import SwiftUI
import MapKit

struct ArrivalView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onBack: () -> Void
    var onNext: () -> Void

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
                Text("You have arrived!")
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

                // Trip summary card
                if let miles = tripManager.currentMiles {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f miles traveled", miles))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(tripManager.destinationName)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                ActionButton(label: "Confirm Arrival") {
                    tripManager.confirmArrival()
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
            if let loc = tripManager.destinationLocation {
                region.center = loc
            }
        }
    }
}
