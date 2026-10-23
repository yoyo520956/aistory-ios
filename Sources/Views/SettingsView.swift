import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var modelStore: ModelStore
    @State private var baseUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var testResult: String?
    @State private var testing = false

    var body: some View {
        Form {
            Section("服务器") {
                TextField("服务器地址", text: $baseUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Image(systemName: "network")
                        Text(testing ? "测试中…" : "保存并测试连接")
                    }
                }
                .disabled(testing || baseUrl.isEmpty)

                if let r = testResult {
                    Text(r)
                        .font(.caption)
                        .foregroundStyle(r.hasPrefix("✓") ? Color.aiSuccess : Color.aiError)
                }
            }

            Section("认证") {
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("密码", text: $password)
                Button {
                    Task { await reLogin() }
                } label: {
                    Label("重新登录获取 Token", systemImage: "key")
                }
                .disabled(username.isEmpty || password.isEmpty)
            }

            Section("创作配置") {
                NavigationLink {
                    ModelListView()
                } label: {
                    Label("模型配置（LLM / 文生图 / 图生视频 / 图片编辑）", systemImage: "cpu")
                }

                NavigationLink {
                    PromptListView()
                } label: {
                    Label("提示词管理", systemImage: "text.badge.star")
                }
            }

            Section("账号") {
                LabeledRow(label: "用户名", value: authStore.currentUser?.username ?? (username.isEmpty ? "-" : username))
                LabeledRow(label: "邮箱", value: authStore.currentUser?.email ?? "未设置")
                LabeledRow(label: "Token", value: authStore.config.accessToken.isEmpty ? "未登录" : "已获取")
            }

            Section("关于") {
                LabeledRow(label: "应用", value: "AI Story")
                LabeledRow(label: "版本", value: "1.0.0 (20261023.02)")
                LabeledRow(label: "后端", value: "ai_story (Django)")
            }

            Section {
                Button(role: .destructive) {
                    authStore.logout()
                } label: {
                    Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("设置")
        .task {
            baseUrl = authStore.config.baseUrl
            username = authStore.config.username
        }
    }

    private func testConnection() async {
        testing = true
        testResult = nil
        defer { testing = false }
        do {
            _ = try await authStore.testConnection(baseUrl: baseUrl)
            testResult = "✓ 连接成功"
        } catch {
            testResult = "✗ \(error.localizedDescription)"
        }
    }

    private func reLogin() async {
        testing = true
        testResult = nil
        defer { testing = false }
        do {
            authStore.config.username = username
            authStore.config.password = password
            authStore.saveConfig()
            try await authStore.login(username: username, password: password)
            testResult = "✓ 登录成功"
        } catch {
            testResult = "✗ \(error.localizedDescription)"
        }
    }
}
