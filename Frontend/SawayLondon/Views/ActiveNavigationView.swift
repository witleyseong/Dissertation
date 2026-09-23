//
//  ActiveNavigationView.swift
//  SafeWay London
//

import SwiftUI
import MapKit

struct ActiveNavigationView: View {
    let journey: Journey
    let locationManager: UserLocationManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var currentLegIndex = 0
    @State private var showingLegsList = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    private var currentLeg: Leg? {
        guard currentLegIndex < journey.legs.count else { return nil }
        return journey.legs[currentLegIndex]
    }
    
    private var nextLeg: Leg? {
        guard currentLegIndex + 1 < journey.legs.count else { return nil }
        return journey.legs[currentLegIndex + 1]
    }
    
    private var remainingTime: Int {
        journey.legs[currentLegIndex...].reduce(0) { $0 + $1.duration }
    }
    
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

    var body: some View {
        ZStack(alignment: .top) {
            // Map with route
            Map(position: $mapCameraPosition) {
                // User location with heading indicator
                if let userLocation = locationManager.userLocation {
                    Annotation("", coordinate: userLocation.coordinate) {
                        UserLocationMarker(heading: locationManager.heading?.trueHeading ?? 0)
                    }
                }
                
                // Route polylines with proper colors and styles
                ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                    let legPath = mapPath(for: leg, at: index)
                    if !legPath.isEmpty {
                        let isPast = index < currentLegIndex
                        let isCurrent = index == currentLegIndex

                        if isPast {
                            // Past legs: gray
                            MapPolyline(coordinates: legPath)
                                .stroke(.gray.opacity(0.5), lineWidth: 3)
                        } else if leg.isWalking {
                            // Walking: dashed line, coloured by crime exposure (green/orange/red)
                            let exposureColor = leg.exposureBand?.color ?? .green
                            MapPolyline(coordinates: legPath)
                                .stroke(isCurrent ? exposureColor : exposureColor.opacity(0.7),
                                       style: StrokeStyle(lineWidth: isCurrent ? 4 : 3, dash: [5, 5]))
                        } else if leg.modeId == "bus" {
                            // Bus: solid red
                            MapPolyline(coordinates: legPath)
                                .stroke(isCurrent ? .red : .red.opacity(0.7),
                                       lineWidth: isCurrent ? 5 : 4)
                        } else if leg.modeId == "tube" {
                            // Tube: official line color
                            MapPolyline(coordinates: legPath)
                                .stroke(isCurrent ? leg.tubeLineColor : leg.tubeLineColor.opacity(0.7),
                                       lineWidth: isCurrent ? 5 : 4)
                        } else {
                            // Other: blue
                            MapPolyline(coordinates: legPath)
                                .stroke(isCurrent ? .blue : .blue.opacity(0.7),
                                       lineWidth: isCurrent ? 5 : 4)
                        }
                    }
                }
                
                // Next waypoint
                if let nextWaypoint = currentLeg?.arrivalCoordinate {
                    Annotation("", coordinate: nextWaypoint) {
                        WaypointMarker(isNext: true)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()
            
            // Top instruction card
            VStack(spacing: 0) {
                if let current = currentLeg {
                    InstructionCard(
                        leg: current,
                        nextLeg: nextLeg,
                        remainingTime: remainingTime,
                        onShowList: { showingLegsList = true }
                    )
                    .padding()
                    .shadow(radius: 10)
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 12) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<journey.legs.count, id: \.self) { index in
                            Capsule()
                                .fill(index < currentLegIndex ? .gray : (index == currentLegIndex ? .blue : .gray.opacity(0.3)))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        // End navigation button
                        Button {
                            dismiss()
                        } label: {
                            Label("End", systemImage: "xmark")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .foregroundStyle(.red)
                        
                        // Next step button (for testing - in real app this would be automatic)
                        if currentLegIndex < journey.legs.count - 1 {
                            Button {
                                withAnimation {
                                    currentLegIndex += 1
                                }
                            } label: {
                                Label("Next Step", systemImage: "arrow.right")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button {
                                dismiss()
                            } label: {
                                Label("Arrive", systemImage: "checkmark")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.green)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            updateCameraPosition()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            updateCameraPosition()
        }
        .onChange(of: currentLegIndex) { _, _ in
            updateCameraPosition()
        }
        .sheet(isPresented: $showingLegsList) {
            NavigationLegsListView(
                journey: journey,
                currentLegIndex: $currentLegIndex
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private func updateCameraPosition() {
        if let userLocation = locationManager.userLocation {
            // Follow user with slight tilt and rotation based on heading
            let heading = locationManager.heading?.trueHeading ?? 0
            mapCameraPosition = .camera(
                MapCamera(
                    centerCoordinate: userLocation.coordinate,
                    distance: 500, // 500 meters altitude
                    heading: heading,
                    pitch: 60 // Tilted view like Google Maps navigation
                )
            )
        }
    }
}

struct InstructionCard: View {
    let leg: Leg
    let nextLeg: Leg?
    let remainingTime: Int
    let onShowList: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main instruction
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(leg.isWalking ? (leg.exposureBand?.color ?? .green) : .blue)
                        .frame(width: 50, height: 50)

                    Image(systemName: leg.iconName)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if leg.isWalking {
                        Text("Walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("to \(leg.to)")
                            .font(.title2.bold())

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
                        Text("Take")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if let routeName = leg.routeName {
                                Text(routeName)
                                    .font(.title2.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Text("to \(leg.to)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Duration and distance
                    HStack {
                        if let distance = leg.distanceKm {
                            Text(String(format: "%.1f km", distance))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text("\(leg.duration) min")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Summary footer
            HStack {
                // Remaining time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(remainingTime) min remaining")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                // Show list button
                Button(action: onShowList) {
                    HStack(spacing: 4) {
                        Text("View all steps")
                            .font(.caption.bold())
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                    }
                }
            }
            
            // Next step preview (if exists)
            if let next = nextLeg {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text("Then")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Image(systemName: next.iconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if next.isWalking {
                        Text("walk \(next.duration) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let routeName = next.routeName {
                        Text("take \(routeName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct UserLocationMarker: View {
    let heading: Double
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 60, height: 60)
            
            // Inner dot
            Circle()
                .fill(.blue)
                .frame(width: 20, height: 20)
            
            // Direction indicator
            Image(systemName: "triangle.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .rotationEffect(.degrees(heading))
                .offset(y: -8)
        }
    }
}

struct WaypointMarker: View {
    let isNext: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isNext ? Color.red : Color.gray)
                .frame(width: 30, height: 30)
            
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)
        }
    }
}

struct NavigationLegsListView: View {
    let journey: Journey
    @Binding var currentLegIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(journey.legs.enumerated()), id: \.offset) { index, leg in
                        Button {
                            currentLegIndex = index
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(leg.isWalking ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: leg.iconName)
                                        .foregroundStyle(leg.isWalking ? .green : .blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if leg.isWalking {
                                        Text("Walk to \(leg.to)")
                                            .font(.subheadline.bold())
                                    } else if let routeName = leg.routeName {
                                        Text("Take \(routeName)")
                                            .font(.subheadline.bold())
                                        Text("to \(leg.to)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text("\(leg.duration) min")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if index == currentLegIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("All Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
