/*
 Destinator iOS — Custom Navigation Bar
 X button on the left, hamburger menu (≡) on the right.
 Matches the wireframe layout.
*/

import SwiftUI

struct NavBarView: View {
    var onClose: () -> Void
    var onMenu: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AppTheme.navIcon)
                    .padding(10)
            }

            Spacer()

            Button(action: onMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(AppTheme.navIcon)
                    .padding(10)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 50)
        .background(AppTheme.backgroundPink)
    }
}
