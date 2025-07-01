//
//  ForgotPassView.swift
//  DocMatic
//
//  Created by Paul  on 7/1/25.
//

import SwiftUI

struct ForgotPassView: View {
    @State private var email: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: Lottie Image
            lottieView(name: "guyAtDesk")
                .frame(width: 200, height: 150)
                .clipped()
            
            Text("Forgot Password?")
                .font(.title.bold())
            
            Text("Don't worry it happens to everyone. Please enter your email address below and we'll send you a reset link.")
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            // MARK: form fields
            InputView(text: $email, image: "envelope", placeholder: "Email Address")
                .autocapitalization(.none)
            
            // MARK: sign in button
            Button(action: {
                viewModel.sendResetLink(withEmail: email)
            }) {
                Text("Send Link")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .padding(.horizontal)
            }
            .background(Color("Default").gradient, in: .capsule)
            .disabled(!formIsValid)
            .opacity(formIsValid ? 1.0 : 0.5)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                HStack(spacing: 5) {
                    Text("You remember your password?")
                    Text("Sign In")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 45)
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
