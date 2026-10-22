import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var mode = "login" // login or register
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image(systemName: "film.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.aiPrimary)
                .padding(.top, 60)
            
            Text("AI Story")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.aiText1)
            
            Text("AI 漫剧生成系统")
                .font(.subheadline)
                .foregroundStyle(Color.aiText2)
            
            Divider().background(Color.aiBorder).padding(.vertical, 10)
            
            // Server URL
            VStack(alignment: .leading, spacing: 8) {
                Text("服务器地址").font(.caption).foregroundStyle(Color.aiText2)
                TextField("http://192.168.1.100:8000", text: $authStore.config.baseUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color.aiSurface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.aiBorder, lineWidth: 0.5))
            }
            
            // Username
            VStack(alignment: .leading, spacing: 8) {
                Text("用户名").font(.caption).foregroundStyle(Color.aiText2)
                TextField("输入用户名", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color.aiSurface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.aiBorder, lineWidth: 0.5))
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("密码").font(.caption).foregroundStyle(Color.aiText2)
                SecureField("输入密码", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color.aiSurface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.aiBorder, lineWidth: 0.5))
            }
            
            // Email (register only)
            if mode == "register" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱 (可选)").font(.caption).foregroundStyle(Color.aiText2)
                    TextField("email@example.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(Color.aiSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.aiBorder, lineWidth: 0.5))
                }
            }
            
            // Toggle mode
            HStack {
                Text("账号登录").foregroundStyle(mode == "login" ? Color.aiPrimary : Color.aiText2)
                    .font(.subheadline)
                    .onTapGesture { mode = "login" }
                
                Spacer()
                
                Text("|")
                    .foregroundStyle(Color.aiText2)
                
                Spacer()
                
                Text("注册账号").foregroundStyle(mode == "register" ? Color.aiPrimary : Color.aiText2)
                    .font(.subheadline)
                    .onTapGesture { mode = "register" }
            }
            .padding(.vertical, 10)
            
            // Login Button
            Button {
                Task { await handleAuth() }
            } label: {
                ZStack {
                    if authStore.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(mode == "login" ? "登录" : "注册")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.aiPrimary)
                .cornerRadius(12)
            }
            .disabled(authStore.isLoading)
            
            if let error = authStore.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.aiError)
                    .padding()
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .alert("错误", isPresented: $showError) {
            Button("确定") {}
        } message: {
            Text(authStore.lastError ?? "")
        }
    }
    
    private func handleAuth() async {
        guard !username.isEmpty, !password.isEmpty else {
            authStore.lastError = "请输入用户名和密码"
            showError = true
            return
        }
        
        do {
            if mode == "login" {
                try await authStore.login(username: username, password: password)
            } else {
                try await authStore.register(username: username, password: password, email: email)
            }
        } catch {
            authStore.lastError = error.localizedDescription
            showError = true
        }
    }
}
