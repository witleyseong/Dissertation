//
//  HelpSupportView.swift
//  SafeWay London
//

import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var confirmationDialog: SupportConfirmation?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Help & Support")
                            .font(.title.bold())
                        
                        Text("Quick access to trusted UK support services.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 1. Emergency Section
                    emergencySection
                    
                    // 2. Police and Crime Reporting
                    policeSection
                    
                    // 3. Mental Health and NHS Support
                    mentalHealthSection
                    
                    // Disclaimer
                    disclaimerView
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                confirmationDialog?.title ?? "",
                isPresented: Binding(
                    get: { confirmationDialog != nil },
                    set: { if !$0 { confirmationDialog = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let dialog = confirmationDialog {
                    Button(dialog.actionTitle, role: .none) {
                        dialog.action()
                    }
                    
                    Button("Cancel", role: .cancel) {
                        confirmationDialog = nil
                    }
                }
            } message: {
                if let dialog = confirmationDialog {
                    Text(dialog.message)
                }
            }
            .alert("Unable to Open", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Emergency Section
    
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                title: "Emergency"
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: emergencyResource,
                onAction: { handleAction(for: emergencyResource) }
            )
            .padding(.horizontal)
            
            // Emergency note
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text("For emergencies in the UK, 999 connects you to Police, Ambulance or Fire services.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Police Section
    
    private var policeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "shield.fill",
                iconColor: .blue,
                title: "Police and crime reporting"
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: nonEmergencyPoliceResource,
                onAction: { handleAction(for: nonEmergencyPoliceResource) }
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: reportCrimeResource,
                onAction: { handleAction(for: reportCrimeResource) }
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Mental Health Section
    
    private var mentalHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                icon: "cross.case.fill",
                iconColor: .green,
                title: "Mental health and NHS support"
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: nhs111Resource,
                onAction: { handleAction(for: nhs111Resource) }
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: samaritansResource,
                onAction: { handleAction(for: samaritansResource) }
            )
            .padding(.horizontal)
            
            SupportResourceCard(
                resource: nhsMentalHealthResource,
                onAction: { handleAction(for: nhsMentalHealthResource) }
            )
            .padding(.horizontal)
        }
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                
                Text("Important Information")
                    .font(.headline)
            }
            
            Text("SafeWay does not provide emergency, police or medical services. If you or someone else is in immediate danger, call 999. External services and websites are operated by their respective organisations.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Support Resources
    
    private var emergencyResource: SupportResource {
        SupportResource(
            title: "Emergency services",
            description: "Call Police, Ambulance or Fire when someone is in immediate danger or a serious incident is happening.",
            systemImage: "phone.fill",
            actionTitle: "Call 999",
            action: .phone(number: "tel:999"),
            isEmergency: true
        )
    }
    
    private var nonEmergencyPoliceResource: SupportResource {
        SupportResource(
            title: "Non-emergency police",
            description: "Contact the police about a non-urgent crime, incident, antisocial behaviour or general enquiry.",
            systemImage: "shield.fill",
            actionTitle: "Call 101",
            action: .phone(number: "tel:101")
        )
    }
    
    private var reportCrimeResource: SupportResource {
        SupportResource(
            title: "Report a crime online",
            description: "Use the Metropolitan Police website to report a non-emergency crime or incident in London.",
            systemImage: "doc.text.fill",
            actionTitle: "Open Metropolitan Police",
            action: .website(URL(string: "https://www.met.police.uk/ro/report/ocr/af/how-to-report-a-crime/")!)
        )
    }
    
    private var nhs111Resource: SupportResource {
        SupportResource(
            title: "Urgent mental health support",
            description: "Call NHS 111 and select the mental health option if you need urgent mental health support but there is no immediate danger.",
            systemImage: "cross.case.fill",
            actionTitle: "Call NHS 111",
            action: .phone(number: "tel:111"),
            websiteURL: URL(string: "https://www.nhs.uk/nhs-services/mental-health-services/where-to-get-urgent-help-for-mental-health/")
        )
    }
    
    private var samaritansResource: SupportResource {
        SupportResource(
            title: "Talk to Samaritans",
            description: "Free, confidential emotional support at any time, day or night.",
            systemImage: "heart.fill",
            actionTitle: "Call 116 123",
            action: .phone(number: "tel:116123"),
            websiteURL: URL(string: "https://www.samaritans.org/how-we-can-help/contact-samaritan/")
        )
    }
    
    private var nhsMentalHealthResource: SupportResource {
        SupportResource(
            title: "NHS mental health services",
            description: "Find information about NHS mental health services, treatments and ways to get support.",
            systemImage: "brain.head.profile",
            actionTitle: "Visit NHS mental health services",
            action: .website(URL(string: "https://www.nhs.uk/nhs-services/mental-health-services/")!)
        )
    }
    
    // MARK: - Action Handling
    
    private func handleAction(for resource: SupportResource) {
        switch resource.action {
        case .phone(let number):
            showPhoneConfirmation(for: resource, number: number)
        case .website(let url):
            openURL(url)
        }
    }
    
    private func showPhoneConfirmation(for resource: SupportResource, number: String) {
        let (title, message) = confirmationContent(for: resource, number: number)
        
        confirmationDialog = SupportConfirmation(
            title: title,
            message: message,
            actionTitle: resource.actionTitle
        ) {
            makePhoneCall(number: number)
        }
    }
    
    private func confirmationContent(for resource: SupportResource, number: String) -> (String, String) {
        switch number {
        case "tel:999":
            return (
                "Call emergency services?",
                "Call 999 only when someone is in immediate danger, a serious crime is happening, or urgent emergency assistance is required."
            )
        case "tel:101":
            return (
                "Call the police on 101?",
                "Use 101 for police matters that do not require an immediate emergency response."
            )
        case "tel:111":
            return (
                "Call NHS 111?",
                "NHS 111 can direct you to appropriate urgent health or mental-health support."
            )
        case "tel:116123":
            return (
                "Call Samaritans?",
                "Samaritans provide free, confidential emotional support at any time."
            )
        default:
            return (
                "Make call?",
                "This will open the Phone app to call \(number.replacingOccurrences(of: "tel:", with: ""))."
            )
        }
    }
    
    private func makePhoneCall(number: String) {
        guard let url = URL(string: number) else {
            errorMessage = "Invalid phone number."
            showingError = true
            return
        }
        
        openURL(url) { accepted in
            if !accepted {
                errorMessage = "Unable to open the Phone app. Please ensure calling is enabled on your device."
                showingError = true
            }
        }
    }
}

// MARK: - Section Header Component

struct SectionHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
            
            Text(title)
                .font(.title3.bold())
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    HelpSupportView()
}

#Preview("Dark Mode") {
    HelpSupportView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    HelpSupportView()
        .environment(\.dynamicTypeSize, .accessibility2)
}
