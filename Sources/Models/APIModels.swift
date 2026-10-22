import Foundation
import SwiftUI

// MARK: - Series Models

struct Series: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var episodesCount: Int
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case episodesCount = "episodes_count"
        case createdAt = "created_at"
    }
}

extension Series {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        episodesCount = (try? c.decode(Int.self, forKey: .episodesCount)) ?? 0
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
    }
}

struct SeriesDetail: Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var episodes: [Project]
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description, episodes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension SeriesDetail {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        episodes = (try? c.decode([Project].self, forKey: .episodes)) ?? []
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
    }
}

// MARK: - Project Models

struct Project: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var displayName: String
    var description: String
    var originalTopic: String
    var status: String
    var statusDisplay: String
    var progressPercentage: Double
    var stagesCount: Int
    var completedStagesCount: Int
    var failedStagesCount: Int
    var createdAt: String
    var updatedAt: String
    var completedAt: String?
    var seriesName: String?
    var seriesId: UUID?
    var episodeTitle: String?
    var episodeNumber: Int?
    var screenplayId: UUID?
    var jianyingDraftPath: String?
    var promptSetId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case displayName = "display_name"
        case originalTopic = "original_topic"
        case statusDisplay = "status_display"
        case progressPercentage = "progress_percentage"
        case stagesCount = "stages_count"
        case completedStagesCount = "completed_stages_count"
        case failedStagesCount = "failed_stages_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case seriesId = "series"
        case seriesName = "series_name"
        case episodeTitle = "episode_title"
        case episodeNumber = "episode_number"
        case screenplayId = "screenplay"
        case jianyingDraftPath = "jianying_draft_path"
        case promptSetId = "prompt_template_set"
    }

    var isCompleted: Bool { status == "completed" }
    var isProcessing: Bool { status == "processing" || status == "queued" }
    var isFailed: Bool { status == "failed" }
}

extension Project {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        displayName = (try? c.decode(String.self, forKey: .displayName)) ?? name
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        originalTopic = (try? c.decode(String.self, forKey: .originalTopic)) ?? ""
        status = (try? c.decode(String.self, forKey: .status)) ?? "draft"
        statusDisplay = (try? c.decode(String.self, forKey: .statusDisplay)) ?? status
        progressPercentage = (try? c.decode(Double.self, forKey: .progressPercentage)) ?? 0
        stagesCount = (try? c.decode(Int.self, forKey: .stagesCount)) ?? 0
        completedStagesCount = (try? c.decode(Int.self, forKey: .completedStagesCount)) ?? 0
        failedStagesCount = (try? c.decode(Int.self, forKey: .failedStagesCount)) ?? 0
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
        completedAt = try? c.decodeIfPresent(String.self, forKey: .completedAt)
        seriesId = try? c.decodeIfPresent(UUID.self, forKey: .seriesId)
        seriesName = try? c.decodeIfPresent(String.self, forKey: .seriesName)
        episodeTitle = try? c.decodeIfPresent(String.self, forKey: .episodeTitle)
        episodeNumber = try? c.decodeIfPresent(Int.self, forKey: .episodeNumber)
        screenplayId = try? c.decodeIfPresent(UUID.self, forKey: .screenplayId)
        jianyingDraftPath = try? c.decodeIfPresent(String.self, forKey: .jianyingDraftPath)
        promptSetId = try? c.decodeIfPresent(UUID.self, forKey: .promptSetId)
    }
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
    var id: UUID
    var stageType: String
    var stageTypeDisplay: String
    var status: String
    var statusDisplay: String
    var inputData: JSONValue?
    var outputData: JSONValue?
    var retryCount: Int
    var errorMessage: String?
    var startedAt: String?
    var completedAt: String?
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case stageType = "stage_type"
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

extension ProjectStage {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        stageType = (try? c.decode(String.self, forKey: .stageType)) ?? ""
        stageTypeDisplay = (try? c.decode(String.self, forKey: .stageTypeDisplay)) ?? stageType
        status = (try? c.decode(String.self, forKey: .status)) ?? "pending"
        statusDisplay = (try? c.decode(String.self, forKey: .statusDisplay)) ?? status
        inputData = try? c.decodeIfPresent(JSONValue.self, forKey: .inputData)
        outputData = try? c.decodeIfPresent(JSONValue.self, forKey: .outputData)
        retryCount = (try? c.decode(Int.self, forKey: .retryCount)) ?? 0
        errorMessage = try? c.decodeIfPresent(String.self, forKey: .errorMessage)
        startedAt = try? c.decodeIfPresent(String.self, forKey: .startedAt)
        completedAt = try? c.decodeIfPresent(String.self, forKey: .completedAt)
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
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
        case .imageEdit: return "slider.horizontal.3"
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
    var id: UUID
    var name: String
    var providerType: String
    var executorClass: String
    var apiUrl: String
    var apiKey: String
    var modelName: String
    var maxTokens: Int
    var temperature: Double
    var topP: Double
    var timeout: Int
    var isActive: Bool
    var priority: Int
    var rateLimitRPM: Int
    var rateLimitRPD: Int
    var extraConfig: JSONValue?
    var createdAt: String
    var updatedAt: String

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

extension ModelProvider {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        providerType = (try? c.decode(String.self, forKey: .providerType)) ?? "llm"
        executorClass = (try? c.decode(String.self, forKey: .executorClass)) ?? ""
        apiUrl = (try? c.decode(String.self, forKey: .apiUrl)) ?? ""
        apiKey = (try? c.decode(String.self, forKey: .apiKey)) ?? ""
        modelName = (try? c.decode(String.self, forKey: .modelName)) ?? ""
        maxTokens = (try? c.decode(Int.self, forKey: .maxTokens)) ?? 2000
        temperature = (try? c.decode(Double.self, forKey: .temperature)) ?? 0.7
        topP = (try? c.decode(Double.self, forKey: .topP)) ?? 1.0
        timeout = (try? c.decode(Int.self, forKey: .timeout)) ?? 60
        isActive = (try? c.decode(Bool.self, forKey: .isActive)) ?? true
        priority = (try? c.decode(Int.self, forKey: .priority)) ?? 0
        rateLimitRPM = (try? c.decode(Int.self, forKey: .rateLimitRPM)) ?? 60
        rateLimitRPD = (try? c.decode(Int.self, forKey: .rateLimitRPD)) ?? 1000
        extraConfig = try? c.decodeIfPresent(JSONValue.self, forKey: .extraConfig)
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
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
}

// MARK: - Asset Models

struct GlobalVariable: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var key: String
    var group: String
    var description: String
    var variableType: String
    var scope: String
    var scopeDisplay: String
    var isActive: Bool
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, key, group, description, scope
        case variableType = "variable_type"
        case scopeDisplay = "scope_display"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

extension GlobalVariable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        key = (try? c.decode(String.self, forKey: .key)) ?? ""
        group = (try? c.decode(String.self, forKey: .group)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        variableType = (try? c.decode(String.self, forKey: .variableType)) ?? ""
        scope = (try? c.decode(String.self, forKey: .scope)) ?? ""
        scopeDisplay = (try? c.decode(String.self, forKey: .scopeDisplay)) ?? scope
        isActive = (try? c.decode(Bool.self, forKey: .isActive)) ?? true
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
    }
}

// MARK: - Prompt Models

struct PromptTemplate: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var stageType: String
    var systemPrompt: String
    var userPrompt: String
    var isLocked: Bool
    var isActive: Bool
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, isLocked, isActive
        case stageType = "stage_type"
        case systemPrompt = "system_prompt"
        case userPrompt = "user_prompt"
        case createdAt = "created_at"
    }
}

extension PromptTemplate {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        stageType = (try? c.decode(String.self, forKey: .stageType)) ?? ""
        systemPrompt = (try? c.decode(String.self, forKey: .systemPrompt)) ?? ""
        userPrompt = (try? c.decode(String.self, forKey: .userPrompt)) ?? ""
        isLocked = (try? c.decode(Bool.self, forKey: .isLocked)) ?? false
        isActive = (try? c.decode(Bool.self, forKey: .isActive)) ?? true
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
    }
}

struct PromptTemplateSet: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var isDefault: Bool
    var templates: [PromptTemplate]
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, templates
        case isDefault = "is_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension PromptTemplateSet {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        isDefault = (try? c.decode(Bool.self, forKey: .isDefault)) ?? false
        templates = (try? c.decode([PromptTemplate].self, forKey: .templates)) ?? []
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
    }
}

// MARK: - Screenplay Models

struct Screenplay: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var totalEpisodes: Int
    var completedEpisodes: Int
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case totalEpisodes = "total_episodes"
        case completedEpisodes = "completed_episodes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Screenplay {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        totalEpisodes = (try? c.decode(Int.self, forKey: .totalEpisodes)) ?? 0
        completedEpisodes = (try? c.decode(Int.self, forKey: .completedEpisodes)) ?? 0
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
    }
}

struct Episode: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var number: Int
    var title: String
    var content: String
    var projectId: UUID?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, number, title, content
        case projectId = "project_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Episode {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        number = (try? c.decode(Int.self, forKey: .number)) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        projectId = try? c.decodeIfPresent(UUID.self, forKey: .projectId)
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decode(String.self, forKey: .updatedAt)) ?? ""
    }
}

// MARK: - Generic List Response

struct PaginatedResponse<T: Codable>: Codable {
    var count: Int
    var next: String?
    var previous: String?
    var results: [T]

    enum CodingKeys: String, CodingKey {
        case count, next, previous, results
    }
}

extension PaginatedResponse {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = (try? c.decode(Int.self, forKey: .count)) ?? 0
        next = try? c.decodeIfPresent(String.self, forKey: .next)
        previous = try? c.decodeIfPresent(String.self, forKey: .previous)
        results = (try? c.decode([T].self, forKey: .results)) ?? []
    }
}
