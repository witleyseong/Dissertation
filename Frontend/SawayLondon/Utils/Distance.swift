//
//  Distance.swift
//  SafeWay London
//

import Foundation

extension Double {
    /// Format distance in meters to human-readable string
    func formatDistance() -> String {
        if self >= 1000 {
            return String(format: "%.1f km", self / 1000)
        } else {
            return String(format: "%.0f m", self)
        }
    }
}

extension Int {
    /// Format duration in minutes to human-readable string
    func formatDuration() -> String {
        if self >= 60 {
            let hours = self / 60
            let mins = self % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        } else {
            return "\(self)m"
        }
    }
}
