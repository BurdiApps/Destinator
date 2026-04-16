/*
 Destinator iOS — Trip Manager
 Central state management for the trip workflow.
 Coordinates between screens, GPS, and Firestore.
*/

import Foundation
import CoreLocation
import SwiftUI
import MapKit

/// Screens the app can display
enum AppScreen {
    case welcome
    case destination
    case arrival
    case newRoute
    case history
    case vehicle
}

class TripManager: ObservableObject {
    // MARK: - Published state
    @Published var currentScreen: AppScreen = .welcome
    @Published var completedTrips: [Trip] = []
    @Published var driverName: String = "James Burdick"
    @Published var vehicleName: String = "2019 Honda Civic"
    @Published var driverId: String = "driver_default"

    // Current trip state
    @Published var destinationName: String = ""
    @Published var originName: String = "Current Location"
    @Published var currentMiles: Double?
    @Published var currentAnnotations: [MapAnnotationItem] = []

    // Services
    let locationService = LocationService()
    let firestoreService = FirestoreService()

    // Internal trip tracking
    private var tripStartTime: Date?
    private var tripStartLocation: CLLocationCoordinate2D?
    private var tripOdoStart: Double = 0

    // MARK: - Computed

    var currentLocation: CLLocationCoordinate2D? {
        locationService.currentLocation
    }

    var destinationLocation: CLLocationCoordinate2D? {
        // For now return current location; geocoding can be added later
        currentLocation
    }

    var totalMilesToday: Double? {
        let sum = completedTrips.reduce(0.0) { $0 + $1.gpsMiles }
        return sum > 0 ? sum : nil
    }

    // MARK: - Lifecycle

    init() {
        locationService.requestPermission()
        loadTripsFromFirestore()
    }

    // MARK: - Trip Flow

    func startTrip() {
        tripStartTime = Date()
        tripStartLocation = currentLocation
        tripOdoStart = completedTrips.last.map { $0.odoEnd } ?? 0
        locationService.startTracking()

        if let loc = currentLocation {
            currentAnnotations = [MapAnnotationItem(coordinate: loc)]
        }
    }

    func setDestination(_ name: String) {
        destinationName = name.isEmpty ? "Unknown" : name
    }

    func confirmArrival() {
        let endTime = Date()
        let gpsMiles: Double
        if let start = tripStartLocation, let end = currentLocation {
            gpsMiles = LocationService.distanceInMiles(from: start, to: end)
        } else {
            gpsMiles = 0
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let dateStr = formatter.string(from: endTime)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        let odoEnd = tripOdoStart + gpsMiles
        let odoMiles = odoEnd - tripOdoStart

        // Criteria logic matching the C++ simulator
        let diff = abs(odoMiles - gpsMiles)
        let criteria: String
        if diff < 0.5 {
            criteria = "JUST RIGHT"
        } else if gpsMiles > odoMiles {
            criteria = "OVER"
        } else {
            criteria = "UNDER"
        }

        let trip = Trip(
            driverId: driverId,
            fromLocation: originName,
            toLocation: destinationName,
            odoStart: tripOdoStart,
            odoEnd: odoEnd,
            odoMiles: odoMiles,
            gpsMiles: gpsMiles,
            criteria: criteria,
            date: dateStr,
            startTime: timeFormatter.string(from: tripStartTime ?? endTime),
            endTime: timeFormatter.string(from: endTime),
            explanation: criteria == "JUST RIGHT" ? "On track" : "Route deviation detected"
        )

        completedTrips.append(trip)
        currentMiles = gpsMiles
        locationService.stopTracking()

        // Save to Firestore
        firestoreService.saveTrip(trip) { result in
            switch result {
            case .success(let docId):
                print("Trip saved: \(docId)")
            case .failure(let error):
                print("Failed to save trip: \(error.localizedDescription)")
            }
        }
    }

    func resetForNewTrip() {
        destinationName = ""
        originName = "Current Location"
        currentMiles = nil
        currentAnnotations = []
        tripStartTime = nil
        tripStartLocation = nil
    }

    // MARK: - Firestore

    private func loadTripsFromFirestore() {
        firestoreService.fetchTrips(driverId: driverId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let trips):
                    self?.completedTrips = trips
                case .failure(let error):
                    print("Failed to load trips: \(error.localizedDescription)")
                }
            }
        }
    }
}
