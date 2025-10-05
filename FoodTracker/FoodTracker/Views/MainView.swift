import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var moc
    @StateObject private var viewModel = FoodViewModel()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(viewModel) // 👈 Legg viewModel i miljøet
                .environment(\.managedObjectContext, moc)
                .tabItem {
                    Label("Hjem", systemImage: "house.fill")
                }

            FoodLogView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Matlogg", systemImage: "list.bullet")
                }

            StatsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Statistikk", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Innstillinger", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(FoodViewModel())
}
