//
//  AddFoodView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 16/09/2025.
//

import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var calories = ""
    
    var onSave: (String, Int) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Navn på matvare", text: $name)
                TextField("Kalorier", text: $calories)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Legg til mat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        if let cal = Int(calories) {
                            onSave(name, cal)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || Int(calories) == nil)
                }
            }
        }
    }
}
