//
//  FoodViewModel.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 16/09/2025.
//

import SwiftUI

@Observable
class FoodViewModel {
    var foods: [FoodItem] = []
    
    func addFood(name: String, calories: Int) {
        let item = FoodItem(name: name, calories: calories)
        foods.append(item)
    }
}

