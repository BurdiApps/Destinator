/*
 Destinator iOS — Action Button
 Purple circle with "+" icon and a label below.
 Matches the wireframe FAB-style buttons.
*/

import SwiftUI

struct ActionButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.accentPurple)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.accentPurple.opacity(0.4), radius: 6, x: 0, y: 3)
            }

            Text(label)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
