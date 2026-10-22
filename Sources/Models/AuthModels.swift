import Foundation

// MARK: - Auth Models

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let access: String
    let refresh: String
    let user: UserInfo?
}

struct UserInfo: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String?
    let isStaff: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case isStaff = "is_staff"
    }
}

struct RegisterRequest: Encodable {
    let username: String
    let password: String
    let email: String?
}

// MARK: - Server Config

struct ServerConfig: Codable, Equatable, Hashable {
    var baseUrl: String
    var username: String
    var password: String
    var accessToken: String
    var refreshToken: String
    
    init(baseUrl: String = "", username: String = "", password: String = "", accessToken: String = "", refreshToken: String = "") {
        self.baseUrl = baseUrl
        self.username = username
        self.password = password
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    var isAuthenticated: Bool { !accessToken.isEmpty || (!username.isEmpty && !password.isEmpty) }
    
    static let defaults = ServerConfig()
}
