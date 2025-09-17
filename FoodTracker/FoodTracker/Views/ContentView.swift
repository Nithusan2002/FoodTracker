//
//  ContentView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FoodViewModel
    @State private var showingAddFood = false
    @State private var showingProfile = false
    @State private var showingNotifications = false

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if viewModel.foods.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Ingen matvarer registrert ennå")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(viewModel.foods) { item in
                            HStack {
                                Text(item.name ?? "")
                                Spacer()
                                Text("\(item.calories) kcal")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { viewModel.foods[$0] }.forEach(viewModel.deleteFood)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Food Tracker")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { showingNotifications = true } label: {
                            Image(systemName: "bell")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingProfile = true } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingProfile) {
                    // ProfileView()
                }
                .sheet(isPresented: $showingNotifications) {
                    // NotificationsView()
                }

                // Flytende pluss-knapp
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddFood = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        .sheet(isPresented: $showingAddFood) {
                            AddFoodView(viewModel: viewModel)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FoodViewModel())
}

