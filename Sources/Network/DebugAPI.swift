import Foundation

// MARK: - Debug Session Models

struct DebugSession: Codable {
    var id: String
    var name: String
    var stageType: String
    var draftContent: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case stageType = "stage_type"
        case draftContent = "draft_template_content"
    }
}

extension DebugSession {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        stageType = (try? c.decode(String.self, forKey: .stageType)) ?? ""
        draftContent = (try? c.decode(String.self, forKey: .draftContent)) ?? ""
    }
}

struct DebugRunResult {
    var status: String
    var output: String
}

// MARK: - Debug API

extension APIClient {
    func bootstrapDebug(templateId: UUID) async throws -> DebugSession {
        struct Req: Encodable { let prompt_template_id: String }
        return try await post("api/v1/prompts/debug-sessions/bootstrap/",
                              body: Req(prompt_template_id: templateId.uuidString))
    }

    func runDebug(sessionId: String,
                  templateContent: String,
                  variables: [String: String],
                  input: [String: String],
                  providerId: UUID?) async throws -> DebugRunResult {
        struct Req: Encodable {
            let template_content: String
            let variable_values: [String: String]
            let input_payload: [String: String]
            let model_provider_id: String?
        }
        let body = Req(template_content: templateContent,
                       variable_values: variables,
                       input_payload: input,
                       model_provider_id: providerId?.uuidString)

        let data = try await rawRequest("api/v1/prompts/debug-sessions/\(sessionId)/run/",
                                        method: "POST",
                                        body: try JSONEncoder().encode(body))

        // 宽松解析：从任意 JSON 里挖输出文本
        if let value = try? JSONDecoder().decode(JSONValue.self, from: data) {
            return DebugRunResult(status: extractStatus(value),
                                  output: extractOutput(value))
        }
        return DebugRunResult(status: "unknown", output: String(data: data, encoding: .utf8) ?? "")
    }

    private func extractStatus(_ v: JSONValue) -> String {
        if let o = v.objectValue {
            for key in ["status", "state"] {
                if let s = o[key]?.stringValue { return s }
            }
        }
        return "completed"
    }

    private func extractOutput(_ v: JSONValue) -> String {
        // 1) 顶层常见字段
        if let o = v.objectValue {
            for key in ["output", "output_text", "response", "content", "text", "result"] {
                if let s = o[key]?.stringValue, !s.isEmpty { return s }
            }
            // 2) artifacts 数组
            if let artifacts = o["artifacts"]?.arrayValue {
                let texts = artifacts.compactMap { a -> String? in
                    guard let ao = a.objectValue else { return a.stringValue }
                    for key in ["content", "text", "output", "response"] {
                        if let s = ao[key]?.stringValue, !s.isEmpty { return s }
                    }
                    return nil
                }
                if !texts.isEmpty { return texts.joined(separator: "\n\n") }
            }
            // 3) run 嵌套
            if let run = o["run"]?.objectValue ?? o["latest_run"]?.objectValue {
                for key in ["output", "output_text", "response", "content", "text"] {
                    if let s = run[key]?.stringValue, !s.isEmpty { return s }
                }
            }
            // 4) 兜底：任一长字符串
            for (_, sub) in o {
                if let s = sub.stringValue, s.count > 60 { return s }
            }
        }
        if let s = v.stringValue { return s }
        return ""
    }
}
