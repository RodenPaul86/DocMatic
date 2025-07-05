//
//  RegistrationView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct RegistrationView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isShowingTermsOfService: Bool = false
    @State private var isShowingPrivacyPolicy: Bool = false
    
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
                            .textContentType(.name)
                        
                        InputView(text: $email, image: "envelope", placeholder: "Email Address", borderColor: emailFieldWasTouched && !emailIsValid ? .red : nil) {
                            emailFieldWasTouched = false
                        }
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .focused($emailFieldIsFocused)
                        .onChange(of: emailFieldIsFocused) { focused in
                            if !focused {
                                emailFieldWasTouched = true // Mark field as touched after focus is lost
                            }
                        }
                        
                        InputView(text: $password, image: "lock", placeholder: "Password", isSecureField: true, borderColor: borderColorForPassword)
                            .textContentType(.newPassword)
                        
                        InputView(text: $confirmPassword, image: "lock", placeholder: "Confirm Password", isSecureField: true, borderColor: borderColorForPassword)
                            .textContentType(.newPassword)
                        
                        VStack(alignment: .center, spacing: 5) {
                            Text("By signing up, you agree to our")
                                .foregroundStyle(.gray)
                            
                            HStack(spacing: 5) {
                                Button("Terms & Conditions") {
                                    isShowingTermsOfService = true
                                }
                                .font(.footnote.bold())
                                .sheet(isPresented: $isShowingTermsOfService) {
                                    NavigationStack {
                                        webView(url: "https://docmatic.app/terms.html")
                                            .navigationTitle("Terms & Conditions")
                                            .navigationBarTitleDisplayMode(.inline)
                                            .toolbar {
                                                ToolbarItem(placement: .navigationBarTrailing) {
                                                    if let link = URL(string: "https://docmatic.app/terms.html") {
                                                        Link(destination: link) {
                                                            Image(systemName: "safari")
                                                                .font(.headline)
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                                
                                Text("and")
                                    .foregroundStyle(.gray)
                                
                                Button("Privacy Policy") {
                                    isShowingPrivacyPolicy = true
                                }
                                .font(.footnote.bold())
                                .sheet(isPresented: $isShowingPrivacyPolicy) {
                                    NavigationStack {
                                        webView(url: "https://docmatic.app/privacy.html")
                                            .navigationTitle("Privacy Policy")
                                            .navigationBarTitleDisplayMode(.inline)
                                            .toolbar {
                                                ToolbarItem(placement: .navigationBarTrailing) {
                                                    if let link = URL(string: "https://docmatic.app/privacy.html") {
                                                        Link(destination: link) {
                                                            Image(systemName: "safari")
                                                                .font(.headline)
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    }
                    
                    // MARK: Create Account button
                    Button(action: {
                        Task {
                            try await viewModel.createUser(withEmail: email, password: password, fullName: fullName)
                        }
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.notification(.success))
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
