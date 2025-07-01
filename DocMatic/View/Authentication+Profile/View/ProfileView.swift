//
//  ProfileView.swift
//  DocMatic
//
//  Created by Paul  on 6/29/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var showDeleteAlert: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        if let user = viewModel.currentUser {
            List {
                Section {
                    HStack {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(Color(.systemGray3))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.fullname)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)
                            
                            Text(user.email)
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                Section(header: Text("Account")) {
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        SettingsRowView(imageName: "arrow.left.circle.fill",
                                        title: "Sign Out",
                                        tintColor: .red)
                    }
                    .foregroundStyle(.primary)
                    
                    Button(action: {
                        Task {
                            await viewModel.deleteAccount()
                        }
                    }) {
                        SettingsRowView(imageName: "xmark.circle.fill",
                                        title: "Delete Account",
                                        tintColor: .red)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .overlay(
                // MARK: chevron button in top-left
                HStack {
                    Button(action: { dismiss() }) {
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

#Preview {
    ProfileView()
}
