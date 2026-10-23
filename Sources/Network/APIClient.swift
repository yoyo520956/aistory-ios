import Foundation

// MARK: - SSE Event

struct SSEEvent: Codable {
    let type: String
    let content: String?
    let token: String?
    let project_id: String?
    let stage: String?
    let message: String?
    let error: String?
    let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case type, content, token, message, error, data, stage
        case project_id = "project_id"
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(Int)
    case decodingError(Error)
    case unauthorized
    case serverError(String)

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

// MARK: - API Client

class APIClient {
    static let shared = APIClient()

    var config: ServerConfig
    let session: URLSession

    private init(config: ServerConfig = ServerConfig()) {
        self.config = config
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 120
        c.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: c)
    }

    func updateConfig(_ c: ServerConfig) { self.config = c }

    private var baseString: String? {
        let b = config.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !b.isEmpty else { return nil }
        return b.hasSuffix("/") ? String(b.dropLast()) : b
    }

    func authHeaders(json: Bool = true) -> [String: String] {
        var h: [String: String] = ["Accept": "application/json"]
        if json { h["Content-Type"] = "application/json" }
        if !config.accessToken.isEmpty {
            h["Authorization"] = "Bearer \(config.accessToken)"
        } else if !config.username.isEmpty, !config.password.isEmpty {
            let credsData = "\(config.username):\(config.password)".data(using: .utf8) ?? Data()
            h["Authorization"] = "Basic \(credsData.base64EncodedString())"
        }
        return h
    }

    func makeURL(_ path: String) throws -> URL {
        guard let base = baseString else { throw APIError.invalidURL }
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: base + "/" + clean) else { throw APIError.invalidURL }
        return url
    }

    // MARK: - Core Requests

    func rawRequest(_ path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        let url = try makeURL(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.allHTTPHeaderFields = authHeaders()
        if let body { req.httpBody = body }

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "APIClient", code: -1))
        }
        switch http.statusCode {
        case 200...299:
            return data
        case 401, 403:
            throw APIError.unauthorized
        case 400...499:
            let msg = String(data: data, encoding: .utf8) ?? "请求错误 \(http.statusCode)"
            throw APIError.serverError(msg)
        default:
            let msg = String(data: data, encoding: .utf8) ?? "服务器错误 \(http.statusCode)"
            throw APIError.serverError(msg)
        }
    }

    private func request<T: Codable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        var bodyData: Data?
        if let body { bodyData = try JSONEncoder().encode(body) }
        let data = try await rawRequest(path, method: method, body: bodyData)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// 列表请求：同时兼容「分页对象 {results:[...]}」和「纯数组 [...]」
    func list<T: Codable>(_ path: String) async throws -> [T] {
        let data = try await rawRequest(path)
        let decoder = JSONDecoder()
        if let arr = try? decoder.decode([T].self, from: data) { return arr }
        if let page = try? decoder.decode(PaginatedResponse<T>.self, from: data) { return page.results }
        do {
            return try decoder.decode(PaginatedResponse<T>.self, from: data).results
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func post<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", body: body)
    }

    func put<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "PUT", body: body)
    }

    func patch<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "PATCH", body: body)
    }

    @discardableResult
    private func delete(_ path: String) async throws -> Data {
        try await rawRequest(path, method: "DELETE")
    }
}

// MARK: - Auth

extension APIClient {
    func login(username: String, password: String) async throws -> LoginResponse {
        struct Req: Encodable { let username: String; let password: String }
        return try await post("api/v1/auth/login", body: Req(username: username, password: password))
    }

    func register(username: String, password: String, email: String?) async throws -> LoginResponse {
        struct Req: Encodable { let username: String; let password: String; let email: String? }
        return try await post("api/v1/auth/register", body: Req(username: username, password: password, email: email))
    }

    func getMe() async throws -> UserInfo {
        try await request("api/v1/auth/me")
    }
}

// MARK: - Series

extension APIClient {
    func fetchSeries() async throws -> [Series] {
        try await list("api/v1/projects/series")
    }

    func createSeries(name: String, description: String) async throws -> Series {
        struct Req: Encodable { let name: String; let description: String }
        return try await post("api/v1/projects/series/", body: Req(name: name, description: description))
    }

    func fetchSeries(id: UUID) async throws -> SeriesDetail {
        try await request("api/v1/projects/series/\(id)/")
    }

    func updateSeries(id: UUID, name: String, description: String) async throws -> Series {
        struct Req: Encodable { let name: String; let description: String }
        return try await put("api/v1/projects/series/\(id)/", body: Req(name: name, description: description))
    }

    func deleteSeries(id: UUID) async throws {
        try await delete("api/v1/projects/series/\(id)/")
    }
}

// MARK: - Projects

extension APIClient {
    func fetchProjects(seriesId: UUID? = nil) async throws -> [Project] {
        var path = "api/v1/projects/projects/"
        if let sid = seriesId { path += "?series=\(sid.uuidString)" }
        return try await list(path)
    }

    func createProject(_ req: ProjectCreateRequest) async throws -> Project {
        try await post("api/v1/projects/projects/", body: req)
    }

    func fetchProject(id: UUID) async throws -> Project {
        try await request("api/v1/projects/projects/\(id)/")
    }

    func updateProject(id: UUID, name: String, topic: String, description: String) async throws -> Project {
        struct Req: Encodable { let name: String; let original_topic: String; let description: String }
        return try await patch("api/v1/projects/projects/\(id)/", body: Req(name: name, original_topic: topic, description: description))
    }

    func deleteProject(id: UUID) async throws {
        try await delete("api/v1/projects/projects/\(id)/")
    }
}

// MARK: - Stages

extension APIClient {
    func executeStage(projectId: UUID, stageName: String, inputData: [String: String]? = nil) async throws {
        struct Req: Encodable {
            let stage_name: String
            let input_data: [String: String]?
        }
        let body = Req(stage_name: stageName, input_data: inputData)
        let _: EmptyResponse = try await post("api/v1/projects/projects/\(projectId)/execute_stage/", body: body)
    }

    func retryStage(projectId: UUID, stageName: String) async throws {
        struct Req: Encodable { let stage_name: String }
        let _: EmptyResponse = try await post("api/v1/projects/projects/\(projectId)/retry-stage/", body: Req(stage_name: stageName))
    }

    func retryPipeline(projectId: UUID) async throws {
        let _: EmptyResponse = try await post("api/v1/projects/projects/\(projectId)/retry_pipeline/", body: EmptyRequest())
    }

    func fetchStages(projectId: UUID) async throws -> [ProjectStage] {
        try await list("api/v1/projects/stages/?project=\(projectId.uuidString)")
    }
}

// MARK: - SSE Stream

extension APIClient {
    func streamStage(projectId: UUID, stageName: String? = nil) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let path: String
                    if let stageName = stageName {
                        path = "api/v1/projects/sse/projects/\(projectId)/stages/\(stageName)/"
                    } else {
                        path = "api/v1/projects/sse/projects/\(projectId)/"
                    }
                    let url = try self.makeURL(path)
                    var req = URLRequest(url: url)
                    req.httpMethod = "GET"
                    req.allHTTPHeaderFields = self.authHeaders(json: false)
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await self.session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw APIError.httpError(code)
                    }

                    for try await line in bytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        guard trimmed.hasPrefix("data:") else { continue }
                        let jsonPart = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        guard let d = jsonPart.data(using: .utf8) else { continue }
                        if let ev = try? JSONDecoder().decode(SSEEvent.self, from: d) {
                            continuation.yield(ev)
                            if ev.type == "pipeline_done" || ev.type == "pipeline_error" {
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - Helper Types

struct EmptyRequest: Encodable {}

struct EmptyResponse: Codable {
    init() {}
    init(from decoder: Decoder) throws {}
    func encode(to encoder: Encoder) throws {}
}

// MARK: - Model Providers

extension APIClient {
    func fetchModelProviders() async throws -> [ModelProvider] {
        try await list("api/v1/models/model-providers/")
    }

    func createModelProvider(_ req: ModelProviderCreateRequest) async throws -> ModelProvider {
        try await post("api/v1/models/model-providers/", body: req)
    }

    func updateModelProvider(id: UUID, _ req: ModelProviderCreateRequest) async throws -> ModelProvider {
        try await put("api/v1/models/model-providers/\(id)/", body: req)
    }

    func deleteModelProvider(id: UUID) async throws {
        try await delete("api/v1/models/model-providers/\(id)/")
    }

    func testModelProvider(id: UUID, prompt: String) async throws -> Bool {
        struct Req: Encodable { let test_prompt: String }
        let _: EmptyResponse = try await post("api/v1/models/model-providers/\(id)/test/", body: Req(test_prompt: prompt))
        return true
    }
}

// MARK: - Assets (Global Variables)

extension APIClient {
    func fetchAssets() async throws -> [GlobalVariable] {
        try await list("api/v1/prompts/global-variables/")
    }

    func createAsset(key: String, group: String, description: String, variableType: String) async throws -> GlobalVariable {
        struct Req: Encodable {
            let key: String
            let group: String
            let description: String
            let variable_type: String
            let scope: String
        }
        let body = Req(key: key, group: group, description: description, variable_type: variableType, scope: "user")
        return try await post("api/v1/prompts/global-variables/", body: body)
    }

    func updateAsset(id: UUID, key: String, group: String, description: String) async throws -> GlobalVariable {
        struct Req: Encodable { let key: String; let group: String; let description: String }
        return try await patch("api/v1/prompts/global-variables/\(id)/", body: Req(key: key, group: group, description: description))
    }

    func deleteAsset(id: UUID) async throws {
        try await delete("api/v1/prompts/global-variables/\(id)/")
    }
}

// MARK: - Prompts

extension APIClient {
    func fetchPromptSets() async throws -> [PromptTemplateSet] {
        try await list("api/v1/prompts/prompt-template-sets/")
    }

    func fetchPromptSet(id: UUID) async throws -> PromptTemplateSet {
        try await request("api/v1/prompts/prompt-template-sets/\(id)/")
    }

    func createPromptSet(name: String) async throws -> PromptTemplateSet {
        struct Req: Encodable { let name: String }
        return try await post("api/v1/prompts/prompt-template-sets/", body: Req(name: name))
    }

    func deletePromptSet(id: UUID) async throws {
        try await delete("api/v1/prompts/prompt-template-sets/\(id)/")
    }

    func fetchPromptTemplates(setId: UUID? = nil) async throws -> [PromptTemplate] {
        if let sid = setId {
            return try await list("api/v1/prompts/prompt-templates/?prompt_template_set=\(sid.uuidString)")
        }
        return try await list("api/v1/prompts/prompt-templates/")
    }

    func fetchPromptTemplate(id: UUID) async throws -> PromptTemplate {
        try await request("api/v1/prompts/prompt-templates/\(id)/")
    }

    func updatePromptTemplate(id: UUID, name: String, systemPrompt: String, userPrompt: String) async throws -> PromptTemplate {
        struct Req: Encodable {
            let name: String
            let system_prompt: String
            let user_prompt: String
        }
        return try await patch("api/v1/prompts/prompt-templates/\(id)/", body: Req(name: name, system_prompt: systemPrompt, user_prompt: userPrompt))
    }

    func deletePromptTemplate(id: UUID) async throws {
        try await delete("api/v1/prompts/prompt-templates/\(id)/")
    }
}

// MARK: - Screenplays

extension APIClient {
    func fetchScreenplays() async throws -> [Screenplay] {
        try await list("api/v1/screenplays/screenplays/")
    }

    func fetchScreenplay(id: UUID) async throws -> Screenplay {
        try await request("api/v1/screenplays/screenplays/\(id)/")
    }

    func fetchEpisodes(screenplayId: UUID) async throws -> [Episode] {
        try await list("api/v1/screenplays/episodes/?screenplay=\(screenplayId.uuidString)")
    }
}

// MARK: - Workflow Node Schemas

extension APIClient {
    func fetchNodeSchemas() async throws -> [JSONValue] {
        let data = try await rawRequest("api/v1/workflows/node-schemas/")
        let decoder = JSONDecoder()
        if let arr = try? decoder.decode([JSONValue].self, from: data) { return arr }
        if let page = try? decoder.decode(PaginatedResponse<JSONValue>.self, from: data) { return page.results }
        return []
    }
}

// MARK: - Content / Storage

extension APIClient {
    func storageImageURL(path: String) -> URL? {
        guard let base = baseString else { return nil }
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: base + "/" + clean)
    }

    func storageVideoURL(path: String) -> URL? {
        return storageImageURL(path: path)
    }

    /// 把服务端返回的图片路径（可能是相对路径）转成绝对 URL
    func absoluteURL(_ path: String) -> URL? {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        guard let base = baseString else { return nil }
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if clean.hasPrefix("api/") {
            return URL(string: base + "/" + clean)
        }
        return URL(string: base + "/api/v1/content/storage/image/" + clean)
    }
}
