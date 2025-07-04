//
//  InputView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let image: String
    let placeholder: String
    var isSecureField: Bool = false
    var borderColor: Color? = nil
    var onClear: (() -> Void)? = nil
    
    // Local state to toggle password visibility
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: image)
                .foregroundStyle(.gray)
            
            // Toggle between SecureField and TextField
            if isSecureField && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
            }
            
            // Show/hide password button for secure fields
            if isSecureField {
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            
            // Clear text button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor ?? Color(.systemGray5), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        InputView(text: .constant(""), image: "person", placeholder: "Username")
        InputView(text: .constant("123456"), image: "lock", placeholder: "Password", isSecureField: true)
    }
}
