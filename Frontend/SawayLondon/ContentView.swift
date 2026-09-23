//
//  ContentView.swift
//  SafeWay London
//

import SwiftUI

struct ContentView: View {
    @State private var sessionStore = SessionStore()
    @State private var locationManager = UserLocationManager()

    var body: some View {
        Group {
            switch sessionStore.state {
            case .loading:
                LoadingView()

            case .signedOut:
                LoginView()

            case .signedIn:
                HomeInputView(sessionStore: sessionStore)
            }
        }
        .environment(sessionStore)
        .environment(locationManager)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("SafeWay London")
                .font(.title.bold())
            
            ProgressView()
                .padding(.top, 20)
        }
    }
}

#Preview {
    ContentView()
}
