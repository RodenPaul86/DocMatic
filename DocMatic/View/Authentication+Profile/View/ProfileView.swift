//
//  ProfileView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @State private var showDeleteAlert: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.modelContext) private var context
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        if let user = viewModel.currentUser {
            NavigationStack {
                VStack {
                    VStack(alignment: .center, spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            if let urlString = viewModel.currentUser?.profileImageUrl,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                            .background(Color(.systemGray3))
                                            .clipShape(Circle())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    case .failure:
                                        // Show initials if image fails to load
                                        Text(viewModel.currentUser?.initials ?? "")
                                            .font(.title)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .frame(width: 80, height: 80)
                                            .background(Color(.systemGray3))
                                            .clipShape(Circle())
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                // Show initials if no profileImageUrl
                                Text(viewModel.currentUser?.initials ?? "")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color(.systemGray3))
                                    .clipShape(Circle())
                            }
#if DEBUG
                            NavigationLink {
                                if #available(iOS 18.1, *) {
                                    EditView()
                                        .navigationBarBackButtonHidden(true)
                                } else {
                                    // Fallback on earlier versions
                                }
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.theme.accent)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: 0, y: 0)
#endif
                        }
                        
                        Text(user.fullname)
                            .font(.title3.bold())
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top)
                    
                    // MARK: Stats Section
                    HStack(alignment: .bottom, spacing: 40) {
                        ProfileStatView(value: "\(profileViewModel.scannedCount)", label: "Scanned", icon: "document.viewfinder")
                        ProfileStatView(value: "\(profileViewModel.lockedCount)", label: "Locked", icon: "lock.doc")
                        ProfileStatView(value: "\(profileViewModel.streakCount)", label: "Streak", icon: "flame.fill")
                    }
                    .padding(.vertical)
                    
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Eco Achievements")
                                .font(.title3.bold())
                            
                            achievement(title: "Seedling", description: "Your paperless journey begins.", goal: 1, progress: profileViewModel.ecoAchievements, iconName: "pineCone")
                            achievement(title: "Sprout", description: "25 pages saved from the printer.", goal: 25, progress: profileViewModel.ecoAchievements, iconName: "sprout")
                            achievement(title: "Twig", description: "100 pages saved. Keep growing!", goal: 100, progress: profileViewModel.ecoAchievements, iconName: "plant")
                            achievement(title: "Branch", description: "250 pages saved. That’s a lot of paper.", goal: 250, progress: profileViewModel.ecoAchievements, iconName: "bamboo")
                            achievement(title: "Tree Hugger", description: "500 pages saved! That’s a whole tree!", goal: 500, progress: profileViewModel.ecoAchievements, iconName: "tree")
                            achievement(title: "Eco Hero", description: "1000 pages saved. You’ve gone green!", goal: 1000, progress: profileViewModel.ecoAchievements, iconName: "ecoLabel")
                        }
                        .padding()
                    }
                    
                }
                .safeAreaInset(edge: .bottom) {
                    customUserButtons()
                    
                }
                .onAppear {
                    Task {
                        await viewModel.fetchUser()
                    }
                    profileViewModel.fetchDocuments(from: context)
                }
                .overlay(
                    // MARK: chevron button in top-left
                    HStack {
                        Button(action: {
                            dismiss()
                            if isHapticsEnabled {
                                hapticManager.shared.notify(.impact(.rigid))
                            }
                        }) {
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
    
    @ViewBuilder
    private func customUserButtons() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.signOut()
                if isHapticsEnabled {
                    hapticManager.shared.notify(.notification(.success))
                }
            }) {
                Text("Sign Out")
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6), in: .capsule)
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            }
            
            Button(action: {
                Task {
                    await viewModel.deleteAccount()
                }
                if isHapticsEnabled {
                    hapticManager.shared.notify(.notification(.success))
                }
            }) {
                Text("Delete Account")
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6), in: .capsule)
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background {
            progressiveBlurView()
                .blur(radius: 10)
                .padding(.horizontal, -15)
                .padding(.bottom, -100)
                .padding(.top, -10)
        }
    }
}

struct ProfileStatView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.theme.accent)
                .padding(15)
                .background(.ultraThinMaterial, in: Circle())
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
        }
    }
}

struct achievement: View {
    let id = UUID()
    let title: String
    let description: String
    let goal: Int
    var progress: Int
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(iconName)
                    .resizable()
                    .frame(width: 35, height: 35)
                    .padding(15)
                    .background(.ultraThinMaterial, in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            ProgressView(value: min(Float(max(progress, 0)), Float(goal)), total: Float(goal))
            
            HStack {
                Text("0")
                    .font(.caption)
                Spacer()
                Text("\(goal)")
                    .font(.caption)
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

