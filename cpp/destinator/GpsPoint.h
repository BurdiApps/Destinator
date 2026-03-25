#pragma once

class GpsPoint {
public:
    double latitude, longitude;
    int timestamp;

    GpsPoint(double lat, double lon, int time = 0)
        : latitude(lat), longitude(lon), timestamp(time) {}
};
