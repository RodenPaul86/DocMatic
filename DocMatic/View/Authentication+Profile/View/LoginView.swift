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
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            // MARK: image
            Image("github1024")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)
            
            // MARK: form fields
            VStack(spacing: 24) {
                InputView(text: $email,
                          title: "Email Address",
                          placeholder: "name@example.com")
                .autocapitalization(.none)
                
                InputView(text: $password,
                          title: "Password",
                          placeholder: "Enter your password",
                          isSecureField: true)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // MARK: sign in button
            Button(action: {
                Task {
                    try await viewModel.signIn(withEmail: email, password: password)
                }
            }) {
                HStack {
                    Text("Sign In")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 50)
            }
            .background(Color("Default").gradient, in: .capsule)
            .disabled(!formIsValid)
            .opacity(formIsValid ? 1.0 : 0.5)
            .padding(.top, 24)
            
            Button(action: {
                showForgotPasswordAlert = true
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.top, 12)
            .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
                TextField("Enter your email", text: $email)
                Button("Send Reset Link") {
                    viewModel.sendResetLink(withEmail: email)
                }
                Button("Cancel", role: .cancel) {}
            }
            
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
