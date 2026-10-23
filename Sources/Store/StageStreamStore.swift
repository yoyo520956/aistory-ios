import Foundation
import Combine

/// 阶段执行实时流（SSE）
@MainActor
final class StageStreamStore: ObservableObject {
    @Published var activeStage: String?
    @Published var log: [String] = []
    @Published var latestTokens: String = ""
    @Published var isStreaming = false
    @Published var finished = false
    @Published var lastError: String?

    private var task: Task<Void, Never>?
    private var projectId: UUID?

    func start(projectId: UUID, stage: String?) {
        stop()
        self.projectId = projectId
        self.activeStage = stage
        self.log = []
        self.latestTokens = ""
        self.finished = false
        self.lastError = nil
        self.isStreaming = true

        let stream = APIClient.shared.streamStage(projectId: projectId, stageName: stage)
        task = Task { [weak self] in
            do {
                for try await event in stream {
                    guard let self else { return }
                    await MainActor.run { self.handle(event) }
                    if event.type == "done" || event.type == "error"
                        || event.type == "pipeline_done" || event.type == "pipeline_error" {
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    self?.lastError = error.localizedDescription
                    self?.isStreaming = false
                }
                return
            }
            await MainActor.run {
                self?.isStreaming = false
                self?.finished = true
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isStreaming = false
    }

    private func handle(_ event: SSEEvent) {
        switch event.type {
        case "connected":
            append("已连接实时流")
        case "token", "chunk", "delta":
            if let t = event.token ?? event.content {
                latestTokens += t
            }
        case "message":
            if let m = event.message { append(m) }
        case "progress":
            if let m = event.message { append(m) }
        case "done", "stage_done":
            append("✓ 阶段完成")
            isStreaming = false
            finished = true
        case "error":
            append("✗ \(event.error ?? event.message ?? "未知错误")")
            lastError = event.error ?? event.message
            isStreaming = false
        case "pipeline_done":
            append("✓ 全部阶段完成")
            isStreaming = false
            finished = true
        case "pipeline_error":
            append("✗ 流水线失败：\(event.error ?? "")")
            lastError = event.error
            isStreaming = false
        default:
            if let m = event.message { append("[\(event.type)] \(m)") }
        }
    }

    private func append(_ line: String) {
        log.append(line)
        if log.count > 400 { log.removeFirst(log.count - 400) }
    }
}
