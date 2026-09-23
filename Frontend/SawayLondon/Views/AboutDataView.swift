//
//  AboutDataView.swift
//  SafeWay London
//

import SwiftUI

struct AboutDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the Data")
                            .font(.title.bold())
                        
                        Text("Understand how crime data is used in this application")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // What is shown
                    SectionView(
                        icon: "chart.bar.fill",
                        iconColor: .blue,
                        title: "What we show",
                        content: "SafeWay London compares historical exposure to recorded crime along walking segments within multimodal routes. We show historical police-recorded crime data from the Metropolitan Police Service and City of London Police."
                    )
                    
                    // What is NOT shown
                    SectionView(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "What we do NOT show",
                        content: "This application does not predict real-time safety. We do not label routes as \"safe\" or \"dangerous\". The data is historical and approximate."
                    )
                    
                    // Data source
                    SectionView(
                        icon: "location.fill",
                        iconColor: .green,
                        title: "Data source",
                        content: "Historical police-recorded crime data from the Metropolitan Police Service and City of London Police, published through data.police.uk. Locations are anonymised to public locations and may not reflect the exact incident location."
                    )
                    
                    // How to interpret
                    SectionView(
                        icon: "info.circle.fill",
                        iconColor: .purple,
                        title: "How to interpret",
                        content: "Routes are classified into three exposure bands:\n\nLower exposure: Fewer historical recorded crimes\nModerate exposure: Moderate level of historical crimes\nHigher exposure: More historical recorded crimes\n\nAll values are based on historical recorded crime data."
                    )
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Important", systemImage: "exclamationmark.shield.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                        
                        Text("Historical crime data does not predict future safety. Use this application as an informative tool, but always practise personal safety and remain aware of your surroundings.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AboutDataView()
}
