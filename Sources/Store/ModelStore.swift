import Foundation
import SwiftUI

@Observable
class ModelStore {
    var providers: [ModelProvider] = []
    var isLoading = false
    var lastError: String?
    
    // MARK: - Load
    
    func loadProviders() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            providers = try await APIClient.shared.fetchModelProviders()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - Create
    
    func createProvider(_ req: ModelProviderCreateRequest) async throws -> ModelProvider {
        let p = try await APIClient.shared.createModelProvider(req)
        providers.insert(p, at: 0)
        return p
    }
    
    // MARK: - Update
    
    func updateProvider(id: UUID, _ req: ModelProviderCreateRequest) async throws {
        _ = try await APIClient.shared.updateModelProvider(id: id, req)
        if let i = providers.firstIndex(where: { $0.id == id }) {
            providers[i] = try await APIClient.shared.fetchModelProviders().first { $0.id == id } ?? providers[i]
        }
    }
    
    // MARK: - Delete
    
    func deleteProvider(_ id: UUID) async throws {
        try await APIClient.shared.deleteModelProvider(id: id)
        providers.removeAll { $0.id == id }
    }
    
    // MARK: - Test
    
    func testProvider(id: UUID, prompt: String) async throws -> Bool {
        return try await APIClient.shared.testModelProvider(id: id, prompt: prompt)
    }
    
    // MARK: - Filter
    
    func providers(for type: String) -> [ModelProvider] {
        providers.filter { $0.providerType == type && $0.isActive }
    }
}
