# Destinator

A C++ program to simulate modular GPS trip logging, with odometer comparison, CSV export, and realistic travel mileage calculation via the haversine formula. Built for CSE 310: Applied Programming.

---

## Features

- Record one or more trip segments (from any start to any end).
- Simulate GPS "waypoints" along each segment for realistic mileage.
- Calculate mileage using the haversine formula.
- Detect and prompt for explanation if GPS and odometer readings disagree ("OVER" or "UNDER").
- Export all trip data as a clear CSV with explanations.
- User-friendly CLI interface for demo and grading.

---

## Setup & Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/destinator.git
   cd destinator
   ```
2. Build the project with g++ (WSL/Linux):
   ```bash
   g++ -o destinator main.cpp Simulator.cpp Trip.cpp
   ```
   *(Add other .cpp files if present)*

---

## Usage

Run the program:
```bash
./destinator
```

You will be prompted for:
- Session date
- Odometer readings
- Start & end locations for each trip segment
- (If needed) Explanation for GPS/odometer mismatch

Example CSV output (`trip_log.csv`):

| From | To | Odo Start | Odo End | Odo Miles | GPS Miles | Criteria | Date | Start Time | End Time | Explanation |
|:----:|:--:|:---------:|:-------:|:---------:|:---------:|:--------:|:----:|:----------:|:--------:|:-----------:|
| Home | Store | 1200 | 1202 | 2.0 | 2.01 | JUST RIGHT | 03-28-2026 | 09:01:22 | 09:04:13 | On track |
| Store | Home | 1202 | 1204 | 2.0 | 1.96 | UNDER | 03-28-2026 | 10:00:00 | 10:03:10 | "Route was faster than expected" |

---

## File Structure

- **main.cpp:** Handles user interaction and session/trip logic.
- **Trip.cpp/h:** Stores trip data and handles distance calculation.
- **Simulator.cpp/h:** Generates simulated GPS waypoints for trips.
- **GpsPoint.h:** Defines simple GPS coordinate structure.

---

## Code Highlights

- **Waypoints:** Each trip segment includes several simulated GPS points (waypoints) to mimic real GPS data.
- **Haversine Formula:** Used to accurately compute distance between coordinates on Earth.
- **Modularity:** Handles multiple trip segments in one session, exporting all data clearly.

---

## Learning Notes & Strategies

- Practiced designing modular, real-world like C++ code (separating logic, simulation, and user interface).
- Learned and implemented the haversine formula for geospatial distance calculation.
- Simulated embedded GPS logic using C++ vectors and interpolation.
- Used CLI input validation and clear prompts for user experience.
- Took time after each main step to test inputs, outputs, and error scenarios.

---

## Time Log

| Date        | Hours | Activity                        |
|-------------|-------|---------------------------------|
| 03/18/2026  | 3     | Project setup, repo, initial code|
| 03/19/2026  | 4     | Main I/O, odometer logic        |
| 03/20/2026  | 5     | Waypoints & haversine math      |
| 03/21/2026  | 3     | CSV export & file testing       |
| 03/22/2026  | 2     | Codes comments & README         |
| 03/23/2026  | 3     | Demo preparation, video draft   |
| **Total**   | **20**|                                 |

---

## License

For educational use only. [James Burdick/BYU Idaho].

---

## Contact

Module #1 - Created by [James Burdick] 
Youtube Video - https://youtu.be/BPU_0eNh7_Q
