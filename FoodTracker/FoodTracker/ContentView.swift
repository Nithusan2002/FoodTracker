//
//  ContentView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FoodViewModel()
    @State private var showingAddFood = false

    var body: some View {
        NavigationView {
            List {
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
            .navigationTitle("Food Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(viewModel: viewModel)
            }
        }
    }
}



#Preview {
    ContentView()
}
