//
//  ContentView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 15/09/2025.
//

import SwiftUI

struct ContentView: View {
    let foods = [
            FoodItem(name: "Eple", calories: 52),
            FoodItem(name: "Banan", calories: 89),
            FoodItem(name: "Kyllingfilet", calories: 165)
        ]
        
        var body: some View {
            NavigationView {
                List(foods) { food in
                    HStack {
                        Text(food.name)
                        Spacer()
                        Text("\(food.calories) kcal")
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Dagens mat")
            }
        }
}

#Preview {
    ContentView()
}
