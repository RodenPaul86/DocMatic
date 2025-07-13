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
    @StateObject private var scanManager = ScanManager.shared
    
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
                        ProfileStatView(value: "\(scanManager.scanCount)", label: "Scanned", icon: "document.viewfinder")
                        //ProfileStatView(value: "\(docVM.lockedCount)", label: "Locked", icon: "lock.doc")
                        ProfileStatView(value: "\(scanManager.streakCount) day\(scanManager.streakCount == 1 ? "" : "s")", label: "Streak", icon: "flame.fill")
                    }
                    .padding(.vertical)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Eco Achievements")
                                .font(.title3.bold())
                                .padding(.bottom)
                            
                            achievement(title: "🌱 Paper Saver",
                                        description: "Your first shared scan—one small step for you, one leafy leap for Earth.",
                                        goal: 1,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "leaf")
                            
                            achievement(title: "🐛 Eco Explorer",
                                        description: "You’re starting a sustainable sharing habit. Keep it growing!",
                                        goal: 5,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "ant")
                            
                            achievement(title: "🍃 Leaf It to Me",
                                        description: "10 pages shared—trees are quietly celebrating.",
                                        goal: 10,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "leaf.circle")
                            
                            achievement(title: "🪴 Green Thumb",
                                        description: "Your eco-sharing habits are starting to blossom beautifully.",
                                        goal: 25,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "sun.min")
                            
                            achievement(title: "🐝 Buzz of Efficiency",
                                        description: "50 pages shared—you’re working like a busy (and green) bee.",
                                        goal: 50,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "hare")
                            
                            achievement(title: "🌳 Tree Hugger",
                                        description: "100 shared pages—roughly a full tree saved from the printer!",
                                        goal: 100,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "tree")
                            
                            achievement(title: "🌎 Planet Protector",
                                        description: "You’re officially doing your part to keep things paperless.",
                                        goal: 250,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "globe")
                            
                            achievement(title: "🔋 Carbon Cutter",
                                        description: "500 shared scans—your impact is high-voltage eco-smart.",
                                        goal: 500,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "bolt.fill")
                            
                            achievement(title: "🚴 Green Commuter",
                                        description: "You’re sharing like a sustainable cyclist: clean and consistent.",
                                        goal: 750,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "bicycle")
                            
                            achievement(title: "🦉 Wise Eco Warrior",
                                        description: "1,000 pages shared! The forests nod in respect.",
                                        goal: 1000,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "brain.head.profile")
                            
                            achievement(title: "🌤 Sky Saver",
                                        description: "You’ve helped clear the air—CO₂ dodged thanks to your shares.",
                                        goal: 1500,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "cloud.sun")
                            
                            achievement(title: "🧘 Zen Paperless Master",
                                        description: "You’ve reached sharing serenity—2,000 pages and counting.",
                                        goal: 2000,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "figure.mind.and.body")
                            
                            achievement(title: "🧪 Sustainable Scientist",
                                        description: "You’re experimenting with paperless perfection. Results: impressive.",
                                        goal: 2500,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "testtube.2")
                            
                            achievement(title: "🛰 Eco Pioneer",
                                        description: "You’re sharing at orbital speeds. Next stop: a greener future.",
                                        goal: 3000,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "satellite")
                            
                            achievement(title: "🛸 Planet Level: Expert",
                                        description: "You’ve gone intergalactic with your green impact. Beam us up!",
                                        goal: 3500,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "sparkles")
                            
                            achievement(title: "🏆 Legendary Earth Ally",
                                        description: "A forest’s worth of shared pages. Earth salutes you.",
                                        goal: 4000,
                                        progress: profileViewModel.ecoAchievements,
                                        iconName: "trophy")
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
                }
                .overlay(
                    // MARK: chevron button in top-left
                    HStack {
                        Button(action: {
                            dismiss()
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

