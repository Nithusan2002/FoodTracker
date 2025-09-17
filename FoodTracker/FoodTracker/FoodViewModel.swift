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
        backfillCreatedAtIfNeeded()
    }
    
    func fetchFoods() {
        let request: NSFetchRequest<FoodItem> = FoodItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \FoodItem.createdAt, ascending: false)
        ]
        do {
            foods = try viewContext.fetch(request)
        } catch {
            print("Error fetching foods: \(error)")
        }
    }
    
    func foods(for date: Date) -> [FoodItem] {
        let calendar = Calendar.current
        return foods.filter { item in
            if let createdAt = item.createdAt {
             j   return calendar.isDate(createdAt, inSameDayAs: date)
            }
            return false
        }
    }
    
    func addFood(name: String, calories: Int) {
        let newFood = FoodItem(context: viewContext)
        newFood.id = UUID()
        newFood.name = name
        newFood.calories = Int32(calories)
        newFood.createdAt = Date() // NY LINJE
        
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
    
    func backfillCreatedAtIfNeeded() {
        var changed = false
        for item in foods where item.createdAt == nil {
            item.createdAt = Date()
            changed = true
        }
        if changed { saveContext() }
    }
}

#Preview {
    ContentView()
        .environmentObject(FoodViewModel())
}


