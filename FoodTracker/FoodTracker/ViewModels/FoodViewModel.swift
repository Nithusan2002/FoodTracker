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
            return calendar.isDate(createdAt, inSameDayAs: date)
            }
            return false
        }
    }
    
    func addFood(name: String, calories: Int, carbs: Double?, protein: Double?, fat: Double?, barcode: String?, mealType: String) {
        let newItem = FoodItem(context: viewContext)
        newItem.name = name
        newItem.calories = Int32(calories)
        newItem.carbs = carbs ?? 0
        newItem.protein = protein ?? 0
        newItem.fat = fat ?? 0
        newItem.barcode = barcode
        newItem.mealType = mealType
        newItem.createdAt = Date()

        do {
            try viewContext.save()
            fetchFoods()
        } catch {
            print("Kunne ikke lagre matvaren: \(error.localizedDescription)")
        }
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
    
    func totalCalories(for date: Date) -> Int {
        let calendar = Calendar.current
        return foods
            .filter { food in
                guard let createdAt = food.createdAt else { return false }
                return calendar.isDate(createdAt, inSameDayAs: date)
            }
            .reduce(0) { sum, food in
                sum + Int(food.calories)
            }
    }
}

#Preview {
    HomeView()
        .environmentObject(FoodViewModel())
}
