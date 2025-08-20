//
//  EditView.swift
//  DocMatic
//
//  Created by Paul  on 7/5/25.
//

import SwiftUI
import PhotosUI
import ImagePlayground

struct EditView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var avatarImage: Image?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var showCamera = false
    
    @State private var profileImageURL: URL?
    
    @Environment(\.supportsImagePlayground) var supportsImagePlayground
    @State private var isShowingImagePlayground: Bool = false
    
    @Environment(\.modelContext) private var context
    @StateObject private var profileVM = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    var hasChanges: Bool {
        selectedUIImage != nil
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: Profile Preview Image
                    if let selectedImage = selectedUIImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                    } else if let url = profileImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                                    .contextMenu {
                                        Button(action: {
                                            if let selectedUIImage {
                                                UIImageWriteToSavedPhotosAlbum(selectedUIImage, nil, nil, nil)
                                            } else {
                                                // If selectedUIImage is nil, try loading from the URL (fallback)
                                                Task {
                                                    if let url = profileImageURL,
                                                       let data = try? Data(contentsOf: url),
                                                       let image = UIImage(data: data) {
                                                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                                    }
                                                }
                                            }
                                        }) {
                                            Label("Save Image", systemImage: "square.and.arrow.down")
                                                .tint(.primary)
                                        }
                                    }
                            case .failure(_):
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundStyle(Color(.systemGray3))
                                    .frame(width: 120, height: 120)
                                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(Color(.systemGray3))
                            .frame(width: 120, height: 120)
                            .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                    }
                    
                    // MARK: Buttons for Photo + Gen AI + Camera
                    VStack(spacing: 24) {
                        PhotosPicker(selection: $photosPickerItem, matching: .not(.screenshots)) {
                            photoButtonView(image: "photo.on.rectangle.angled.fill", title: "Your Photos")
                        }
                        
                        if supportsImagePlayground {
                            Button(action: { isShowingImagePlayground = true }) {
                                photoButtonView(image: "sparkles", title: "Generate Image")
                            }
                        }
                        
                        Button(action: { showCamera = true }) {
                            photoButtonView(image: "camera.fill", title: "Camera")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                }
                .padding(30)
            }
            .scrollBounceBehavior(.basedOnSize) /// <-- Optional
            .scrollDismissesKeyboard(.interactively) /// <-- iOS 16+
            
            VStack(spacing: 12) {
                // MARK: Save Button
                if #available(iOS 26.0, *) {
                    Button(action: {
                        Task {
                            if let image = selectedUIImage {
                                await authVM.uploadProfileImage(image)
                            }
                            dismiss()
                        }
                    }) {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.5)
                } else {
                    Button(action: {
                        if isHapticsEnabled {
                            hapticManager.shared.notify(.notification(.success))
                        }
                        
                        Task {
                            if let image = selectedUIImage {
                                await authVM.uploadProfileImage(image)
                            }
                            dismiss()
                        }
                    }) {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.theme.accent, in: .capsule)
                    }
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1.0 : 0.5)
                }
                
                // MARK: Discard Button
                Button(action: {
                    if isHapticsEnabled {
                        hapticManager.shared.notify(.notification(.success))
                    }
                    
                    dismiss()
                }) {
                    if #available(iOS 26.0, *) {
                        Text("Discard")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6), in: .capsule)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    } else {
                        Text("Discard")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6), in: .capsule)
                            .overlay(
                                Capsule()
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 30)
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            if let user = authVM.currentUser {
                if let urlString = user.profileImageUrl,
                   let url = URL(string: urlString) {
                    profileImageURL = url
                }
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedUIImage = image
                    avatarImage = Image(uiImage: image)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                if let image = image {
                    selectedUIImage = image
                    avatarImage = Image(uiImage: image)
                }
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .imagePlaygroundSheet(isPresented: $isShowingImagePlayground,
                              concept: "",
                              sourceImage: avatarImage) { url in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    selectedUIImage = image
                    avatarImage = Image(uiImage: image)
                }
            }
        }
    }
}
