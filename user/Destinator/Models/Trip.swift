/*
 Destinator iOS — Trip Model
 Mirrors the Firestore 'trips' collection from the admin dashboard.
*/

import Foundation
import FirebaseFirestore

struct Trip: Identifiable, Codable {
    @DocumentID var id: String?
    var driverId: String
    var fromLocation: String
    var toLocation: String
    var odoStart: Double
    var odoEnd: Double
    var odoMiles: Double
    var gpsMiles: Double
    var criteria: String          // "JUST RIGHT", "OVER", "UNDER"
    var date: String              // "MM-dd-yyyy"
    var startTime: String         // "HH:mm:ss"
    var endTime: String
    var explanation: String

    enum CodingKeys: String, CodingKey {
        case id
        case driverId   = "driver_id"
        case fromLocation = "from_location"
        case toLocation = "to_location"
        case odoStart   = "odo_start"
        case odoEnd     = "odo_end"
        case odoMiles   = "odo_miles"
        case gpsMiles   = "gps_miles"
        case criteria
        case date
        case startTime  = "start_time"
        case endTime    = "end_time"
        case explanation
    }
}
