import SwiftUI
import Combine

// MARK: - App State (iOS 16 compatible: ObservableObject)

class AppState: ObservableObject {
    @Published var serverConfig = ServerConfig()
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var selectedProject: Project?
    @Published var lastError: String?
    
    private let configKey = "ai_story_server_config"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() { loadServerConfig() }
    
    // MARK: - Config Persistence
    
    func loadServerConfig() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? decoder.decode(ServerConfig.self, from: data) {
            serverConfig = config
            APIClient.shared.updateConfig(config)
        }
    }
    
    func saveServerConfig(_ config: ServerConfig) {
        serverConfig = config
        APIClient.shared.updateConfig(config)
        if let data = try? encoder.encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }
    
    // MARK: - Projects
    
    func loadProjects() async {
        isLoading = true; lastError = nil
        defer { isLoading = false }
        do { projects = try await APIClient.shared.fetchProjects() }
        catch { lastError = "加载项目失败：\(error.localizedDescription)" }
    }
    
    func createProject(name: String, topic: String) async {
        isLoading = true; lastError = nil
        defer { isLoading = false }
        do {
            let p = try await APIClient.shared.createProject(name: name, topic: topic)
            projects.insert(p, at: 0)
            selectedProject = p
        } catch { lastError = error.localizedDescription }
    }
    
    func refreshProject(_ id: UUID) async {
        do {
            let p = try await APIClient.shared.fetchProject(id: id)
            if let i = projects.firstIndex(where: { $0.id == id }) { projects[i] = p }
            if selectedProject?.id == id { selectedProject = p }
        } catch { lastError = error.localizedDescription }
    }
    
    func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        if selectedProject?.id == id { selectedProject = nil }
    }
}
