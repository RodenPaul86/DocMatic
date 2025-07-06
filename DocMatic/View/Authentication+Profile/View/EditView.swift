//
//  EditView.swift
//  DocMatic
//
//  Created by Paul  on 7/5/25.
//

import SwiftUI
import PhotosUI
import FirebaseStorage

struct EditView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var avatarImage: Image?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            PhotosPicker(selection: $photosPickerItem, matching: .not(.screenshots)) {
                (avatarImage ?? Image(systemName: "person.circle.fill"))
                    .resizable()
                    .foregroundStyle(Color(.systemGray3))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedUIImage = uiImage
                        avatarImage = Image(uiImage: uiImage)
                    }
                }
            }
            
            VStack(spacing: 24) {
                InputView(text: $fullName, image: "person", placeholder: "Full Name")
                    .textContentType(.name)
                
                InputView(text: $email, image: "envelope", placeholder: "Email")
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    if let image = selectedUIImage {
                        await authVM.uploadProfileImage(image)
                    }
                }
            }) {
                Text("Save Changes")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .background(Color("Default").gradient, in: .capsule)
            .disabled((selectedUIImage == nil))
            .opacity((selectedUIImage != nil) ? 1.0 : 0.5)
        }
        .navigationTitle("Edit Profile")
        .padding(30)
        .onAppear {
            // Prefill with current user data
            if let user = authVM.currentUser {
                email = user.email
                fullName = user.fullname
                if let urlStr = user.profileImageUrl,
                   let url = URL(string: urlStr) {
                    Task {
                        if let data = try? Data(contentsOf: url),
                           let uiImage = UIImage(data: data) {
                            avatarImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        }
    }
}
