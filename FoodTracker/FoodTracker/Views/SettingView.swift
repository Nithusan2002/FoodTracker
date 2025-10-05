import SwiftUI

struct SettingsView: View {
    // 🧠 Lagrer daglig mål og mørk modus i AppStorage
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Double = 2200
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // 👤 Profil
                Section(header: Text("Profil")) {
                    Text("Navn: Nithusan")
                    HStack {
                        Text("Kalorimål:")
                        Spacer()
                        Text("\(Int(dailyCalorieGoal)) kcal")
                            .foregroundColor(.secondary)
                    }
                    
                    // 🔧 Juster kalorimål
                    Stepper(value: $dailyCalorieGoal, in: 1200...4000, step: 100) {
                        Text("Endre mål")
                    }
                }
                
                // ⚙️ Appinnstillinger
                Section(header: Text("Appinnstillinger")) {
                    Toggle("Mørk modus", isOn: $darkModeEnabled)
                }
            }
            .navigationTitle("Innstillinger")
        }
        // 🎨 Endrer utseende dynamisk etter mørk modus
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}

#Preview {
    SettingsView()
}
