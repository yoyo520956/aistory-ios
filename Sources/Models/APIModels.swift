import Foundation

// MARK: - API Data Models

struct Project: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let originalTopic: String
    let description: String
    let status: String
    let statusDisplay: String
    let progressPercentage: Int
    let stagesCount: Int
    let completedStagesCount: Int
    let createdAt: String
    let seriesName: String?
    let episodeTitle: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, displayName, originalTopic, description, status
        case statusDisplay = "status_display"
        case progressPercentage = "progress_percentage"
        case stagesCount = "stages_count"
        case completedStagesCount = "completed_stages_count"
        case createdAt = "created_at"
        case seriesName = "series_name"
        case episodeTitle = "episode_title"
    }
    
    var isCompleted: Bool { status == "completed" }
    var isProcessing: Bool { status == "processing" || status == "paused" }
}

struct ProjectStage: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let stageType: String
    let stageTypeDisplay: String
    let status: String
    let statusDisplay: String
    let inputData: String?
    let outputData: String?
    
    enum CodingKeys: String, CodingKey {
        case id, stageType, status
        case stageTypeDisplay = "stage_type_display"
        case statusDisplay = "status_display"
        case inputData = "input_data"
        case outputData = "output_data"
    }
}

struct StoryboardItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let sequenceNumber: Int
    let sceneDescription: String
    let narrationText: String
    let imagePrompt: String
    let durationSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case sequenceNumber = "sequence_number"
        case sceneDescription
        case narrationText
        case imagePrompt
        case durationSeconds
    }
}

struct GeneratedImage: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let imageUrl: String
    let thumbnailUrl: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case imageUrl, thumbnailUrl, width, height
    }
}

struct GeneratedVideo: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let videoUrl: String
    let thumbnailUrl: String
    let duration: Int
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case videoUrl, thumbnailUrl, duration, width, height
    }
}

struct StorageImage: Codable, Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int
    let url: String
}

struct ServerConfig: Codable, Equatable, Hashable {
    var baseUrl: String
    var username: String
    var password: String
    var token: String
    
    init(baseUrl: String = "", username: String = "", password: String = "", token: String = "") {
        self.baseUrl = baseUrl
        self.username = username
        self.password = password
        self.token = token
    }
    
    var isAuthenticated: Bool {
        !token.isEmpty || (!username.isEmpty && !password.isEmpty)
    }
}

// MARK: - Parse Helpers

extension Project {
    static func fromListDict(_ dict: [String: Any]) -> Project? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let status = dict["status"] as? String else { return nil }
        return Project(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            displayName: dict["display_name"] as? String ?? name,
            originalTopic: dict["original_topic"] as? String ?? "",
            description: dict["description"] as? String ?? "",
            status: status,
            statusDisplay: dict["status_display"] as? String ?? status,
            progressPercentage: (dict["progress_percentage"] as? Int) ?? 0,
            stagesCount: (dict["stages_count"] as? Int) ?? 0,
            completedStagesCount: (dict["completed_stages_count"] as? Int) ?? 0,
            createdAt: dict["created_at"] as? String ?? "",
            seriesName: dict["series_name"] as? String,
            episodeTitle: dict["episode_title"] as? String
        )
    }
    
    static func fromDict(_ dict: [String: Any]) -> Project? {
        return fromListDict(dict)
    }
}
