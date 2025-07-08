//
//  LoginView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct LoginView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var showForgotPasswordAlert: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: Lottie Image
                        lottieView(name: "personsPlaying")
                            .frame(width: 200, height: 150)
                            .clipped()
                        
                        Text("Sign In")
                            .font(.title.bold())
                        
                        Text("Enter valid email and password to sign in.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        
                        // MARK: form fields
                        VStack(spacing: 24) {
                            InputView(text: $email,
                                      image: "envelope.badge.person.crop",
                                      placeholder: "Email address")
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            
                            InputView(text: $password,
                                      image: "lock",
                                      placeholder: "Enter your password",
                                      isSecureField: true)
                            .textContentType(.password)
                            
                            // MARK: Forgot Password
                            HStack {
                                Spacer()
                                
                                NavigationLink {
                                    ForgotPassView()
                                        .navigationBarBackButtonHidden(true)
                                } label: {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        
                        // MARK: sign in button
                        Button(action: {
                            Task {
                                try await viewModel.signIn(withEmail: email, password: password)
                            }
                            if isHapticsEnabled {
                                hapticManager.shared.notify(.notification(.success))
                            }
                        }) {
                            Text("Login")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .padding(.horizontal)
                        }
                        .background(Color.theme.accent, in: .capsule)
                        .disabled(!formIsValid)
                        .opacity(formIsValid ? 1.0 : 0.5)
                        
#if DEBUG
                        HStack {
                            Text("----")
                            Text("Or Continue with")
                            Text("----")
                        }
                        .font(.footnote)
                        .foregroundStyle(.gray)
#endif
                    }
                    .padding(.horizontal, 45)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize) // Optional
                .scrollDismissesKeyboard(.interactively) // iOS 16+
                
                Spacer()
                
                // MARK: sign up button
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 5) {
                        Text("Don't have an account?")
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                }
                .padding(.bottom)
            }
            .alert(item: $viewModel.activeAlert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
            .overlay(
                // MARK: chevron button in top-left
                HStack {
                    Button(action: {
                        dismiss()
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.impact(.light))
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                    .padding(.leading)
                    .padding(.top, 10),
                alignment: .topLeading
            )
        }
    }
}

// MARK: AuthenticationFormProtocol
extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
    }
}

#Preview {
    LoginView()
}
