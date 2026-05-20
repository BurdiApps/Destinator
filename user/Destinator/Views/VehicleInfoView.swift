/*
 Destinator iOS — Vehicle Info View
 Displays current driver/vehicle info.
*/

import SwiftUI

struct VehicleInfoView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavBarView(
                onClose: onBack,
                onMenu: { showMenu = true }
            )

            VStack(spacing: 20) {
                Text("Vehicle Info")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                VStack(spacing: 16) {
                    infoRow(label: "Driver", value: tripManager.driverName)
                    infoRow(label: "Vehicle", value: tripManager.vehicleName)
                    infoRow(label: "Trips Today", value: "\(tripManager.completedTrips.count)")
                    if let miles = tripManager.totalMilesToday {
                        infoRow(label: "Miles Today", value: String(format: "%.1f mi", miles))
                    }
                }
                .padding(20)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer()
            }

            Rectangle()
                .fill(AppTheme.backgroundPink)
                .frame(height: 40)
        }
        .background(AppTheme.screenBackground)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
