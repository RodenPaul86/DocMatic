//
//  AuthViewModel.swift
//  DocMatic
//
//  Created by Paul  on 6/30/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

enum AuthAlert: Identifiable {
    case error(String)
    case success(String)
    
    var id: String {
        switch self {
        case .error(let message): return "error:\(message)"
        case .success(let message): return "success:\(message)"
        }
    }
    
    var title: String {
        switch self {
        case .error: return "Error"
        case .success: return "Success"
        }
    }
    
    var message: String {
        switch self {
        case .error(let message), .success(let message):
            return message
        }
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var activeAlert: AuthAlert?
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        Task {
            await validateSession()
        }
    }
    
    func sendResetLink(withEmail email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("❌ Failed to send reset email:", error.localizedDescription)
                self.activeAlert = .error("Failed to send reset link: \(error.localizedDescription)")
            } else {
                print("✅ Reset link sent!")
                self.activeAlert = .success("A password reset link has been sent to your email.")
            }
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            print("DEBUG: Failure to sign in with error: \(error.localizedDescription)")
            self.activeAlert = .error("It looks like there is no account associated with this email. Please try again or sign up for an account.")
        }
    }
    
    func createUser(withEmail email: String, password: String, fullName: String, profileImage: UIImage?) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            var profileImageUrl: String? = nil
            
            if let image = profileImage,
               let imageData = image.jpegData(compressionQuality: 0.5) {
                
                let ref = Storage.storage().reference(withPath: "/profile_images/\(result.user.uid).jpg")
                
                let _ = try await ref.putDataAsync(imageData)
                profileImageUrl = try await ref.downloadURL().absoluteString
            }
            
            let user = User(id: result.user.uid, fullname: fullName, email: email, profileImageUrl: profileImageUrl ?? "")
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
            self.activeAlert = .error("Faild to create user: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut() /// <-- Signs out user on backend.
            self.userSession = nil /// <-- Wipes out user session and takes back to login screen.
            self.currentUser = nil /// <-- Wipes out current user data model.
            self.activeAlert = .success("You’ve been signed out.")
        } catch {
            print("DEBUG: falied to sign out with error \(error.localizedDescription)")
            self.activeAlert = .error("Sign out failed: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            let ref = Storage.storage().reference(withPath: "profile_images/\(user.uid).jpg")
            try await ref.delete()
            print("Profile image deleted")
            try await Firestore.firestore().collection("users").document(user.uid).delete()
            try await user.delete() /// <-- Delete FireBase Auth account.
            self.userSession = nil /// <-- Wipes out user session and takes back to login screen.
            self.currentUser = nil /// <-- Wipes out current user data model.
            self.activeAlert = .success("Your account has been permanently deleted.")
        } catch {
            print("DEBUG: Failed to delete account with error: \(error.localizedDescription)")
            self.activeAlert = .error("Delete account failed: \(error.localizedDescription)")
            signOut()
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
    }
    
    func validateSession() async {
        guard let user = Auth.auth().currentUser else { return }

        do {
            // Try refreshing token to see if user is valid
            _ = try await user.getIDTokenResult(forcingRefresh: true)
            await fetchUser()
        } catch {
            print("⚠️ User session invalid. Logging out. Reason: \(error.localizedDescription)")
            signOut()
        }
    }
}

extension AuthViewModel {
    func uploadProfileImage(_ image: UIImage) async {
        guard let uid = userSession?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let ref = Storage.storage().reference(withPath: "/profile_images/\(uid).jpg")
        
        do {
            let _ = try await ref.putDataAsync(imageData)
            let imageUrl = try await ref.downloadURL().absoluteString
            
            // Update Firestore user document
            try await Firestore.firestore().collection("users").document(uid).updateData([
                "profileImageUrl": imageUrl
            ])
            
            // Refresh user data
            await fetchUser()
            
        } catch {
            print("❌ Failed to upload profile image: \(error.localizedDescription)")
            activeAlert = .error("Profile image upload failed: \(error.localizedDescription)")
        }
    }
}
