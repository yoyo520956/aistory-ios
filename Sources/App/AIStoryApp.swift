import SwiftUI

@main
struct AIStoryApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear { appState.loadServerConfig() }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var tab = 0
    
    var body: some View {
        TabView(selection: $tab) {
            HomeScreen()
                .tabItem { Label("项目", systemImage: "film") }
                .tag(0)
            SettingsScreen()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(1)
        }
        .tint(Color.aiPrimary)
        .preferredColorScheme(.dark)
    }
}
