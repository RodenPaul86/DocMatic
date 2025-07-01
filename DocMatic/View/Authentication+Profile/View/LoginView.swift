//
//  LoginView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct LoginView: View {
    @State private var showForgotPasswordAlert: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
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
                    
                    InputView(text: $password,
                              image: "lock",
                              placeholder: "Enter your password",
                              isSecureField: true)
                    
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
                }) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .padding(.horizontal)
                }
                .background(Color("Default").gradient, in: .capsule)
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                
                HStack {
                    Text("----")
                    Text("Or Continue with")
                    Text("----")
                }
                .font(.footnote)
                .foregroundStyle(.gray)
                
                
                
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
            }
            .padding(.horizontal, 45)
            .overlay(
                // MARK: chevron button in top-left
                HStack {
                    Button(action: { dismiss() }) {
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
