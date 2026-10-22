import SwiftUI

@main
struct AIStoryApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    appState.loadServerConfig()
                }
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label("首页", systemImage: "film.fill")
                }
                .tag(0)
            
            SettingsScreen()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(Color.aiPrimary)
    }
}
