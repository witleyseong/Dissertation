//
//  SupportResourceCard.swift
//  SafeWay London
//

import SwiftUI

struct SupportResourceCard: View {
    let resource: SupportResource
    let onAction: () -> Void
    
    @Environment(\.openURL) private var openURL
    @ScaledMetric private var iconSize: CGFloat = 24
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: resource.systemImage)
                    .font(.system(size: iconSize))
                    .foregroundStyle(resource.isEmergency ? .red : .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        resource.isEmergency
                        ? Color.red.opacity(0.1)
                        : Color.blue.opacity(0.1)
                    )
                    .clipShape(Circle())
                
                Text(resource.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            // Description
            Text(resource.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Primary action button
            Button(action: onAction) {
                HStack {
                    Text(resource.actionTitle)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if case .phone = resource.action {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                    } else {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(resource.isEmergency ? Color.red : Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .accessibilityLabel(accessibilityLabelFor(resource))
            .accessibilityHint(accessibilityHintFor(resource))
            
            // Secondary website link (if available)
            if let websiteURL = resource.websiteURL {
                Link(destination: websiteURL) {
                    HStack {
                        Text("Visit website")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .accessibilityLabel("Visit \(resource.title) website")
                .accessibilityHint("Opens an external official website")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Accessibility
    
    private func accessibilityLabelFor(_ resource: SupportResource) -> String {
        switch resource.action {
        case .phone(let number):
            return "Call \(resource.title) on \(formatPhoneNumber(number))"
        case .website:
            return "Open \(resource.title) website"
        }
    }
    
    private func accessibilityHintFor(_ resource: SupportResource) -> String {
        switch resource.action {
        case .phone:
            return "Shows a confirmation before opening the Phone app"
        case .website:
            return "Opens an external official website"
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Format phone numbers for better speech
        let cleaned = number.replacingOccurrences(of: "tel:", with: "")
        switch cleaned {
        case "999": return "9 9 9"
        case "101": return "1 0 1"
        case "111": return "1 1 1"
        case "116123": return "1 1 6 1 2 3"
        default: return cleaned
        }
    }
}

#Preview("Standard Resource") {
    SupportResourceCard(
        resource: SupportResource(
            title: "Non-emergency police",
            description: "Contact the police about a non-urgent crime, incident, antisocial behaviour or general enquiry.",
            systemImage: "shield.fill",
            actionTitle: "Call 101",
            action: .phone(number: "tel:101")
        ),
        onAction: {}
    )
    .padding()
}

#Preview("Emergency Resource") {
    SupportResourceCard(
        resource: SupportResource(
            title: "Emergency services",
            description: "Call Police, Ambulance or Fire when someone is in immediate danger or a serious incident is happening.",
            systemImage: "phone.fill",
            actionTitle: "Call 999",
            action: .phone(number: "tel:999"),
            isEmergency: true
        ),
        onAction: {}
    )
    .padding()
}

#Preview("With Website Link") {
    SupportResourceCard(
        resource: SupportResource(
            title: "Talk to Samaritans",
            description: "Free, confidential emotional support at any time, day or night.",
            systemImage: "heart.fill",
            actionTitle: "Call 116 123",
            action: .phone(number: "tel:116123"),
            websiteURL: URL(string: "https://www.samaritans.org/how-we-can-help/contact-samaritan/")
        ),
        onAction: {}
    )
    .padding()
}

#Preview("Dark Mode") {
    SupportResourceCard(
        resource: SupportResource(
            title: "Emergency services",
            description: "Call Police, Ambulance or Fire when someone is in immediate danger or a serious incident is happening.",
            systemImage: "phone.fill",
            actionTitle: "Call 999",
            action: .phone(number: "tel:999"),
            isEmergency: true
        ),
        onAction: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    SupportResourceCard(
        resource: SupportResource(
            title: "Non-emergency police",
            description: "Contact the police about a non-urgent crime, incident, antisocial behaviour or general enquiry.",
            systemImage: "shield.fill",
            actionTitle: "Call 101",
            action: .phone(number: "tel:101")
        ),
        onAction: {}
    )
    .padding()
    .environment(\.dynamicTypeSize, .accessibility3)
}
