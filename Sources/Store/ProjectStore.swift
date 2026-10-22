import Foundation
import SwiftUI

ObservedObject
class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var series: [Series] = []
    @Published var selectedProject: Project?
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MARK: - Load
    
    func loadProjects(seriesId: UUID? = nil) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            projects = try await APIClient.shared.fetchProjects(seriesId: seriesId)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func loadSeries() async {
        do {
            series = try await APIClient.shared.fetchSeries()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func loadProject(id: UUID) async {
        do {
            selectedProject = try await APIClient.shared.fetchProject(id: id)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - Create
    
    func createProject(name: String, topic: String, seriesId: UUID? = nil, episodeTitle: String? = nil, episodeNumber: Int? = nil) async throws -> Project {
        let req = ProjectCreateRequest(
            name: name,
            original_topic: topic,
            description: nil,
            series_id: seriesId,
            episode_title: episodeTitle,
            episode_number: episodeNumber
        )
        let p = try await APIClient.shared.createProject(req)
        projects.insert(p, at: 0)
        return p
    }
    
    func createSeries(name: String, description: String) async throws -> Series {
        let s = try await APIClient.shared.createSeries(name: name, description: description)
        series.insert(s, at: 0)
        return s
    }
    
    // MARK: - Update
    
    func updateProject(id: UUID, name: String, topic: String, description: String) async throws {
        _ = try await APIClient.shared.updateProject(id: id, name: name, topic: topic, description: description)
        if let i = projects.firstIndex(where: { $0.id == id }) {
            projects[i].name = name
            projects[i].originalTopic = topic
        }
        if selectedProject?.id == id {
            selectedProject?.name = name
            selectedProject?.originalTopic = topic
        }
    }
    
    func updateSeries(id: UUID, name: String, description: String) async throws {
        _ = try await APIClient.shared.updateSeries(id: id, name: name, description: description)
        if let i = series.firstIndex(where: { $0.id == id }) {
            series[i].name = name
            series[i].description = description
        }
    }
    
    // MARK: - Delete
    
    func deleteProject(_ id: UUID) async throws {
        try await APIClient.shared.deleteProject(id: id)
        projects.removeAll { $0.id == id }
        if selectedProject?.id == id { selectedProject = nil }
    }
    
    func deleteSeries(_ id: UUID) async throws {
        try await APIClient.shared.deleteSeries(id: id)
        series.removeAll { $0.id == id }
    }
    
    // MARK: - Stage Execution
    
    func executeStage(projectId: UUID, stageName: String) async throws {
        try await APIClient.shared.executeStage(projectId: projectId, stageName: stageName)
    }
    
    func retryStage(projectId: UUID, stageName: String) async throws {
        try await APIClient.shared.retryStage(projectId: projectId, stageName: stageName)
    }
    
    func retryPipeline(projectId: UUID) async throws {
        try await APIClient.shared.retryPipeline(projectId: projectId)
    }
    
    func fetchStages(projectId: UUID) async throws -> [ProjectStage] {
        return try await APIClient.shared.fetchStages(projectId: projectId)
    }
    
    // MARK: - Refresh
    
    func refreshProject(_ id: UUID) async {
        do {
            let p = try await APIClient.shared.fetchProject(id: id)
            if let i = projects.firstIndex(where: { $0.id == id }) {
                projects[i] = p
            }
            if selectedProject?.id == id {
                selectedProject = p
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}
