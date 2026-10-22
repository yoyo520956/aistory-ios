import SwiftUI

@main
struct AIStoryApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var modelStore = ModelStore()
    
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .environmentObject(authStore)
                .environmentObject(projectStore)
                .environmentObject(modelStore)
        }
    }
}
