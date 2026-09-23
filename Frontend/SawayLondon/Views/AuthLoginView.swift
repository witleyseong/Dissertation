//
//  LoginView.swift
//  SafeWay London
//

import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignUp = false
    
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
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    
                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.password)
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
                            Task { await login() }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
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
                        showingSignUp = true
                    } label: {
                        Text("Don't have an account? **Create Account**")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil

        do {
            try await sessionStore.signIn(email: email, password: password)
        } catch let apiError as APIError {
            switch apiError {
            case .unauthorized:
                errorMessage = "Incorrect email or password"
            case .badRequest(let msg):
                errorMessage = msg
            default:
                errorMessage = apiError.localizedDescription
            }
            isLoading = false
        } catch {
            errorMessage = "Error signing in. Please try again."
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
        .environment(SessionStore())
}
