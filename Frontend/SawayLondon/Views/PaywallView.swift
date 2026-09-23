//
//  PaywallView.swift
//  SafeWay London
//

import SwiftUI

/// Placeholder paywall, not used anywhere yet. There are no payments in this project,
/// so the button is disabled.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let feature: Feature

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)

                    Text("Premium feature")
                        .font(.title.bold())

                    Text(featureDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "clock.arrow.circlepath", text: "Saved route history")
                        FeatureRow(icon: "slider.horizontal.3", text: "Crime category filters")
                        FeatureRow(icon: "infinity", text: "Unlimited comparisons")
                        FeatureRow(icon: "chart.bar.fill", text: "Advanced analytics")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Button {
                        // not implemented, no purchase flow
                        dismiss()
                    } label: {
                        Text("Coming soon")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(true)
                    .opacity(0.5)
                }
                .padding()
            }
            .navigationTitle("SafeWay Premium")
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

    private var featureDescription: String {
        switch feature {
        case .savedRouteHistory:
            return "Save and review your past routes"
        case .crimeFilters:
            return "Filter by specific crime categories"
        case .customExposureBuffer:
            return "Customise the analysis area"
        case .advancedAnalytics:
            return "View detailed exposure analytics"
        default:
            return "Access advanced features"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView(feature: .savedRouteHistory)
}
