import Foundation
import SwiftUI

@Observable
class AuthStore {
    var config = ServerConfig()
    var currentUser: UserInfo?
    var isAuthenticated = false
    var isLoading = false
    var lastError: String?
    
    private let configKey = "ai_story_server_config"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        loadConfig()
    }
    
    // MARK: - Config Persistence
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let cfg = try? decoder.decode(ServerConfig.self, from: data) {
            config = cfg
            APIClient.shared.updateConfig(cfg)
            isAuthenticated = cfg.isAuthenticated
        }
    }
    
    func saveConfig() {
        if let data = try? encoder.encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
        APIClient.shared.updateConfig(config)
        isAuthenticated = config.isAuthenticated
    }
    
    // MARK: - Login
    
    func login(username: String, password: String) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIClient.shared.login(username: username, password: password)
            config.accessToken = response.access
            config.refreshToken = response.refresh
            if let user = response.user {
                currentUser = user
            }
            isAuthenticated = true
            saveConfig()
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    func register(username: String, password: String, email: String? = nil) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let response = try await APIClient.shared.register(username: username, password: password, email: email)
            config.accessToken = response.access
            config.refreshToken = response.refresh
            isAuthenticated = true
            saveConfig()
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    func logout() {
        config = .defaults
        currentUser = nil
        isAuthenticated = false
        saveConfig()
    }
    
    // MARK: - Server Test
    
    func testConnection(baseUrl: String) async throws -> Bool {
        config.baseUrl = baseUrl
        saveConfig()
        
        do {
            _ = try await APIClient.shared.getMe()
            return true
        } catch {
            throw APIError.serverError("连接失败：\(error.localizedDescription)")
        }
    }
}
