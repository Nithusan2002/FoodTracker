import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profil")) {
                    Text("Navn: Nithusan")
                    Text("Kalorimål: 2500 kcal")
                }
                Section(header: Text("Appinnstillinger")) {
                    Toggle("Mørk modus", isOn: .constant(false))
                }
            }
            .navigationTitle("Innstillinger")
        }
    }
}


#Preview {
    SettingsView()
}
