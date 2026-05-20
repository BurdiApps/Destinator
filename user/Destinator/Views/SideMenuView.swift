/*
 Destinator iOS — Side Menu
 Slides in from the right when the hamburger (≡) is tapped.
 Provides navigation to trip history and settings.
*/

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var tripManager: TripManager
    @Binding var isPresented: Bool
    var onNavigate: (AppScreen) -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Menu panel
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Destinator")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(tripManager.driverName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.accentPurple)

                // Menu items
                VStack(alignment: .leading, spacing: 0) {
                    menuItem(icon: "location.fill", title: "New Trip") {
                        onNavigate(.welcome)
                        isPresented = false
                    }

                    menuItem(icon: "clock.fill", title: "Trip History") {
                        onNavigate(.history)
                        isPresented = false
                    }

                    menuItem(icon: "car.fill", title: "Vehicle Info") {
                        onNavigate(.vehicle)
                        isPresented = false
                    }

                    Divider().padding(.vertical, 8)

                    menuItem(icon: "gearshape.fill", title: "Settings") {
                        // placeholder
                        isPresented = false
                    }
                }
                .padding(.top, 12)

                Spacer()

                // Version
                Text("v1.0.0 — CSE 310")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(24)
            }
            .frame(width: 280)
            .background(AppTheme.screenBackground)
        }
    }

    private func menuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accentPurple)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
