/*
 Destinator iOS — Driver Model
 Mirrors the Firestore 'drivers' collection.
*/

import Foundation
import FirebaseFirestore

struct Driver: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var vehicle: String
}
