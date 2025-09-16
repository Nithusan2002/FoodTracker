//
//  FoodTrackerApp.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 15/09/2025.
//

import SwiftUI

@main
struct FoodTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
