import SwiftUI
import CoreData
import Charts

struct StatsView: View {
    @EnvironmentObject var viewModel: FoodViewModel

    private var last7DaysData: [(date: Date, calories: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        return days.map { day in
            let total = viewModel.foods(for: day).reduce(0) { $0 + Int($1.calories) }
            return (date: day, calories: total)
        }
    }

    private var todaysCalories: Int {
        viewModel.foods(for: Date()).reduce(0) { $0 + Int($1.calories) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Dagens total")
                        .font(.headline)
                    Text("\(todaysCalories) kcal")
                        .font(.largeTitle)
                        .bold()

                    Divider()

                    Chart {
                        ForEach(last7DaysData, id: \.date) { entry in
                            BarMark(
                                x: .value("Dato", entry.date, unit: .day),
                                y: .value("Kalorier", entry.calories)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading) {
                        Text("Dagens måltider")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.foods(for: Date()).isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Ingen matvarer registrert i dag")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            List {
                                ForEach(viewModel.foods(for: Date()), id: \.self) { food in
                                    HStack {
                                        Text(food.name ?? "")
                                        Spacer()
                                        Text("\(food.calories) kcal")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .frame(height: 250)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(FoodViewModel())
}
