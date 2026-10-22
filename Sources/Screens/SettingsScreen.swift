import SwiftUI

// MARK: - Settings Screen

struct SettingsScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var baseUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var testResult: String?
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 24) {
                    // App info
                    VStack(spacing: 8) {
                        Image(systemName: "film.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.aiPrimary)
                        Text("AI 故事创作")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text("com.qingyao.aistory v1.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 20)
                    
                    // Connection section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("服务器连接")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        FormField(
                            label: "服务器地址",
                            placeholder: "https://your-server.com",
                            text: $baseUrl,
                            isSecure: false
                        )
                        
                        FormField(
                            label: "用户名",
                            placeholder: "输入用户名",
                            text: $username,
                            isSecure: false
                        )
                        
                        FormField(
                            label: "密码 / Token",
                            placeholder: "输入密码或 Token",
                            text: $password,
                            isSecure: true
                        )
                        
                        Text("提示：若后端使用 Token 认证，将 Token 填入密码框即可。")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 4)
                    }
                    .padding(16)
                    .background(Color.aiSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.aiBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            Task { await saveConfig() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text("保存配置")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.aiPrimary)
                            .cornerRadius(8)
                        }
                        .disabled(isSaving)
                        
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                if isTesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text("测试连接")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.aiSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.aiBorder, lineWidth: 1)
                            )
                        }
                        .disabled(isTesting)
                    }
                    .padding(.horizontal, 16)
                    
                    // Test result
                    if let result = testResult {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: result.hasPrefix("成功") ? "checkmark.circle.fill" : "exclamation.triangle.fill")
                                    .foregroundStyle(result.hasPrefix("成功") ? Color.aiSuccess : Color.aiWarning)
                                Text(result)
                                    .font(.subheadline)
                                    .foregroundStyle(result.hasPrefix("成功") ? Color.aiSuccess : Color.aiWarning)
                            }
                        }
                        .padding(12)
                        .background(Color.aiSurface)
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.aiBg)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                baseUrl = appState.serverConfig.baseUrl
                username = appState.serverConfig.username
                password = appState.serverConfig.password
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveConfig() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        let trimmedURL = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            errorMessage = "请输入服务器地址"
            return
        }
        guard trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") else {
            errorMessage = "服务器地址必须以 http:// 或 https:// 开头"
            return
        }
        
        let config = ServerConfig(
            baseUrl: trimmedURL,
            username: username.trimmingCharacters(in: .whitespaces),
            password: password
        )
        appState.saveServerConfig(config)
        testResult = "✅ 配置已保存"
    }
    
    private func testConnection() async {
        isTesting = true
        errorMessage = nil
        testResult = nil
        defer { isTesting = false }
        
        let config = ServerConfig(
            baseUrl: baseUrl.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces),
            password: password
        )
        APIClient.shared.updateConfig(config)
        
        do {
            _ = try await APIClient.shared.fetchProjects()
            testResult = "✅ 连接成功！已获取项目列表"
            appState.saveServerConfig(config)
        } catch {
            testResult = "❌ 连接失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - Settings Components

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(Color.aiBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.aiBorder, lineWidth: 1)
        )
    }
}
