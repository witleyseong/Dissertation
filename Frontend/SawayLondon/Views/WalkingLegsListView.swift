//
//  WalkingLegsListView.swift
//  SafeWay London
//

import SwiftUI

struct WalkingLegsListView: View {
    let journey: Journey
    
    var body: some View {
        List {
            Section {
                ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Icon for mode
                            Image(systemName: leg.iconName)
                                .foregroundStyle(leg.isWalking ? .green : .blue)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Main instruction
                                if leg.isWalking {
                                    Text("Walk \(leg.duration) min")
                                        .font(.headline)
                                } else if leg.modeId == "bus", let route = leg.routeName {
                                    Text("Take Bus \(route)")
                                        .font(.headline)
                                } else if leg.modeId == "tube", let route = leg.routeName {
                                    Text("Take \(route) line")
                                        .font(.headline)
                                } else {
                                    Text(leg.routeName ?? leg.mode.capitalized)
                                        .font(.headline)
                                }
                                
                                // Details
                                HStack(spacing: 12) {
                                    Label("\(leg.duration) min", systemImage: "clock")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    if !leg.isWalking {
                                        Label(leg.distanceMeters.formatDistance(), systemImage: "arrow.forward")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Label(leg.distanceMeters.formatDistance(), systemImage: "figure.walk")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Risk badge for walking
                            if let band = leg.exposureBand {
                                Text(band.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(band.color.opacity(0.2))
                                    .foregroundStyle(band.color)
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Crime info for walking
                        if leg.isWalking, let crimeCount = leg.crimeCount {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(crimeCount) pedestrian-relevant crimes nearby")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 36)
                                
                                // Add contextual info for high counts
                                if crimeCount > 500 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                        
                                        Text("May include high-traffic public location")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding(.leading, 36)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Step by step directions")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Crime data based on historical records from UK Police")
                        .font(.caption2)
                    
                    Text("Data is anonymised to public locations. High counts may indicate busy public areas where crime data is concentrated.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Summary") {
                LabeledContent("Total walking", value: journey.totalWalkingDistanceMeters.formatDistance())
                LabeledContent("Segments", value: "\(journey.walkingSegments)")
                // only the exposurePerKm from the backend is shown, never one calculated in the app
                LabeledContent(
                    "Exposure/km",
                    value: journey.exposurePerKm.map { String(format: "%.1f", $0) } ?? "Exposure information unavailable"
                )
                LabeledContent("Total duration", value: journey.duration.formatDuration())
            }
        }
        .navigationTitle("Route Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WalkingLegsListView(
            journey: Journey(
                id: "1",
                duration: 45,
                departureTime: "10:00",
                arrivalTime: "10:45",
                numChanges: 2,
                safetyScore: nil,
                exposureScore: nil,
                exposureLevel: "moderate",
                isFastest: false,
                isLowestExposure: false,
                totalCrimeExposure: 25,
                totalWalkingKm: nil,
                exposurePerKm: nil,
                fare: 2.80,
                crimeBreakdown: [:],
                legs: []
            )
        )
    }
}
