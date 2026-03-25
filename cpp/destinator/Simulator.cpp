#include "Simulator.h"

std::vector<GpsPoint> Simulator::generateReadings(
    double startLat, double startLon, double endLat, double endLon,
    int numPoints, int intervalSeconds)
{
    std::vector<GpsPoint> points;
    for (int i = 0; i < numPoints; ++i) {
        double frac = (numPoints > 1) ? static_cast<double>(i) / (numPoints - 1) : 0.0;
        double lat = startLat + (endLat - startLat) * frac;
        double lon = startLon + (endLon - startLon) * frac;
        int timestamp = i * intervalSeconds;
        points.emplace_back(lat, lon, timestamp);
    }
    return points;
}
