import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: FoodViewModel

    // Mål fra Settings
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Double = 2200
    @AppStorage("carbPct") private var carbPct: Double = 40
    @AppStorage("proteinPct") private var proteinPct: Double = 30
    @AppStorage("fatPct") private var fatPct: Double = 30

    // UI-state
    @State private var showAddFood = false
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {

                // MARK: - Data for valgt dato
                let foods = viewModel.foods(for: selectedDate)
                let totalCalories = foods.reduce(0.0) { $0 + Double($1.calories) }
                let totalCarbs    = foods.reduce(0.0) { $0 + $1.carbs }
                let totalProtein  = foods.reduce(0.0) { $0 + $1.protein }
                let totalFat      = foods.reduce(0.0) { $0 + $1.fat }

                let goal = max(dailyCalorieGoal, 1) // unngå deling på 0
                let progress = min(totalCalories / goal, 1)

                // Makromål (gram) fra Settings
                let carbGoalG    = (goal * (carbPct/100)) / 4.0
                let proteinGoalG = (goal * (proteinPct/100)) / 4.0
                let fatGoalG     = (goal * (fatPct/100)) / 9.0

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Dato-velger
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Button { bumpDay(-1) } label: {
                                    Image(systemName: "chevron.left")
                                }
                                .buttonStyle(.plain)

                                Spacer(minLength: 8)

                                DatePicker(
                                    "",
                                    selection: $selectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()

                                Spacer(minLength: 8)

                                Button { bumpDay(+1) } label: {
                                    Image(systemName: "chevron.right")
                                }
                                .buttonStyle(.plain)
                            }

                            Text(selectedDate.formatted(
                                .dateTime
                                    .weekday(.wide)
                                    .day()
                                    .month(.wide)
                                    .year()
                                    .locale(Locale(identifier: "nb_NO"))
                            ).capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }

                    // MARK: Header-kort (kalorier)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.cyan.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Dagens inntak", systemImage: "flame.fill")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.95))

                            Text("\(Int(totalCalories)) kcal")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            ProgressView(value: totalCalories, total: goal)
                                .tint(.white)
                                .animation(.easeInOut(duration: 0.35), value: totalCalories)

                            Text("\(Int(totalCalories)) / \(Int(goal)) kcal")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))

                            Text(motivationText(progress: progress))
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.top, 2)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)

                    // MARK: Makroer i dag (pen seksjon)
                    SectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Makroer i dag")
                                .font(.headline)

                            HStack(spacing: 12) {
                                MacroCard(icon: "leaf",
                                          title: "Karbohydrater",
                                          value: totalCarbs,
                                          goal: carbGoalG,
                                          tint: .orange)

                                MacroCard(icon: "bolt.fill",
                                          title: "Proteiner",
                                          value: totalProtein,
                                          goal: proteinGoalG,
                                          tint: .blue)

                                MacroCard(icon: "drop.fill",
                                          title: "Fett",
                                          value: totalFat,
                                          goal: fatGoalG,
                                          tint: .pink)
                            }
                        }
                    }

                    // MARK: Matvarer logget i dag (for valgt dato)
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Matvarer logget i dag")
                                .font(.headline)

                            if foods.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "leaf.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(Color("AppGreen"))
                                    Text("Ingen matvarer logget ennå 🌿")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Button {
                                        showAddFood = true
                                    } label: {
                                        Text("Legg til første måltid")
                                            .font(.callout.bold())
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color("AppGreen").opacity(0.15))
                                            .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(foods) { food in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(food.name ?? "Ukjent").font(.body)
                                                Text("\(Int(food.calories)) kcal • \(Int(food.protein))p / \(Int(food.carbs))c / \(Int(food.fat))f")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 10)
                                        Divider()
                                    }
                                }
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hjem")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFood = true
                    } label: {
                        Label("Legg til", systemImage: "plus.circle.fill")
                    }
                    .tint(Color("AppGreen"))
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView()
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Hjelpere

    private func bumpDay(_ delta: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: newDate)
        }
    }

    private func motivationText(progress: Double) -> String {
        switch progress {
        case ..<0.5:   return "God start! Fortsett å logge 💪"
        case ..<0.9:   return "Bra flyt – nesten i mål 🥗"
        case ..<1.1:   return "Nailed it! Dagens mål nådd 🎯"
        default:       return "Over mål – fint om det var planlagt 🔥"
        }
    }
}

// MARK: - Gjenbrukbare UI-byggesteiner

/// Ramme for seksjoner (kort bakgrunn med skygge)
private struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
    }
}

/// Makro-kort med ikon, %-chip, “inntak / mål” og progressbar
private struct MacroCard: View {
    let icon: String
    let title: String
    let value: Double
    let goal: Double
    let tint: Color

    var body: some View {
        let clampedGoal = max(goal, 1)
        let pct = min(max(value / clampedGoal, 0), 1)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(tint)
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(tint.opacity(0.12))
                    .foregroundColor(tint)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(value)) g")
                    .font(.headline)
                    .foregroundColor(tint)
                Text("av \(Int(clampedGoal)) g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: pct)
                .tint(tint)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.black.opacity(0.04))
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(FoodViewModel())
}
