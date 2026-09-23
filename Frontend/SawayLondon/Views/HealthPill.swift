//
//  HealthPill.swift
//  SafeWay London
//

import SwiftUI

struct HealthPill: View {
    @State private var health: HealthResponse?
    @State private var isOnline = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            if let health {
                Text("API: \(health.status)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Connecting…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .task {
            await checkHealth()
        }
    }
    
    private func checkHealth() async {
        do {
            let response = try await AuthAPI.checkHealth()
            health = response
            isOnline = response.status == "ok"
        } catch {
            isOnline = false
        }
    }
}

#Preview {
    HealthPill()
}
