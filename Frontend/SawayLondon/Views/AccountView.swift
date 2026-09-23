//
//  AccountView.swift
//  SafeWay London
//

import SwiftUI

struct AccountView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingHelpSupport = false
    
    var body: some View {
        NavigationStack {
            List {
                if let user = sessionStore.currentUser {
                    Section("Account Information") {
                        LabeledContent("Email", value: user.email)
                        
                        LabeledContent("Plan") {
                            HStack {
                                Text(user.plan.capitalized)
                                if user.plan.lowercased() == "premium" {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section("Support") {
                    Button {
                        showingHelpSupport = true
                    } label: {
                        Label("Help & Support", systemImage: "cross.case.fill")
                            .foregroundStyle(.primary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        sessionStore.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHelpSupport) {
                HelpSupportView()
            }
        }
    }
}

#Preview {
    let sessionStore = SessionStore()
    return AccountView()
        .environment(sessionStore)
}
