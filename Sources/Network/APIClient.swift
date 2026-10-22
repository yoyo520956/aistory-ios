import Foundation

// MARK: - SSE Event Types

struct SSEEvent: Codable {
    let type: String
    let content: String?
    let token: String?
    let project_id: String?
    let stage: String?
    let message: String?
    let error: String?
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case type, content, token, message, error, data
        case project_id = "project_id"
        case stage
    }
}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()
    private var config: ServerConfig
    private let session: URLSession
    
    private init(config: ServerConfig = .init()) {
        self.config = config
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 120
        c.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: c)
    }
    
    func updateConfig(_ c: ServerConfig) { self.config = c }
    
    private var base: URL? {
        let b = config.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !b.isEmpty else { return nil }
        return URL(string: b.hasSuffix("/") ? String(b.dropLast()) : b)
    }
    
    private func authHeaders() -> [String: String] {
        var h = ["Content-Type": "application/json", "Accept": "application/json"]
        if !config.accessToken.isEmpty {
            h["Authorization"] = "Bearer \(config.accessToken)"
        } else if !config.username.isEmpty, !config.password.isEmpty {
            let credsData = "\(config.username):\(config.password)".data(using: .utf8) ?? Data()
            h["Authorization"] = "Basic \(credsData.base64EncodedString())"
        }
        return h
    }
    
    // MARK: - Generic Request
    
    private func request<T: Codable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let base = base else { throw APIError.invalidURL }
        var url = base.appendingPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path, isDirectory: false)
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.allHTTPHeaderFields = authHeaders()
        
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.networkError(NSError(domain: "x", code: -1)) }
        
        switch http.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401, 403:
            throw APIError.unauthorized
        case 500...599:
            let errMsg = String(data: data, encoding: .utf8) ?? "服务器错误"
            throw APIError.serverError(errMsg)
        default:
            throw APIError.httpError(http.statusCode)
        }
    }
    
    private func post<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", body: body)
    }
    
    private func put<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "PUT", body: body)
    }
    
    private func delete<T: Codable>(_ path: String) async throws -> T {
        try await request(path, method: "DELETE")
    }
    
    // MARK: - Auth
    
    func login(username: String, password: String) async throws -> LoginResponse {
        struct Req: Encodable { let username: String; let password: String }
        let r: LoginResponse = try await post("api/v1/auth/login", body: Req(username: username, password: password))
        return r
    }
    
    func register(username: String, password: String, email: String?) async throws -> LoginResponse {
        struct Req: Encodable { let username: String; let password: String; let email: String? }
        let r: LoginResponse = try await post("api/v1/auth/register", body: Req(username: username, password: password, email: email))
        return r
    }
    
    func getMe() async throws -> UserInfo {
        try await request("api/v1/auth/me")
    }
    
    // MARK: - Series
    
    func fetchSeries() async throws -> [Series] {
        struct R: Codable { let results: [Series] }
        let r: R = try await request("api/v1/projects/series")
        return r.results
    }
    
    func createSeries(name: String, description: String) async throws -> Series {
        struct Req: Encodable { let name: String; let description: String }
        return try await post("api/v1/projects/series", body: Req(name: name, description: description))
    }
    
    func fetchSeries(id: UUID) async throws -> SeriesDetail {
        try await request("api/v1/projects/series/\(id)")
    }
    
    func updateSeries(id: UUID, name: String, description: String) async throws -> Series {
        struct Req: Encodable { let name: String; let description: String }
        return try await put("api/v1/projects/series/\(id)", body: Req(name: name, description: description))
    }
    
    func deleteSeries(id: UUID) async throws {
        try await delete("api/v1/projects/series/\(id)")
    }
    
    // MARK: - Projects
    
    func fetchProjects(seriesId: UUID? = nil) async throws -> [Project] {
        struct R: Codable { let results: [Project] }
        var path = "api/v1/projects/projects"
        if let sid = seriesId {
            path += "?series=\(sid)"
        }
        let r: R = try await request(path)
        return r.results
    }
    
    func createProject(_ req: ProjectCreateRequest) async throws -> Project {
        return try await post("api/v1/projects/projects", body: req)
    }
    
    func fetchProject(id: UUID) async throws -> Project {
        try await request("api/v1/projects/projects/\(id)")
    }
    
    func updateProject(id: UUID, name: String, topic: String, description: String) async throws -> Project {
        struct Req: Encodable { let name: String; let original_topic: String; let description: String }
        return try await put("api/v1/projects/projects/\(id)", body: Req(name: name, original_topic: topic, description: description))
    }
    
    func deleteProject(id: UUID) async throws {
        try await delete("api/v1/projects/projects/\(id)")
    }
    
    // MARK: - Stage Execution
    
    func executeStage(projectId: UUID, stageName: String, inputData: [String: Any]? = nil) async throws {
        var req: [String: Any] = ["stage_name": stageName]
        if let inputData = inputData { req["input_data"] = inputData }
        _ = try await post("api/v1/projects/projects/\(projectId)/stages/\(stageName)/execute", body: req as Encodable)
    }
    
    func retryStage(projectId: UUID, stageName: String) async throws {
        struct Req: Encodable { let stage_name: String }
        _ = try await post("api/v1/projects/projects/\(projectId)/retry-stage", body: Req(stage_name: stageName))
    }
    
    func retryPipeline(projectId: UUID) async throws {
        _ = try await post("api/v1/projects/projects/\(projectId)/retry_pipeline")
    }
    
    func fetchStages(projectId: UUID) async throws -> [ProjectStage] {
        struct R: Codable { let results: [ProjectStage] }
        let r: R = try await request("api/v1/projects/projects/\(projectId)/stages")
        return r.results
    }
    
    // MARK: - SSE Stream
    
    func connectSSE(projectId: UUID, stageName: String? = nil) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        guard let base = base else {
            return AsyncThrowingStream { throw APIError.invalidURL }
        }
        
        let path: String
        if let stageName {
            path = "api/v1/projects/sse/projects/\(projectId)/stages/\(stageName)"
        } else {
            path = "api/v1/projects/sse/projects/\(projectId)"
        }
        
        var url = base.appendingPathComponent(path, isDirectory: false)
        
        return AsyncThrowingStream { continuation in
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.allHTTPHeaderFields = ["Accept": "text/event-stream"]
            if !config.accessToken.isEmpty {
                req.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            let task = session.dataTask(with: req) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continuation.finish(throwing: APIError.networkError(NSError(domain: "sse", code: -1)))
                    return
                }
                continuation.yield(SSEEvent(type: "connected"))
                continuation.finish()
            }
            task.resume()
            
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    // MARK: - Model Providers
    
    func fetchModelProviders() async throws -> [ModelProvider] {
        struct R: Codable { let results: [ModelProvider] }
        let r: R = try await request("api/v1/models/model-providers")
        return r.results
    }
    
    func createModelProvider(_ req: ModelProviderCreateRequest) async throws -> ModelProvider {
        return try await post("api/v1/models/model-providers", body: req)
    }
    
    func updateModelProvider(id: UUID, _ req: ModelProviderCreateRequest) async throws -> ModelProvider {
        return try await put("api/v1/models/model-providers/\(id)", body: req)
    }
    
    func deleteModelProvider(id: UUID) async throws {
        try await delete("api/v1/models/model-providers/\(id)")
    }
    
    func testModelProvider(id: UUID, prompt: String) async throws -> Bool {
        struct Req: Encodable { let test_prompt: String }
        _ = try await post("api/v1/models/model-providers/\(id)/test", body: Req(test_prompt: prompt))
        return true
    }
    
    // MARK: - Assets
    
    func fetchAssets() async throws -> [GlobalVariable] {
        struct R: Codable { let results: [GlobalVariable] }
        let r: R = try await request("api/v1/prompts/global-variables")
        return r.results
    }
    
    func createAsset(_ req: [String: Any]) async throws -> GlobalVariable {
        return try await post("api/v1/prompts/global-variables", body: req as Encodable)
    }
    
    func updateAsset(id: UUID, _ req: [String: Any]) async throws -> GlobalVariable {
        return try await put("api/v1/prompts/global-variables/\(id)", body: req as Encodable)
    }
    
    func deleteAsset(id: UUID) async throws {
        try await delete("api/v1/prompts/global-variables/\(id)")
    }
    
    // MARK: - Prompts
    
    func fetchPromptSets() async throws -> [PromptTemplateSet] {
        struct R: Codable { let results: [PromptTemplateSet] }
        let r: R = try await request("api/v1/prompts/prompt-template-sets")
        return r.results
    }
    
    func fetchPromptTemplates(setId: UUID? = nil) async throws -> [PromptTemplate] {
        struct R: Codable { let results: [PromptTemplate] }
        var path = "api/v1/prompts/prompt-templates"
        if let sid = setId { path += "?prompt_template_set=\(sid)" }
        let r: R = try await request(path)
        return r.results
    }
    
    // MARK: - Screenplays
    
    func fetchScreenplays() async throws -> [Screenplay] {
        struct R: Codable { let results: [Screenplay] }
        let r: R = try await request("api/v1/screenplays/screenplays")
        return r.results
    }
    
    func fetchScreenplay(id: UUID) async throws -> Screenplay {
        try await request("api/v1/screenplays/screenplays/\(id)")
    }
    
    // MARK: - Storage URLs
    
    func storageImageUrl(path: String) -> URL? {
        guard let base = base else { return nil }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return base.appendingPathComponent("api/v1/content/storage/image/\(cleanPath)", isDirectory: false)
    }
    
    func storageVideoUrl(path: String) -> URL? {
        guard let base = base else { return nil }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return base.appendingPathComponent("api/v1/content/storage/video/\(cleanPath)", isDirectory: false)
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL, networkError(Error), httpError(Int), decodingError(Error), unauthorized, serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的服务器地址"
        case .networkError(let e): return "网络错误：\(e.localizedDescription)"
        case .httpError(let c): return "HTTP \(c)"
        case .decodingError: return "数据解析失败"
        case .unauthorized: return "未授权，请检查登录信息"
        case .serverError(let m): return m
        }
    }
}
