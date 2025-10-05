import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            Text("Profile coming soon")
                .foregroundColor(.white)
                .navigationTitle("Profile")
                .background(Color.black.ignoresSafeArea())
        }
    }
}

#Preview {
    ProfileView()
}
