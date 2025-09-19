import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: FoodViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Dato
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).year()).capitalized)                        .font(.title2)
                        .bold()

                    // Kalorier spist hittil
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kalorier spist i dag")
                            .font(.headline)
                        Text("\(totalCaloriesToday(), specifier: "%.0f") kcal")
                            .font(.largeTitle)
                            .bold()
                    }

                    // Makrofordeling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Makrofordeling")
                            .font(.headline)

                        HStack {
                            macroStat(title: "Karbohydrater", value: totalCarbsToday(), unit: "g")
                            Spacer()
                            macroStat(title: "Proteiner", value: totalProteinToday(), unit: "g")
                            Spacer()
                            macroStat(title: "Fett", value: totalFatToday(), unit: "g")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hjem")
        }
    }

    // MARK: - Makrostat komponent
    private func macroStat(title: String, value: Double, unit: String) -> some View {
        VStack {
            Text("\(value, specifier: "%.0f") \(unit)")
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Beregninger
    private func totalCaloriesToday() -> Double {
        viewModel.foods(for: Date())
            .reduce(0) { $0 + Double($1.calories) }
    }

    private func totalCarbsToday() -> Double {
        viewModel.foods(for: Date())
            .reduce(0.0) { $0 + ($1.carbs) }
    }

    private func totalProteinToday() -> Double {
        viewModel.foods(for: Date())
            .reduce(0.0) { $0 + ($1.protein) }
    }

    private func totalFatToday() -> Double {
        viewModel.foods(for: Date())
            .reduce(0.0) { $0 + ($1.fat) }
    }

}
