import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var modelStore: ModelStore
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        ProjectListView()
                    }
                    .tabItem { Label("项目", systemImage: "film") }
                    .tag(0)

                    NavigationStack {
                        SeriesListView()
                    }
                    .tabItem { Label("作品", systemImage: "rectangle.stack") }
                    .tag(1)

                    NavigationStack {
                        ScreenplayListView()
                    }
                    .tabItem { Label("剧本", systemImage: "doc.text") }
                    .tag(2)

                    NavigationStack {
                        AssetListView()
                    }
                    .tabItem { Label("资产", systemImage: "person.crop.rectangle.stack") }
                    .tag(3)

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem { Label("设置", systemImage: "gearshape") }
                    .tag(4)
                }
                .tint(Color.aiPrimary)
                .preferredColorScheme(.dark)
                .task {
                    await projectStore.loadProjects()
                    await projectStore.loadSeries()
                }
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
