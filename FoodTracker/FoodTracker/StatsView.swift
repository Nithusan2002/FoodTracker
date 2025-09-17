//
//  StatsView.swift
//  FoodTracker
//
//  Created by Nithusan Krishnasamymudali on 17/09/2025.
//

import SwiftUI
import CoreData

struct StatsView: View {
    @EnvironmentObject var viewModel: FoodViewModel

    private var todaysFoods: [FoodItem] {
        let calendar = Calendar.current
        return viewModel.foods.filter { food in
            if let date = food.createdAt {
                return calendar.isDateInToday(date)
            }
            return false
        }
    }

    private var todaysCalories: Int {
        todaysFoods.reduce(0) { $0 + Int($1.calories) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Dagens total")
                    .font(.headline)

                Text("\(todaysCalories) kcal")
                    .font(.largeTitle)
                    .bold()

                Divider()

                List {
                    Section(header: Text("Dagens måltider")) {
                        if todaysFoods.isEmpty {
                            Text("Ingen matvarer registrert i dag")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(todaysFoods, id: \.self) { food in
                                HStack {
                                    Text(food.name ?? "")
                                    Spacer()
                                    Text("\(food.calories) kcal")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(FoodViewModel())
}
