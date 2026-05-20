/*
 Destinator iOS — Trip History View
 Shows a list of completed trips from the current session + Firestore.
*/

import SwiftUI

struct TripHistoryView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var showMenu: Bool
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavBarView(
                onClose: onBack,
                onMenu: { showMenu = true }
            )

            VStack(spacing: 12) {
                Text("Trip History")
                    .font(.title.bold())
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if tripManager.completedTrips.isEmpty {
                    Spacer()
                    Text("No trips logged yet.\nStart a new trip from the Welcome screen.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                } else {
                    List(tripManager.completedTrips) { trip in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(trip.fromLocation) → \(trip.toLocation)")
                                    .font(.headline)
                                Spacer()
                                Text(trip.criteria)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(criteriaColor(trip.criteria).opacity(0.2))
                                    .foregroundColor(criteriaColor(trip.criteria))
                                    .clipShape(Capsule())
                            }
                            Text("\(trip.date) | \(String(format: "%.1f mi", trip.gpsMiles))")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }

            Rectangle()
                .fill(AppTheme.backgroundPink)
                .frame(height: 40)
        }
        .background(AppTheme.screenBackground)
    }

    private func criteriaColor(_ criteria: String) -> Color {
        switch criteria {
        case "JUST RIGHT": return .green
        case "OVER": return .red
        case "UNDER": return .orange
        default: return .gray
        }
    }
}
