import SwiftUI

@main
struct AIStoryApp: App {
    @State private var authStore = AuthStore()
    @State private var projectStore = ProjectStore()
    @State private var modelStore = ModelStore()
    
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .environmentObject(authStore)
                .environmentObject(projectStore)
                .environmentObject(modelStore)
        }
    }
}
