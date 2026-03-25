#include "Trip.h"
#include <iostream>
#include <fstream>
#include <cmath>

static double haversine(double lat1, double lon1, double lat2, double lon2) {
    // Earth radius in miles
    const double R = 3958.8;
    const double toRad = M_PI / 180.0;
    double dLat = (lat2 - lat1) * toRad;
    double dLon = (lon2 - lon1) * toRad;
    double a = sin(dLat/2) * sin(dLat/2) +
               cos(lat1 * toRad) * cos(lat2 * toRad) *
               sin(dLon/2) * sin(dLon/2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
}

void Trip::calculateMileage() {
    double miles = 0.0;
    for (size_t i = 1; i < points.size(); ++i) {
        miles += haversine(points[i-1].latitude, points[i-1].longitude,
                           points[i].latitude, points[i].longitude);
    }
    totalMiles = miles;
}

void Trip::displaySummary() {
    std::cout << "Trip: " << id << "\n"
              << "Waypoints: " << points.size() << "\n"
              << "Miles: " << totalMiles << std::endl;
}

void Trip::exportToFile(const std::string& filename) {
    std::ofstream file(filename);
    file << "lat,lon,timestamp\n";
    for (const auto& pt : points)
        file << pt.latitude << "," << pt.longitude << "," << pt.timestamp << "\n";
    file.close();
}
