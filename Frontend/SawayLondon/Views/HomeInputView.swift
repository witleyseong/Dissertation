//
//  HomeInputView.swift
//  SafeWay London
//

import SwiftUI
import MapKit

struct HomeInputView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(UserLocationManager.self) private var locationManager
    @State private var journeyViewModel: JourneyViewModel
    @State private var recentSearchesStore = RecentSearchesStore()

    @State private var fromText = ""
    @State private var toText = ""
    @State private var showingAbout = false
    @State private var showingAccount = false
    @State private var showingComparison = false
    @State private var showingSearch = false // shows the search sheet
    @State private var useCurrentLocation = true // start from the current location by default
    
    init(sessionStore: SessionStore) {
        _journeyViewModel = State(initialValue: JourneyViewModel(sessionStore: sessionStore))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background map (full screen feel)
                BaseMapView(locationManager: locationManager)
                    .ignoresSafeArea()
                
                // Search sheet overlay (only shown when button is tapped)
                if showingSearch {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        SearchSheet(
                            fromText: $fromText,
                            toText: $toText,
                            journeyViewModel: journeyViewModel,
                            recentSearchesStore: recentSearchesStore,
                            locationManager: locationManager,
                            useCurrentLocation: $useCurrentLocation,
                            onSearch: performSearch,
                            onSelectRecent: selectRecentSearch,
                            onDismiss: { showingSearch = false }
                        )
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        // Menu button to toggle search sheet
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showingSearch.toggle()
                            }
                        } label: {
                            Image(systemName: showingSearch ? "xmark" : "line.3.horizontal")
                                .font(.title3)
                        }
                        
                        HealthPill()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingAbout = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        
                        Button {
                            showingAccount = true
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutDataView()
            }
            .sheet(isPresented: $showingAccount) {
                AccountView()
                    .environment(sessionStore)
            }
            .sheet(isPresented: Binding(
                get: { journeyViewModel.pendingDisambiguation != nil },
                set: { isPresented in
                    if !isPresented { journeyViewModel.pendingDisambiguation = nil }
                }
            )) {
                if let disambiguation = journeyViewModel.pendingDisambiguation {
                    DisambiguationView(disambiguation: disambiguation) { origin, destination in
                        journeyViewModel.pendingDisambiguation = nil
                        Task {
                            await journeyViewModel.resolveDisambiguation(origin: origin, destination: destination)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showingComparison) {
                if !journeyViewModel.journeys.isEmpty {
                    RouteComparisonView(journeys: journeyViewModel.journeys)
                }
            }
            .onChange(of: journeyViewModel.journeys) { oldValue, newValue in
                if !newValue.isEmpty {
                    showingComparison = true
                }
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }
    
    private func performSearch() {
        // "from" is the current location or the text the user typed
        let fromLocation: String
        if useCurrentLocation, let userLocation = locationManager.userLocation {
            fromLocation = "\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)"
        } else if !fromText.isEmpty {
            fromLocation = fromText
        } else {
            journeyViewModel.error = "Please enter a starting location or enable current location"
            return
        }
        
        guard !toText.isEmpty else {
            journeyViewModel.error = "Please enter a destination"
            return
        }
        
        // Add to recent searches
        recentSearchesStore.addSearch(
            from: useCurrentLocation ? "Current Location" : fromText,
            to: toText
        )
        
        // Perform search
        Task {
            await journeyViewModel.planJourney(from: fromLocation, to: toText)
        }
    }
    
    private func selectRecentSearch(_ search: RecentSearch) {
        fromText = search.from
        toText = search.to
        performSearch()
    }
}

struct BaseMapView: View {
    let locationManager: UserLocationManager
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
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
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            )
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
                .mapControlVisibility(.visible)
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(alignment: .bottomTrailing) {
            LocateMeButton { centerOnUserLocation() }
                .padding(.trailing, 16)
                .padding(.bottom, 24)
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if let location = newLocation {
                withAnimation {
                    position = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }

    private func centerOnUserLocation() {
        guard let userLocation = locationManager.userLocation else { return }
        withAnimation {
            position = .region(
                MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
}

struct SearchSheet: View {
    @Binding var fromText: String
    @Binding var toText: String
    let journeyViewModel: JourneyViewModel
    let recentSearchesStore: RecentSearchesStore
    let locationManager: UserLocationManager
    @Binding var useCurrentLocation: Bool
    let onSearch: () -> Void
    let onSelectRecent: (RecentSearch) -> Void
    let onDismiss: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var sheetHeight: CGFloat = 500
    @GestureState private var dragOffset: CGFloat = 0
    
    enum Field {
        case from, to
    }
    
    private let minHeight: CGFloat = 350
    
    var body: some View {
        GeometryReader { geometry in
            sheetContent(maxHeight: geometry.size.height - 100)
        }
    }
    
    private func sheetContent(maxHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Drag handle (drag up to expand, down to collapse/dismiss)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let velocity = value.translation.height
                            
                            // Swipe down strongly = dismiss (when at minimum height)
                            if velocity > 150 && sheetHeight <= minHeight + 50 {
                                withAnimation(.spring(response: 0.3)) {
                                    onDismiss()
                                }
                            }
                            // Swipe up = expand to full screen
                            else if velocity < -100 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    sheetHeight = maxHeight
                                }
                            }
                            // Swipe down = collapse to minimum
                            else if velocity > 100 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    sheetHeight = minHeight
                                }
                            }
                        }
                )
            
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    Text("Plan your journey")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    // Search inputs
                    VStack(spacing: 12) {
                        // From field with current location toggle
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            if useCurrentLocation {
                                HStack {
                                    if locationManager.userLocation != nil {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        Text("Current Location")
                                            .foregroundStyle(.primary)
                                    } else {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Getting location...")
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        useCurrentLocation = false
                                        focusedField = .from
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 12)
                            } else {
                                TextField("From", text: $fromText)
                                    .focused($focusedField, equals: .from)
                                    .textInputAutocapitalization(.words)
                                    .padding(.vertical, 12)
                                
                                Button {
                                    useCurrentLocation = true
                                    fromText = ""
                                    focusedField = nil
                                } label: {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                            
                            TextField("To", text: $toText)
                                .focused($focusedField, equals: .to)
                                .textInputAutocapitalization(.words)
                                .padding(.vertical, 12)
                                .onSubmit(onSearch)
                        }
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Compare button
                    Button(action: onSearch) {
                        if journeyViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Compare routes")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSearch ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .disabled(!canSearch || journeyViewModel.isLoading)
                    
                    // Error message
                    if let error = journeyViewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Recent searches
                    if !recentSearchesStore.searches.isEmpty && fromText.isEmpty && toText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent searches")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    recentSearchesStore.clearAll()
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            ForEach(recentSearchesStore.searches) { search in
                                RecentSearchRow(search: search) {
                                    onSelectRecent(search)
                                }
                            }
                        }
                    }
                    
                    // Disclaimer
                    DisclaimerBar()
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        .frame(height: sheetHeight + dragOffset)
        .frame(maxHeight: maxHeight)
        .background(.ultraThinMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 20)
    }
    
    private var canSearch: Bool {
        let hasFrom = useCurrentLocation ? locationManager.userLocation != nil : !fromText.isEmpty
        return hasFrom && !toText.isEmpty
    }
}

struct RecentSearchRow: View {
    let search: RecentSearch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.green)
                        Text(search.from)
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.red)
                        Text(search.to)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HomeInputView(sessionStore: SessionStore())
        .environment(SessionStore())
        .environment(UserLocationManager())
}
