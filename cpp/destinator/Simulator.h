#pragma once
#include <vector>
#include "GpsPoint.h"

class Simulator {
public:
    static std::vector<GpsPoint> generateReadings(
        double startLat, double startLon,
        double endLat, double endLon,
        int numPoints, int intervalSeconds
    );
};
