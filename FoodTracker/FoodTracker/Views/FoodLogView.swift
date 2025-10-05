import SwiftUI

struct FoodLogView: View {
    @EnvironmentObject var viewModel: FoodViewModel
    @State private var showingAddFood = false
    @State private var selectedMealTypeForAdd: String?
    @State private var selectedDate = Date()

    private let mealOrder = ["frokost", "lunsj", "middag", "snacks"]

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Dato-navigasjon
                HStack {
                    Button {
                        changeDate(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Button {
                        changeDate(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(Calendar.current.isDateInToday(selectedDate))
                }
                .padding(.horizontal)

                // MARK: - Måltidsseksjoner
                List {
                    ForEach(mealOrder, id: \.self) { meal in
                        let todaysFoods = viewModel.foods(for: selectedDate)
                        let itemsForMeal = todaysFoods.filter { $0.mealType == meal }

                        Section(header: Text(meal.capitalized)) {
                            if itemsForMeal.isEmpty {
                                Text("Ingen registrerte matvarer")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(itemsForMeal) { item in
                                    HStack {
                                        Text(item.name ?? "")
                                        Spacer()
                                        Text("\(item.calories) kcal")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .onDelete { indexSet in
                                    indexSet.map { itemsForMeal[$0] }.forEach(viewModel.deleteFood)
                                }
                            }

                            // Legg til-knapp for denne seksjonen
                            Button {
                                selectedMealTypeForAdd = meal
                                showingAddFood = true
                            } label: {
                                Label("Legg til i \(meal)", systemImage: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Matlogg")
            .sheet(isPresented: $showingAddFood) {
                if let mealType = selectedMealTypeForAdd {
                    AddFoodView(preselectedMealType: mealType)
                }
            }
        }
    }

    // MARK: - Endre valgt dato
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
