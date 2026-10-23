import SwiftUI

// MARK: - AI 助手对话（原版 PageAgentDialog 的移动端形态）

struct AgentChatView: View {
    @State private var messages: [AgentMessage] = []
    @State private var input = ""
    @State private var scopeKey: String?
    @State private var isStreaming = false
    @State private var errorMessage: String?
    @State private var streamTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if messages.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.aiText2)
                                Text("AI 助手可以帮你改写文案、生成分镜建议")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.aiText2)
                            }
                            .padding(.top, 80)
                        }
                        ForEach(messages) { msg in
                            BubbleView(message: msg).id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider().background(Color.aiBorder)

            // 输入栏
            HStack(spacing: 8) {
                TextField("输入消息…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.aiSurface)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.aiBorder, lineWidth: 0.5))

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.aiPrimary)
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty && !isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.aiBg)
        .navigationTitle("AI 助手")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await clear() }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .task { await ensureSession() }
        .alert("提示", isPresented: .constant(errorMessage != nil)) {
            Button("知道了") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear { streamTask?.cancel() }
    }

    private func ensureSession() async {
        guard scopeKey == nil else { return }
        do {
            let r = try await APIClient.shared.agentInit(scope: "ios-app")
            scopeKey = r.scopeKey.isEmpty ? nil : r.scopeKey
        } catch {
            errorMessage = "助手初始化失败：\(error.localizedDescription)"
        }
    }

    private func send() async {
        if isStreaming {
            // 正在流式输出 → 点击 = 中止
            if let key = scopeKey {
                try? await APIClient.shared.agentAbort(scopeKey: key)
            }
            streamTask?.cancel()
            isStreaming = false
            return
        }

        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        input = ""

        await ensureSession()
        guard let key = scopeKey else {
            errorMessage = "助手会话未就绪"
            return
        }

        messages.append(AgentMessage(role: "user", text: text, done: true))
        let reply = AgentMessage(role: "assistant", text: "", done: false)
        messages.append(reply)
        let replyIndex = messages.count - 1
        isStreaming = true

        do {
            try await APIClient.shared.agentSendMessage(scopeKey: key, text: text, modelId: nil)
        } catch {
            messages[replyIndex].text = "发送失败：\(error.localizedDescription)"
            messages[replyIndex].done = true
            isStreaming = false
            return
        }

        // 拉流
        streamTask = Task {
            do {
                for try await event in APIClient.shared.agentStream(scopeKey: key) {
                    if Task.isCancelled { break }
                    switch event.type {
                    case "token", "delta", "chunk":
                        let t = event.token ?? event.content ?? ""
                        if !t.isEmpty { messages[replyIndex].text += t }
                    case "message":
                        if let m = event.message { messages[replyIndex].text += m }
                    case "done", "stream_end":
                        messages[replyIndex].done = true
                        isStreaming = false
                        return
                    case "error":
                        messages[replyIndex].text += "\n[错误] \(event.error ?? "")"
                        messages[replyIndex].done = true
                        isStreaming = false
                        return
                    default:
                        break
                    }
                }
            } catch {
                if !Task.isCancelled {
                    messages[replyIndex].text += "\n[连接中断] \(error.localizedDescription)"
                }
            }
            messages[replyIndex].done = true
            isStreaming = false
        }
    }

    private func clear() async {
        if let key = scopeKey {
            try? await APIClient.shared.agentClear(scopeKey: key)
        }
        messages.removeAll()
        scopeKey = nil
        await ensureSession()
    }
}

struct BubbleView: View {
    let message: AgentMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 40) }
            Text(message.text.isEmpty && !message.done ? "…" : message.text)
                .font(.callout)
                .foregroundStyle(message.role == "user" ? Color.white : Color.aiText1)
                .textSelection(.enabled)
                .padding(12)
                .background(message.role == "user" ? Color.aiPrimary : Color.aiSurface)
                .cornerRadius(14)
            if message.role != "user" { Spacer(minLength: 40) }
        }
    }
}
