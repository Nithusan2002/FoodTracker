import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var moc
    @StateObject private var viewModel = FoodViewModel()

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .environment(\.managedObjectContext, moc)
                .tabItem {
                    Label("Hjem", systemImage: "house.fill")
                }

            /*
            HistoryView(viewModel: viewModel)
                .environment(\.managedObjectContext, moc)
                .tabItem {
                    Label("Historikk", systemImage: "clock.fill")
                }
            */
            FoodLogView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Matlogg", systemImage: "list.bullet")
                }

            StatsView()
                .tabItem {
                    Label("Statistikk", systemImage: "chart.bar.fill")
                }

            SettingsView()
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

