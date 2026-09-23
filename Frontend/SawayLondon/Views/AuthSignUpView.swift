//
//  SignUpView.swift
//  SafeWay London
//

import SwiftUI

struct SignUpView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                        
                        Text("SafeWay London")
                            .font(.largeTitle.bold())
                        
                        Text("Compare historical crime exposure in multimodal routes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Password (minimum 8 characters)", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button {
                            Task { await signUp() }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Footer
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? **Sign In**")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        email.contains("@")
    }
    
    private func signUp() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil

        do {
            try await sessionStore.signUp(email: email, password: password)
            dismiss()
        } catch let apiError as APIError {
            switch apiError {
            case .conflict:
                errorMessage = "This email is already registered"
            case .badRequest(let msg):
                errorMessage = msg
            default:
                errorMessage = apiError.localizedDescription
            }
            isLoading = false
        } catch {
            errorMessage = "Error creating account. Please try again."
            isLoading = false
        }
    }
}

#Preview {
    SignUpView()
        .environment(SessionStore())
}
