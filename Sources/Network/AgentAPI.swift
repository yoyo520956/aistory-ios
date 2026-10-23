import Foundation

// MARK: - Agent Chat Models

struct AgentInitResult: Codable {
    var scopeKey: String

    enum CodingKeys: String, CodingKey {
        case scopeKey = "scope_key"
    }
}

extension AgentInitResult {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scopeKey = (try? c.decode(String.self, forKey: .scopeKey)) ?? ""
    }
}

struct AgentMessage: Identifiable, Equatable {
    let id = UUID()
    var role: String   // user / assistant
    var text: String
    var done: Bool
}

// MARK: - Agent API

extension APIClient {
    func agentInit(scope: String) async throws -> AgentInitResult {
        struct Req: Encodable { let scope: String }
        return try await post("api/v1/agent/session/init/", body: Req(scope: scope))
    }

    func agentSendMessage(scopeKey: String, text: String, modelId: String?) async throws {
        struct Req: Encodable {
            let content: String
            let model_id: String?
        }
        let _: EmptyResponse = try await post("api/v1/agent/session/\(scopeKey)/message/",
                                              body: Req(content: text, model_id: modelId))
    }

    func agentModels() async throws -> [JSONValue] {
        let data = try await rawRequest("api/v1/agent/models/")
        if let arr = try? JSONDecoder().decode([JSONValue].self, from: data) { return arr }
        if let obj = try? JSONDecoder().decode(JSONValue.self, from: data) {
            if let list = obj.objectValue?["models"]?.arrayValue ?? obj.objectValue?["results"]?.arrayValue {
                return list
            }
        }
        return []
    }

    func agentAbort(scopeKey: String) async throws {
        let _: EmptyResponse = try await post("api/v1/agent/session/\(scopeKey)/abort/", body: EmptyRequest())
    }

    func agentClear(scopeKey: String) async throws {
        let _: EmptyResponse = try await post("api/v1/agent/session/\(scopeKey)/clear/", body: EmptyRequest())
    }

    /// Agent SSE 回复流
    func agentStream(scopeKey: String) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let url = try makeURL("api/v1/agent/session/\(scopeKey)/stream/")
                    var req = URLRequest(url: url)
                    req.httpMethod = "GET"
                    req.allHTTPHeaderFields = authHeaders(json: false)
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw APIError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
                    }
                    for try await line in bytes.lines {
                        let t = line.trimmingCharacters(in: .whitespaces)
                        guard t.hasPrefix("data:") else { continue }
                        let payload = t.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        guard let d = payload.data(using: .utf8) else { continue }
                        if let ev = try? JSONDecoder().decode(SSEEvent.self, from: d) {
                            continuation.yield(ev)
                            if ev.type == "done" || ev.type == "error" || ev.type == "stream_end" { break }
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
