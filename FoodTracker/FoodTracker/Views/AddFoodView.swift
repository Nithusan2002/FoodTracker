//
//  AddFoodView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 16/09/2025.
//

import SwiftUI

struct AddFoodView: View {
    @ObservedObject var viewModel: FoodViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var calories = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Food Details")) {
                    TextField("Name", text: $name)
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let cal = Int(calories), !name.isEmpty {
                            viewModel.addFood(name: name, calories: cal)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Int(calories) == nil)
                }
            }
        }
    }
}
