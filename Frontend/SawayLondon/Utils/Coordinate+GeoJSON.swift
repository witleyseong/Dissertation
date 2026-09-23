//
//  Coordinate+GeoJSON.swift
//  SafeWay London
//

import CoreLocation

extension Array where Element == Double {
    /// Convert [lng, lat] array to CLLocationCoordinate2D
    ///  Backend returns [longitude, latitude] but CoreLocation/MapKit use (latitude, longitude)
    var asCoordinate: CLLocationCoordinate2D? {
        guard count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: self[1], longitude: self[0])
    }
}

extension CLLocationCoordinate2D {
    /// Convert coordinate to [lng, lat] for backend
    var asGeoJSONArray: [Double] {
        [longitude, latitude]
    }
    
    /// Haversine distance to another coordinate (in meters)
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let earthRadius: Double = 6371000 // meters
        
        let lat1 = latitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let deltaLat = (coordinate.latitude - latitude) * .pi / 180
        let deltaLon = (coordinate.longitude - longitude) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}
