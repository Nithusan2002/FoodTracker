//
//  MainView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 17/09/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = FoodViewModel()

    var body: some View {
        TabView {
            ContentView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Foods", systemImage: "list.bullet")
                }
            
            StatsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(FoodViewModel())
}

