import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: FoodViewModel
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Double = 2200
    @State private var showAddFood = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                let todayFoods = viewModel.foods(for: Date())
                let totalCalories = todayFoods.reduce(0.0) { $0 + Double($1.calories) }
                let totalCarbs = todayFoods.reduce(0.0) { $0 + $1.carbs }
                let totalProtein = todayFoods.reduce(0.0) { $0 + $1.protein }
                let totalFat = todayFoods.reduce(0.0) { $0 + $1.fat }
                let progress = totalCalories / dailyCalorieGoal

                VStack(alignment: .leading, spacing: 24) {
                    
                    // 🗓️ Dato
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).year()).capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    // 🔥 Kalorier – hovedkort
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color("AppGreen"), Color("AppGreen").opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(radius: 3)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Dagens inntak")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("\(Int(totalCalories)) kcal")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            ProgressView(value: totalCalories, total: dailyCalorieGoal)
                                .tint(.white)
                                .animation(.easeInOut(duration: 0.4), value: totalCalories)
                            Text("\(Int(totalCalories)) / \(Int(dailyCalorieGoal)) kcal")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))
                            Text(motivationText(progress: progress))
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.top, 4)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                    
                    // 📊 Makrofordeling – tre kort
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Makrofordeling")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            macroCard(title: "Karbohydrater", value: totalCarbs, color: .orange)
                            macroCard(title: "Proteiner", value: totalProtein, color: .blue)
                            macroCard(title: "Fett", value: totalFat, color: .pink)
                        }
                    }
                    
                    // 🍽️ Matvarer logget
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Matvarer logget i dag")
                            .font(.headline)
                        
                        if todayFoods.isEmpty {
                            VStack(spacing: 8) {
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
                            .padding(.vertical, 20)
                        } else {
                            ForEach(todayFoods) { food in
                                HStack {
                                    Text(food.name ?? "Ukjent")
                                    Spacer()
                                    Text("\(Int(food.calories)) kcal")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hjem")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showAddFood) {
                AddFoodView()
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Kort for makroer
    private func macroCard(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value)) g")
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func motivationText(progress: Double) -> String {
        switch progress {
        case 0..<0.5:
            return "God start! Fortsett å logge 💪"
        case 0.5..<0.9:
            return "Bra jobba! Du nærmer deg målet 🥗"
        case 0.9..<1.1:
            return "Fantastisk! Du nådde målet 🎯"
        default:
            return "Wow! Du har overgått målet ditt 🔥"
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(FoodViewModel())
}
