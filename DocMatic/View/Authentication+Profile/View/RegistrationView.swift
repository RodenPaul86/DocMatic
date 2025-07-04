//
//  RegistrationView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct RegistrationView: View {
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var emailFieldIsFocused: Bool
    @State private var emailFieldWasTouched = false
    
    var passwordsMatch: Bool? {
        if password.isEmpty || confirmPassword.isEmpty {
            return nil
        }
        return password == confirmPassword
    }
    
    var borderColorForPassword: Color? {
        switch passwordsMatch {
        case true:
            return .green
        case false:
            return .red
        default:
            return nil
        }
    }
    
    var emailIsValid: Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: Lottie Image
                    lottieView(name: "settingPass")
                        .frame(width: 200, height: 150)
                        .clipped()
                    
                    Text("Sign Up")
                        .font(.title.bold())
                    
                    Text("Use proper information to create an account.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    // MARK: form fields
                    VStack(spacing: 24) {
                        InputView(text: $fullName, image: "person", placeholder: "Full Name")
                        
                        InputView(text: $email, image: "envelope", placeholder: "Email Address", borderColor: emailFieldWasTouched && !emailIsValid ? .red : nil) {
                            emailFieldWasTouched = false
                        }
                        .autocapitalization(.none)
                        .focused($emailFieldIsFocused)
                        .onChange(of: emailFieldIsFocused) { focused in
                            if !focused {
                                emailFieldWasTouched = true // Mark field as touched after focus is lost
                            }
                        }
                        
                        InputView(text: $password, image: "lock", placeholder: "Password", isSecureField: true, borderColor: borderColorForPassword)
                        
                        InputView(text: $confirmPassword, image: "lock", placeholder: "Confirm Password", isSecureField: true, borderColor: borderColorForPassword)
                        
                        VStack(alignment: .center, spacing: 5) {
                            Text("By signing up, you agree to our")
                                .foregroundStyle(.gray)
                            
                            HStack(spacing: 5) {
                                Button("Terms & Conditions") {
                                    // Action
                                }
                                .font(.footnote.bold())
                                
                                Text("and")
                                    .foregroundStyle(.gray)
                                
                                Button("Privacy Policy") {
                                    // Action
                                }
                                .font(.footnote.bold())
                            }
                        }
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    }
                    
                    // MARK: sign in button
                    Button(action: {
                        Task {
                            try await viewModel.createUser(withEmail: email, password: password, fullName: fullName)
                        }
                    }) {
                        Text("Create Account")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .background(Color("Default").gradient, in: .capsule)
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)
                }
                .padding(.horizontal, 45)
            }
            .scrollBounceBehavior(.basedOnSize) // Optional
            .scrollDismissesKeyboard(.interactively) // iOS 16+
            
            Spacer()
            
            Button(action: { dismiss() }) {
                HStack(spacing: 5) {
                    Text("Already have an account?")
                    Text("Sign In")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            .padding(.bottom)
        }
    }
}

// MARK: AuthenticationFormProtocol
extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
        && confirmPassword == password
        && !fullName.isEmpty
    }
}

#Preview {
    RegistrationView()
}
