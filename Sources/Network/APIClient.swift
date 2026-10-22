import Foundation

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

class APIClient {
    static let shared = APIClient()
    private var config: ServerConfig
    private let session: URLSession
    
    private init(config: ServerConfig = .init()) {
        self.config = config
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 60; c.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: c)
    }
    
    func updateConfig(_ c: ServerConfig) { self.config = c }
    
    private var base: URL? {
        let b = config.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !b.isEmpty else { return nil }
        return URL(string: b.hasSuffix("/") ? String(b.dropLast()) : b)
    }
    
    private func headers() -> [String: String] {
        var h = ["Content-Type": "application/json", "Accept": "application/json"]
        if !config.token.isEmpty { h["Authorization"] = "Bearer \(config.token)" }
        else if !config.username.isEmpty, !config.password.isEmpty {
            let creds = "\(config.username):\(config.password)"
            h["Authorization"] = "Basic \(creds.base64EncodedString())"
        }
        return h
    }
    
    private func request<T: Codable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard var url = base else { throw APIError.invalidURL }
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        url = url.appendingPathComponent(clean, isDirectory: false)
        var req = URLRequest(url: url)
        req.httpMethod = method; req.allHTTPHeaderFields = headers()
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.networkError(NSError(domain: "x", code: -1)) }
        switch http.statusCode {
        case 200...299: return try JSONDecoder().decode(T.self, from: data)
        case 401, 403: throw APIError.unauthorized
        case 500...599: throw APIError.serverError(String(data: data, encoding: .utf8) ?? "服务器错误")
        default: throw APIError.httpError(http.statusCode)
        }
    }
    
    private func post<T: Codable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", body: body)
    }
    
    // MARK: - Projects
    
    func fetchProjects() async throws -> [Project] {
        struct R: Codable { let projects: [Project] }
        return (try await request("api/v1/projects/projects") as R).projects
    }
    
    func createProject(name: String, topic: String) async throws -> Project {
        struct Req: Encodable { let name: String; let original_topic: String }
        return try await post("api/v1/projects/projects", body: Req(name: name, original_topic: topic))
    }
    
    func fetchProject(id: UUID) async throws -> Project {
        try await request("api/v1/projects/projects/\(id)")
    }
    
    // MARK: - Stage Execution
    
    func executeStage(projectId: UUID, stageName: String) async throws -> Bool {
        struct Req: Encodable { let stage_name: String }
        struct R: Codable { let success: Bool }
        let r: R = try await post("api/v1/projects/projects/\(projectId)/stages/\(stageName)/execute", body: Req(stage_name: stageName))
        return r.success
    }
    
    func fetchStage(projectId: UUID, stageName: String) async throws -> ProjectStage {
        try await request("api/v1/projects/projects/\(projectId)/stages/\(stageName)")
    }
    
    // MARK: - Storyboards
    
    func fetchStoryboards(projectId: UUID) async throws -> [StoryboardItem] {
        struct R: Codable { let storyboards: [StoryboardItem] }
        return (try await request("api/v1/projects/projects/\(projectId)/storyboards") as R).storyboards
    }
    
    // MARK: - Images
    
    func fetchImages(projectId: UUID) async throws -> [GeneratedImage] {
        struct Item: Codable { let path: String; let url: String }
        struct R: Codable { let data: [Item] }
        let r: R = try await request("api/v1/content/storage/image")
        return r.data.map { GeneratedImage(id: UUID(), imageUrl: $0.url, thumbnailUrl: $0.url, width: 0, height: 0) }
    }
    
    // MARK: - Videos
    
    func fetchVideos(projectId: UUID) async throws -> [GeneratedVideo] {
        struct Item: Codable { let path: String; let url: String; let duration: Int; let width: Int; let height: Int }
        struct R: Codable { let data: [Item] }
        let r: R = try await request("api/v1/content/storage/video")
        return r.data.map { GeneratedVideo(id: UUID(), videoUrl: $0.url, thumbnailUrl: $0.url, duration: $0.duration, width: $0.width, height: $0.height) }
    }
    
    // MARK: - Storage URL Helpers
    
    func storageImageURL(path: String) -> URL? {
        guard let base = base else { return nil }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return base.appendingPathComponent("storage/images/\(cleanPath)", isDirectory: false)
    }
    
    func storageVideoURL(path: String) -> URL? {
        guard let base = base else { return nil }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return base.appendingPathComponent("storage/videos/\(cleanPath)", isDirectory: false)
    }
}
