#pragma once
#include <vector>
#include <string>
#include "GpsPoint.h"

class Trip {
public:
    std::string id;
    std::vector<GpsPoint> points;
    double totalMiles = 0.0;

    Trip(const std::string& tid) : id(tid) {}

    void addPoint(const GpsPoint& pt) { points.push_back(pt); }
    void calculateMileage();
    void displaySummary();
    void exportToFile(const std::string& filename);
};
