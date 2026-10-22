import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var baseUrl = ""
    @State private var showTestResult = false
    @State private var testResult = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("服务器配置") {
                    TextField("服务器地址", text: $baseUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            Image(systemName: "network")
                            Text("测试连接")
                        }
                    }
                    
                    if showTestResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.contains("成功") ? Color.aiSuccess : Color.aiError)
                    }
                }
                
                Section("账号信息") {
                    HStack {
                        Text("用户名")
                        Spacer()
                        Text(authStore.currentUser?.username ?? "-")
                            .foregroundStyle(Color.aiText2)
                    }
                    
                    HStack {
                        Text("邮箱")
                        Spacer()
                        Text(authStore.currentUser?.email ?? "未设置")
                            .foregroundStyle(Color.aiText2)
                    }
                }
                
                Section("数据管理") {
                    Button("清除缓存") {
                        // 清除本地数据
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color.aiText2)
                    }
                    
                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("倾瑶工作室")
                            .foregroundStyle(Color.aiText2)
                    }
                }
            }
            .navigationTitle("设置")
            .onChange(of: baseUrl) { newValue in
                authStore.config.baseUrl = newValue
                authStore.saveConfig()
            }
            .onAppear {
                baseUrl = authStore.config.baseUrl
            }
        }
    }
    
    private func testConnection() async {
        testResult = "测试中..."
        showTestResult = true
        
        do {
            let success = try await authStore.testConnection(baseUrl: baseUrl)
            if success {
                testResult = "✓ 连接成功"
            } else {
                testResult = "✗ 连接失败"
            }
        } catch {
            testResult = "✗ 连接失败：\(error.localizedDescription)"
        }
    }
}
