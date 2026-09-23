//
//  MapDetailView.swift
//  SafeWay London
//

import SwiftUI
import MapKit

struct MapDetailView: View {
    let journey: Journey

    @Environment(\.dismiss) private var dismiss
    @Environment(UserLocationManager.self) private var locationManager
    @State private var position: MapCameraPosition = .automatic
    @State private var showingActiveNavigation = false
    @State private var selectedLegIndex: Int?
    
    // Calculate route polyline coordinates
    private var routeCoordinates: [CLLocationCoordinate2D] {
        Array(journey.legs.enumerated()).flatMap { index, leg in
            mapPath(for: leg, at: index)
        }
    }

    /// Coordinates to draw for a leg. Some transfer walks come without a lineString,
    /// so draw a line from the end of the previous leg to the start of the next one.
    private func mapPath(for leg: Leg, at index: Int) -> [CLLocationCoordinate2D] {
        if leg.path.count >= 2 {
            return leg.path
        }

        let previousLeg = index > 0 ? journey.legs[index - 1] : nil
        let nextLeg = index < journey.legs.count - 1 ? journey.legs[index + 1] : nil

        guard let start = leg.departureCoordinate ?? previousLeg?.arrivalCoordinate,
              let end = leg.arrivalCoordinate ?? nextLeg?.departureCoordinate else {
            return []
        }

        if let midpoint = leg.midpointCoordinate {
            return [start, midpoint, end]
        }
        return [start, end]
    }
    
    // Calculate map region to show entire route
    private var routeRegion: MKCoordinateRegion {
        guard !routeCoordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let lats = routeCoordinates.map { $0.latitude }
        let lons = routeCoordinates.map { $0.longitude }
        
        let minLat = lats.min() ?? 51.5
        let maxLat = lats.max() ?? 51.6
        let minLon = lons.min() ?? -0.2
        let maxLon = lons.max() ?? -0.1
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3, // Add 30% padding
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map showing the route
            Map(position: $position) {
                // User location
                if let userLocation = locationManager.userLocation {
                    Annotation("Your Location", coordinate: userLocation.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(.blue)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                
                // One polyline per leg. Transit is drawn first and walking on top, so short
                // transfer walks don't get hidden by the transit line.
                ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                    let legPath = mapPath(for: leg, at: index)
                    if !legPath.isEmpty && !leg.isWalking {
                        if leg.modeId == "bus" {
                            // Bus: solid red line
                            MapPolyline(coordinates: legPath)
                                .stroke(.red, lineWidth: 4)
                        } else if leg.modeId == "tube" {
                            // Tube: use official line color
                            MapPolyline(coordinates: legPath)
                                .stroke(leg.tubeLineColor, lineWidth: 4)
                        } else {
                            // Other: blue
                            MapPolyline(coordinates: legPath)
                                .stroke(.blue, lineWidth: 4)
                        }
                    }
                }

                ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                    let legPath = mapPath(for: leg, at: index)
                    if !legPath.isEmpty && leg.isWalking {
                        // Walking: dashed line, coloured by crime exposure (green/orange/red)
                        let exposureColor = leg.exposureBand?.color ?? .green
                        MapPolyline(coordinates: legPath)
                            .stroke(exposureColor, style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                    }
                }
                
                // Leg markers (start/end points and transfers)
                ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                    if let start = leg.departureCoordinate {
                        Annotation(leg.from, coordinate: start) {
                            LegMarker(
                                icon: index == 0 ? "circle.fill" : "arrow.triangle.swap",
                                color: index == 0 ? .green : .orange,
                                isSelected: selectedLegIndex == index
                            )
                            .onTapGesture {
                                selectedLegIndex = index
                            }
                        }
                    }
                    
                    // Final destination
                    if index == journey.legs.count - 1, let end = leg.arrivalCoordinate {
                        Annotation(leg.to, coordinate: end) {
                            LegMarker(
                                icon: "mappin.circle.fill",
                                color: .red,
                                isSelected: false
                            )
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls { } // Hide default top-right controls; we place our own below
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                CloseMapButton { dismiss() }
                    .padding(.leading, 16)
                    .padding(.top, 8)
            }
            .overlay(alignment: .bottomTrailing) {
                LocateMeButton { centerOnUserLocation() }
                    .padding(.trailing, 16)
                    .padding(.bottom, 416) // Sits just above the journey details sheet
            }

            // Bottom sheet with journey details
            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Journey summary
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(journey.duration.formatDuration())
                                    .font(.title.bold())
                                
                                Text("\(journey.departureTime) - \(journey.arrivalTime)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                if journey.numChanges > 0 {
                                    Label("\(journey.numChanges) change\(journey.numChanges == 1 ? "" : "s")", systemImage: "arrow.triangle.swap")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Label("Direct", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                
                                Spacer()
                                
                                if let fareDisplay = journey.fareDisplay {
                                    Text(fareDisplay)
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Step-by-step instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Directions")
                                .font(.headline)
                            
                            ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                                LegInstructionRow(
                                    leg: leg,
                                    index: index,
                                    isSelected: selectedLegIndex == index
                                )
                                .onTapGesture {
                                    selectedLegIndex = index
                                    // Zoom to this leg
                                    if let coord = leg.departureCoordinate {
                                        position = .region(
                                            MKCoordinateRegion(
                                                center: coord,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            )
                                        )
                                    }
                                }
                            }
                        }

                        // Crime breakdown by category, straight from the backend
                        CrimeBreakdownSection(crimeBreakdown: journey.crimeBreakdown)

                        // Start navigation button
                        Button {
                            showingActiveNavigation = true
                        } label: {
                            Label("Start Navigation", systemImage: "location.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .frame(maxHeight: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestPermission()
            position = .region(routeRegion)
        }
        .fullScreenCover(isPresented: $showingActiveNavigation) {
            ActiveNavigationView(
                journey: journey,
                locationManager: locationManager
            )
        }
    }

    private func centerOnUserLocation() {
        guard let userLocation = locationManager.userLocation else { return }
        withAnimation {
            position = .region(
                MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
}

/// Crime categories for the walking parts of this journey (from the backend's crimeBreakdown).
/// Sorted by count. If there is no data it shows a message instead of hiding the section.
struct CrimeBreakdownSection: View {
    let crimeBreakdown: [String: Int]

    private var sortedCategories: [(category: String, count: Int)] {
        crimeBreakdown
            .map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crime breakdown")
                .font(.headline)

            if sortedCategories.isEmpty {
                Text("Crime breakdown unavailable for this route.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedCategories, id: \.category) { item in
                        HStack(alignment: .top) {
                            Text(item.category)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 12)

                            Text("\(item.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.category): \(item.count) historical police-recorded incidents near walking sections")

                        if item.category != sortedCategories.last?.category {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            Text("Historical police-recorded incidents near walking sections. This does not predict crime or guarantee personal safety.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct CloseMapButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

struct LocateMeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

struct LegMarker: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isSelected ? 0.3 : 0.1))
                .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
            
            Circle()
                .fill(color)
                .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
            
            Image(systemName: icon)
                .font(.system(size: isSelected ? 12 : 10))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct LegInstructionRow: View {
    let leg: Leg
    let index: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill((leg.isWalking ? (leg.exposureBand?.color ?? .green) : .blue).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: leg.iconName)
                    .font(.subheadline)
                    .foregroundStyle(leg.isWalking ? (leg.exposureBand?.color ?? .green) : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Instruction
                if leg.isWalking {
                    Text("Walk \(leg.duration) min")
                        .font(.subheadline.bold())

                    Text("to \(leg.to)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Crime exposure for this walking segment, straight from the backend
                    if let exposurePerKm = leg.exposurePerKm {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f crimes/km", exposurePerKm))
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(leg.exposureBand?.color ?? .secondary)
                    }
                } else {
                    HStack {
                        if let routeName = leg.routeName {
                            Text(routeName)
                                .font(.subheadline.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                        
                        Text("for \(leg.duration) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("to \(leg.to)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Distance
                if let distance = leg.distanceKm {
                    Text(String(format: "%.1f km", distance))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Duration badge
            Text("\(leg.duration)m")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
    }
}
