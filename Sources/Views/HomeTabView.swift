import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var projectStore: ProjectStore
    @State private var selectedTab = 0
    @State private var showLogin = false
    
    var body: some View {
        if authStore.isAuthenticated {
            TabView(selection: $selectedTab) {
                ProjectListView()
                    .tabItem {
                        Label("项目", systemImage: "film")
                    }
                    .tag(0)
                
                SeriesListView()
                    .tabItem {
                        Label("作品", systemImage: "photo.on.rectangle")
                    }
                    .tag(1)
                
                ModelListView()
                    .tabItem {
                        Label("模型", systemImage: "cpu")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
                    .tag(3)
            }
            .tint(Color.aiPrimary)
            .preferredColorScheme(.dark)
            .onAppear {
                Task {
                    await projectStore.loadProjects()
                    await projectStore.loadSeries()
                }
            }
        } else {
            LoginView()
                .environmentObject(authStore)
        }
    }
}
