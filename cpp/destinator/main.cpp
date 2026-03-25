#include <iostream>
#include <vector>
#include <string>
#include <ctime>
#include <iomanip>
#include <fstream>
#include "GpsPoint.h"
#include "Trip.h"
#include "Simulator.h"

struct Location {
    std::string name;
    double latitude;
    double longitude;
};

std::string getCurrentTime() {
    time_t t = time(nullptr);
    tm *lt = localtime(&t);
    char buf[20];
    strftime(buf, sizeof(buf), "%m-%d-%Y %H:%M:%S", lt);
    return std::string(buf);
}

int getLocationSelection(const std::vector<Location>& locations, const std::string& prompt, int skip = -1) {
    int idx = -1;
    std::cout << prompt << std::endl;
    for (size_t i = 0; i < locations.size(); ++i) {
        if ((int)i == skip) continue;
        std::cout << i << ": " << locations[i].name << " (" <<
            locations[i].latitude << ", " << locations[i].longitude << ")\n";
    }
    while (true) {
        std::cout << "Enter a location: ";
        std::cin >> idx;
        if (idx >= 0 && idx < (int)locations.size() && idx != skip) break;
        std::cout << "Invalid choice. Try again." << std::endl;
    }
    return idx;
}

std::string compareMiles(double gpsMiles, double odoMiles) {
    double delta = gpsMiles - odoMiles;
    double threshold = 0.25; // 0.25 miles is 'just right'
    if (delta < -threshold) return "UNDER";
    if (delta > threshold)  return "OVER";
    return "JUST RIGHT";
}

int main() {
    std::srand(static_cast<unsigned int>(std::time(nullptr)));

    std::vector<Location> places = {
        {"Home",      35.3730, -119.0187 },
        {"Daycare 1", 35.3800, -119.0120 },
        {"Daycare 2", 35.3570, -119.0500 },
        {"Work",      35.4000, -119.0220 },
        {"Store",     35.3390, -119.0290 },
        {"Gas",       35.3650, -119.0400 }
    };

    // Get trip session info for all legs
    int month, day, year;
    std::cout << "\nTrip session date...\n";
    std::cout << "Month (MM): "; std::cin >> month;
    std::cout << "Day (DD): "; std::cin >> day;
    std::cout << "Year (YYYY): "; std::cin >> year;
    std::ostringstream dateStream;
    dateStream << std::setfill('0') << std::setw(2) << month << "-"
               << std::setw(2) << day << "-"
               << year;
    std::string date = dateStream.str();

    std::vector<std::string> csvRows;
    // CSV header row
    csvRows.push_back("From,To,Odo Start,Odo End,Odo Miles,GPS Miles,Criteria,Date,Start Time,End Time,Explanation");

    double sessionOdo = 0.0;
    bool firstTrip = true;
    int startIdx = -1;
    std::string lastEndTime;

    do {
        std::cout << "\n=== New Trip Segment ===\n";
        double odoStart, odoEnd;

        // Odometer logic: for first segment, prompt; for chained, use previous end or prompt
        if (firstTrip) {
            std::cout << "Enter STARTING odometer miles: ";
            std::cin >> odoStart;
            sessionOdo = odoStart;
            startIdx = getLocationSelection(places, "Select START location:");
        } else {
            odoStart = sessionOdo;
            std::cout << "Current odometer = " << odoStart << "\n";
            startIdx = getLocationSelection(places, "Select START location for segment:");
        }

        int endIdx = getLocationSelection(places, "Select END location (must differ):", startIdx);

        std::cout << "Enter ENDING odometer miles: ";
        std::cin >> odoEnd;
        sessionOdo = odoEnd; // for next segment

        // Start/end times
        std::string startTime = getCurrentTime();
        // Simulate trip segment, then take end time
        Trip trip(places[startIdx].name + " to " + places[endIdx].name + " " + date);
        auto points = Simulator::generateReadings(
            places[startIdx].latitude, places[startIdx].longitude,
            places[endIdx].latitude, places[endIdx].longitude,
            10, 60
        );
        for (const auto& pt : points) trip.addPoint(pt);
        trip.calculateMileage();
        std::string endTime = getCurrentTime();
        lastEndTime = endTime;

        // Calculate results/criteria
        double odoMiles = odoEnd - odoStart;
        std::string criteria = compareMiles(trip.totalMiles, odoMiles);

        std::string explanation;
        std::cin.ignore(); // Remove newline if any before std::getline
        if (criteria != "JUST RIGHT") {
            std::cout << "Miles are " << criteria << " (GPS: " << std::fixed << std::setprecision(2)
                      << trip.totalMiles << " vs Odo: " << odoMiles << ")\n";
            std::cout << "Reason for being " << criteria << "? (e.g., detour, delay, etc.): ";
            std::getline(std::cin, explanation);
        } else {
            explanation = "On track";
        }

        // Save row to CSV rows vector
        std::ostringstream row;
        row << places[startIdx].name << "," << places[endIdx].name << ","
            << odoStart << "," << odoEnd << "," << odoMiles << ","
            << std::fixed << std::setprecision(2) << trip.totalMiles << "," << criteria << ","
            << date << "," << startTime << "," << endTime << ","
            << "\"" << explanation << "\"";
        csvRows.push_back(row.str());

        // Prepare for next leg
        firstTrip = false;
        startIdx = endIdx;  // next leg starts where last one ended

        // Ask if user is done
        std::cout << "\nAdd another trip segment? (y/n): ";
        char again;
        std::cin >> again;
        if (again != 'y' && again != 'Y') break;

    } while (true);

    // At end, export all rows together
    std::ofstream file("trip_data.csv");
    for (const auto& row : csvRows) file << row << "\n";
    file.close();

    std::cout << "\nComplete log (" << csvRows.size()-1 << " segment(s)) exported to trip_data.csv!\n";
    return 0;
}
