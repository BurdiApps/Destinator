# Destinator iOS — Driver Trip Tracker

SwiftUI iOS app for the Destinator GPS trip-logging system. This is the **driver-facing** companion to the Flask admin dashboard. Trips logged here sync to the same Firestore database the admin panel reads.

## Screens (from wireframes)

| # | Screen | Action Button | Purpose |
|---|--------|---------------|---------|
| 1 | Welcome | Scan Miles | Start odometer reading, begin trip |
| 2 | What's Your Destination? | Send ETA | Enter destination, calculate ETA |
| 3 | You have arrived! | Confirm Arrival | Log trip to Firestore |
| 4 | New Route? | New Route? | Reset and start another trip |

## Xcode Setup (on your Mac)

### 1. Create the Xcode project

1. Open **Xcode** → File → New → Project
2. Choose **iOS → App**
3. Settings:
   - Product Name: `Destinator`
   - Team: your Apple ID
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
4. Save it **inside** `Destinator/user/` (replace the generated files)

### 2. Add the source files

Copy/move all `.swift` files from this repo's `user/Destinator/` folder into the Xcode project's source group. The folder structure:

```
Destinator/
├── DestinatoriOSApp.swift      # App entry point (replace the generated one)
├── ContentView.swift            # Navigation controller
├── Theme.swift                  # Pink/purple color scheme
├── Models/
│   ├── Trip.swift               # Trip data model (matches Firestore)
│   └── Driver.swift             # Driver data model
├── Views/
│   ├── WelcomeView.swift        # Screen 1
│   ├── DestinationView.swift    # Screen 2
│   ├── ArrivalView.swift        # Screen 3
│   ├── NewRouteView.swift       # Screen 4
│   ├── TripHistoryView.swift    # Side menu → history
│   ├── VehicleInfoView.swift    # Side menu → vehicle
│   ├── SideMenuView.swift       # Hamburger menu overlay
│   ├── NavBarView.swift         # Custom X + ≡ nav bar
│   ├── MapDisplayView.swift     # MapKit map component
│   └── ActionButton.swift       # Purple FAB button
└── Services/
    ├── TripManager.swift        # Central state / trip flow logic
    ├── FirestoreService.swift   # Firestore CRUD
    └── LocationService.swift    # CoreLocation GPS tracking
```

### 3. Add Firebase SDK via Swift Package Manager

1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: **Up to Next Major** (11.x)
4. Add these libraries:
   - `FirebaseCore`
   - `FirebaseFirestore`

### 4. Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/) → your Destinator project
2. Add an **iOS app** (bundle ID: `com.yourname.Destinator`)
3. Download `GoogleService-Info.plist`
4. Drag it into the Xcode project root (check "Copy items if needed")

### 5. Enable Location in Info.plist

Add these keys to Info.plist (Xcode → target → Info tab):

```
NSLocationWhenInUseUsageDescription = "Destinator needs your location to track trip miles."
```

### 6. Build & Run

- Select an **iPhone 14/15 Pro** simulator (or your device)
- Press **⌘R** to build and run

## Firestore Collections (shared with admin)

| Collection | Used By |
|------------|---------|
| `drivers` | Read driver/vehicle info |
| `trips` | Read history + write new trips |
| `users` | Admin-only (not used by iOS app) |

## Tech Stack

- **SwiftUI** — declarative UI
- **MapKit** — Apple Maps display
- **CoreLocation** — GPS tracking
- **Firebase/Firestore** — cloud database (same as admin)
- **iOS 16+** target
