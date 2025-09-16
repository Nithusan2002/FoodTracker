//
//  ContentView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var vm = FoodViewModel()
    @State private var showingAddFood = false
    
    let foods = [
            FoodItem(name: "Eple", calories: 52),
            FoodItem(name: "Banan", calories: 89),
            FoodItem(name: "Kyllingfilet", calories: 165)
        ]
        
        var body: some View {
            NavigationStack {
                List(vm.foods) { food in
                    HStack {
                        Text(food.name)
                        Spacer()
                        Text("\(food.calories) kcal")
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Dagens mat")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddFood = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingAddFood) {
                    AddFoodView { name, calories in
                        vm.addFood(name: name, calories: calories)
                    }
                }
            }
        }
}

#Preview {
    ContentView()
}
