//
//  FoodViewModel.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 16/09/2025.
//

import SwiftUI
import CoreData

class FoodViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext
    
    @Published var foods: [FoodItem] = []
    
    init() {
        fetchFoods()
    }
    
    func fetchFoods() {
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)]
        
        do {
            foods = try viewContext.fetch(request)
        } catch {
            print("Error fetching foods: \(error)")
        }
    }
    
    func addFood(name: String, calories: Int) {
        let newFood = FoodItem(context: viewContext)
        newFood.id = UUID()
        newFood.name = name
        newFood.calories = Int32(calories)
        
        saveContext()
        fetchFoods()
    }
    
    func deleteFood(_ food: FoodItem) {
        viewContext.delete(food)
        saveContext()
        fetchFoods()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}



