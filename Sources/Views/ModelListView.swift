import SwiftUI

struct ModelListView: View {
    @EnvironmentObject var modelStore: ModelStore
    @State private var showingCreate = false
    @State private var showError = false
    @State private var selectedType: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if modelStore.providers.isEmpty && !modelStore.isLoading {
                    EmptyState(
                        icon: "cpu",
                        title: "暂无模型",
                        subtitle: "添加你的第一个 AI 模型"
                    ) {
                        showingCreate = true
                    }
                } else {
                    List {
                        ForEach(filteredProviders, id: \.id) { provider in
                            ModelRow(provider: provider)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { try await modelStore.deleteProvider(provider.id) }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    
                                    Button {
                                        // Edit action
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("模型配置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            selectedType = "llm"
                            showingCreate = true
                        } label: {
                            Label("添加 LLM", systemImage: "brain")
                        }
                        Button {
                            selectedType = "text2image"
                            showingCreate = true
                        } label: {
                            Label("添加文生图", systemImage: "photo")
                        }
                        Button {
                            selectedType = "image2video"
                            showingCreate = true
                        } label: {
                            Label("添加图生视频", systemImage: "film")
                        }
                        Button {
                            selectedType = "image_edit"
                            showingCreate = true
                        } label: {
                            Label("添加图片编辑", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                ModelCreateView(selectedType: selectedType)
            }
            .task { await modelStore.loadProviders() }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(modelStore.lastError ?? "")
            }
        }
    }
    
    private var filteredProviders: [ModelProvider] {
        guard let type = selectedType else { return modelStore.providers }
        return modelStore.providers.filter { $0.providerType == type }
    }
}

struct ModelRow: View {
    let provider: ModelProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: providerIcon)
                .font(.title2)
                .foregroundStyle(providerTypeColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider.name)
                        .font(.body)
                        .foregroundStyle(Color.aiText1)
                    
                    if !provider.isActive {
                        Text("已停用")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.aiBorder)
                            .cornerRadius(4)
                    }
                }
                
                Text(provider.modelName)
                    .font(.caption)
                    .foregroundStyle(Color.aiText2)
                    .lineLimit(1)
                
                Text(provider.apiUrl)
                    .font(.caption2)
                    .foregroundStyle(Color.aiText2)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: provider.isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(provider.isActive ? Color.aiSuccess : Color.aiText2)
        }
        .padding(.vertical, 4)
    }
    
    private var providerIcon: String {
        switch provider.providerType {
        case "llm": return "brain"
        case "text2image": return "photo"
        case "image2video": return "film"
        case "image_edit": return "wand.and.stars"
        default: return "circle"
        }
    }
    
    private var providerTypeColor: Color {
        switch provider.providerType {
        case "llm": return .purple
        case "text2image": return .blue
        case "image2video": return .green
        case "image_edit": return .orange
        default: return .secondary
        }
    }
}

struct ModelCreateView: View {
    let selectedType: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var modelStore: ModelStore
    @State private var name = ""
    @State private var providerType = "llm"
    @State private var apiUrl = ""
    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var maxTokens = 2000
    @State private var temperature = 0.7
    @State private var topP = 1.0
    @State private var timeout = 60
    @State private var isActive = true
    @State private var showError = false
    
    init(selectedType: String?) {
        self.selectedType = selectedType
        _providerType = State(initialValue: selectedType ?? "llm")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("模型名称", text: $name)
                    
                    Picker("模型类型", selection: $providerType) {
                        Text("LLM 模型").tag("llm")
                        Text("文生图").tag("text2image")
                        Text("图生视频").tag("image2video")
                        Text("图片编辑").tag("image_edit")
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("API 地址", text: $apiUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("模型名称", text: $modelName)
                }
                
                Section("认证") {
                    SecureField("API Key", text: $apiKey)
                }
                
                Section("高级设置") {
                    HStack {
                        Text("最大 Token")
                        Spacer()
                        TextField("Token", value: $maxTokens, format: .number)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("温度")
                        Spacer()
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                        Text(String(format: "%.1f", temperature))
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("Top P")
                        Spacer()
                        Slider(value: $topP, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", topP))
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("超时(秒)")
                        Spacer()
                        TextField("超时", value: $timeout, format: .number)
                            .frame(width: 80)
                    }
                }
                
                Section {
                    Toggle("启用模型", isOn: $isActive)
                }
            }
            .navigationTitle("添加模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await handleCreate() }
                    }
                    .disabled(name.isEmpty || apiUrl.isEmpty || apiKey.isEmpty || modelName.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(modelStore.lastError ?? "")
            }
        }
    }
    
    private func handleCreate() async {
        let req = ModelProviderCreateRequest(
            name: name,
            provider_type: providerType,
            executor_class: "",
            api_url: apiUrl,
            api_key: apiKey,
            model_name: modelName,
            max_tokens: maxTokens,
            temperature: temperature,
            top_p: topP,
            timeout: timeout,
            is_active: isActive,
            priority: 0,
            rate_limit_rpm: 60,
            rate_limit_rpd: 1000
        )
        
        do {
            _ = try await modelStore.createProvider(req)
            dismiss()
        } catch {
            modelStore.lastError = error.localizedDescription
            showError = true
        }
    }
}
