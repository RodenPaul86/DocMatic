//
//  ForgotPassView.swift
//  DocMatic
//
//  Created by Paul  on 7/1/25.
//

import SwiftUI

struct ForgotPassView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var email: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: Lottie Image
                    lottieView(name: "guyAtDesk")
                        .frame(width: 200, height: 150)
                        .clipped()
                    
                    Text("Forgot Password?")
                        .font(.title.bold())
                    
                    Text("Don't worry it happens. Please enter your email address below and we'll send you a reset link.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                    
                    // MARK: form fields
                    InputView(text: $email, image: "envelope", placeholder: "Email Address")
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    
                    // MARK: Send Link button
                    if #available(iOS 26.0, *) {
                        Button(action: {
                            viewModel.sendResetLink(withEmail: email)
                            if isHapticsEnabled {
                                hapticManager.shared.notify(.notification(.success))
                            }
                        }) {
                            Text("Send Link")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(!formIsValid)
                        .opacity(formIsValid ? 1.0 : 0.5)
                    } else {
                        Button(action: {
                            viewModel.sendResetLink(withEmail: email)
                            if isHapticsEnabled {
                                hapticManager.shared.notify(.notification(.success))
                            }
                        }) {
                            Text("Send Link")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .padding(.horizontal)
                        }
                        .background(Color.theme.accent, in: .capsule)
                        .disabled(!formIsValid)
                        .opacity(formIsValid ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal, 45)
                .alert(item: $viewModel.activeAlert) { alert in
                    Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
                }
            }
            .scrollBounceBehavior(.basedOnSize) // Optional
            .scrollDismissesKeyboard(.interactively) // iOS 16+
            
            Spacer()
            
            Button(action: { dismiss() }) {
                HStack(spacing: 5) {
                    Text("You remember your password?")
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
extension ForgotPassView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
    }
}

#Preview {
    ForgotPassView()
}
