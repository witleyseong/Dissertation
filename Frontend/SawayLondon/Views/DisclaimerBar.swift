//
//  DisclaimerBar.swift
//  SafeWay London
//

import SwiftUI

struct DisclaimerBar: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text("Exposure information is based on selected historical police-recorded crime data near walking sections. It does not predict crime or guarantee personal safety.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text("Data currently available: June 2023 to May 2026.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "location.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text("Crime data is anonymised to public locations by UK Police. High counts may indicate busy public areas.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exposure information is based on selected historical police-recorded crime data from June 2023 to May 2026 near walking sections. It does not predict crime or guarantee personal safety. Crime data is anonymised to public locations by UK Police.")
    }
}

#Preview {
    DisclaimerBar()
}
