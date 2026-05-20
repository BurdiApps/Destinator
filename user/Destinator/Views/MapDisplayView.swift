/*
 Destinator iOS — Map Display View
 Shows an Apple MapKit map with rounded corners.
 Takes up the bulk of each screen per the wireframe layout.
*/

import SwiftUI
import MapKit

struct MapDisplayView: View {
    @Binding var region: MKCoordinateRegion
    var annotations: [MapAnnotationItem]

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { item in
            MapMarker(coordinate: item.coordinate, tint: AppTheme.accentPurple)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
