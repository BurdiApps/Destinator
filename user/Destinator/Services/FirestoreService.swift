/*
 Destinator iOS — Firestore Service
 Handles CRUD operations against the same Firestore collections
 used by the admin Flask dashboard.
 Collections: 'drivers', 'trips'
*/

import Foundation
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Trips

    /// Save a completed trip to Firestore 'trips' collection
    func saveTrip(_ trip: Trip, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let ref = try db.collection("trips").addDocument(from: trip)
            completion(.success(ref.documentID))
        } catch {
            completion(.failure(error))
        }
    }

    /// Fetch trips for a specific driver
    func fetchTrips(driverId: String, completion: @escaping (Result<[Trip], Error>) -> Void) {
        db.collection("trips")
            .whereField("driver_id", isEqualTo: driverId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let trips = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Trip.self)
                } ?? []
                completion(.success(trips))
            }
    }

    /// Fetch all trips (no filter)
    func fetchAllTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        db.collection("trips")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let trips = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Trip.self)
                } ?? []
                completion(.success(trips))
            }
    }

    // MARK: - Drivers

    /// Fetch a single driver by document ID
    func fetchDriver(id: String, completion: @escaping (Result<Driver, Error>) -> Void) {
        db.collection("drivers").document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists,
                  let driver = try? snapshot.data(as: Driver.self) else {
                completion(.failure(NSError(
                    domain: "Destinator",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Driver not found"]
                )))
                return
            }
            completion(.success(driver))
        }
    }

    /// Fetch all drivers
    func fetchDrivers(completion: @escaping (Result<[Driver], Error>) -> Void) {
        db.collection("drivers").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let drivers = snapshot?.documents.compactMap { doc in
                try? doc.data(as: Driver.self)
            } ?? []
            completion(.success(drivers))
        }
    }
}
