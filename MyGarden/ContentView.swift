import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("Welcome to MyGarden")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your personal garden companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("MyGarden")
        }
    }
}

#Preview {
    ContentView()
}
