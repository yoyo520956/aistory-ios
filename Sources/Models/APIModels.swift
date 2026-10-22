import Foundation

// MARK: - Series Models

struct Series: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let episodesCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case episodesCount = "episodes_count"
        case createdAt = "created_at"
    }
}

struct SeriesDetail: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let episodes: [Project]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, episodes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Project Models

struct Project: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let description: String
    let originalTopic: String
    let status: String
    let statusDisplay: String
    let progressPercentage: Double
    let stagesCount: Int
    let completedStagesCount: Int
    let failedStagesCount: Int
    let createdAt: String
    let updatedAt: String
    let completedAt: String?
    let seriesName: String?
    let seriesId: UUID?
    let episodeTitle: String?
    let episodeNumber: Int?
    let screenplayId: UUID?
    let jianyingDraftPath: String?
    let promptSetId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, originalTopic, status
        case displayName = "display_name"
        case progressPercentage = "progress_percentage"
        case stagesCount = "stages_count"
        case completedStagesCount = "completed_stages_count"
        case failedStagesCount = "failed_stages_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case seriesName = "series_name"
        case seriesId = "series_id"
        case episodeTitle = "episode_title"
        case episodeNumber = "episode_number"
        case screenplayId = "screenplay_id"
        case jianyingDraftPath = "jianying_draft_path"
        case promptSetId = "prompt_template_set"
    }
    
    var isCompleted: Bool { status == "completed" }
    var isProcessing: Bool { status == "processing" || status == "queued" }
    var isFailed: Bool { status == "failed" }
}

struct ProjectCreateRequest: Encodable {
    let name: String
    let original_topic: String
    let description: String?
    let series_id: UUID?
    let episode_title: String?
    let episode_number: Int?
}

// MARK: - Stage Models

struct ProjectStage: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let stageType: String
    let stageTypeDisplay: String
    let status: String
    let statusDisplay: String
    let inputData: [String: Any]?
    let outputData: [String: Any]?
    let retryCount: Int
    let errorMessage: String?
    let startedAt: String?
    let completedAt: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, stageType, status
        case stageTypeDisplay = "stage_type_display"
        case statusDisplay = "status_display"
        case inputData = "input_data"
        case outputData = "output_data"
        case retryCount = "retry_count"
        case errorMessage = "error_message"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}

enum StageType: String, CaseIterable, Identifiable {
    case rewrite
    case assetExtraction = "asset_extraction"
    case storyboard
    case imageGeneration = "image_generation"
    case multiGridImage = "multi_grid_image"
    case cameraMovement = "camera_movement"
    case videoGeneration = "video_generation"
    case imageEdit = "image_edit"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rewrite: return "文案精修"
        case .assetExtraction: return "资产抽取"
        case .storyboard: return "分镜生成"
        case .imageGeneration: return "图片生成"
        case .multiGridImage: return "多宫格图片"
        case .cameraMovement: return "运镜生成"
        case .videoGeneration: return "视频生成"
        case .imageEdit: return "图片编辑"
        }
    }
    
    var iconName: String {
        switch self {
        case .rewrite: return "pencil"
        case .assetExtraction: return "brain"
        case .storyboard: return "viewfinder"
        case .imageGeneration: return "photo"
        case .multiGridImage: return "square.grid.2x2"
        case .cameraMovement: return "play.circle"
        case .videoGeneration: return "film"
        case .imageEdit: return "adjustments"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .rewrite: return .purple
        case .assetExtraction: return .orange
        case .storyboard: return .blue
        case .imageGeneration: return .yellow
        case .multiGridImage: return .mint
        case .cameraMovement: return .cyan
        case .videoGeneration: return .red
        case .imageEdit: return .pink
        }
    }
}

// MARK: - Model Provider Models

struct ModelProvider: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let providerType: String
    let executorClass: String
    let apiUrl: String
    let apiKey: String
    let modelName: String
    let maxTokens: Int
    let temperature: Double
    let topP: Double
    let timeout: Int
    let isActive: Bool
    let priority: Int
    let rateLimitRPM: Int
    let rateLimitRPD: Int
    let extraConfig: [String: Any]?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, apiUrl, modelName, maxTokens, temperature, topP, timeout, isActive, priority
        case providerType = "provider_type"
        case executorClass = "executor_class"
        case apiKey = "api_key"
        case rateLimitRPM = "rate_limit_rpm"
        case rateLimitRPD = "rate_limit_rpd"
        case extraConfig = "extra_config"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var providerTypeDisplay: String {
        switch providerType {
        case "llm": return "LLM模型"
        case "text2image": return "文生图"
        case "image2video": return "图生视频"
        case "image_edit": return "图片编辑"
        default: return providerType
        }
    }
}

struct ModelProviderCreateRequest: Encodable {
    let name: String
    let provider_type: String
    let executor_class: String
    let api_url: String
    let api_key: String
    let model_name: String
    let max_tokens: Int
    let temperature: Double
    let top_p: Double
    let timeout: Int
    let is_active: Bool
    let priority: Int
    let rate_limit_rpm: Int
    let rate_limit_rpd: Int
    let extra_config: [String: Any]?
}

// MARK: - Asset Models

struct GlobalVariable: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let key: String
    let group: String
    let description: String
    let variableType: String
    let scope: String
    let scopeDisplay: String
    let isActive: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, key, group, description, scope
        case variableType = "variable_type"
        case scopeDisplay = "scope_display"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Prompt Models

struct PromptTemplate: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let stageType: String
    let systemPrompt: String
    let userPrompt: String
    let isLocked: Bool
    let isActive: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, systemPrompt, userPrompt, isLocked, isActive
        case stageType = "stage_type"
        case createdAt = "created_at"
    }
}

struct PromptTemplateSet: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let isDefault: Bool
    let templates: [PromptTemplate]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, templates
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Screenplay Models

struct Screenplay: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let totalEpisodes: Int
    let completedEpisodes: Int
    let createdAt: String
    let updatedAt: String
}

struct Episode: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let number: Int
    let title: String
    let content: String
    let projectId: UUID?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, number, title, content
        case projectId = "project_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
