import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingCreate = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Group {
                if projectStore.projects.isEmpty && !projectStore.isLoading {
                    EmptyState(
                        icon: "film",
                        title: "暂无项目",
                        subtitle: "创建你的第一个 AI 漫剧项目",
                        actionTitle: "新建项目",
                        onAction: { showingCreate = true }
                    )
                } else {
                    List {
                        ForEach(projectStore.projects) { project in
                            NavigationLink(value: project.id) {
                                ProjectCardView(project: project)
                            }
                        }
                        .onDelete(perform: deleteProject)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("项目")
            .navigationDestination(for: UUID.self) { id in
                ProjectDetailView(projectId: id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                ProjectCreateView()
            }
            .task { await projectStore.loadProjects() }
            .alert("错误", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(projectStore.lastError ?? "")
            }
        }
    }
    
    private func deleteProject(at offsets: IndexSet) {
        for index in offsets {
            let project = projectStore.projects[index]
            Task {
                do {
                    try await projectStore.deleteProject(project.id)
                } catch {
                    projectStore.lastError = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct ProjectCardView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.displayName.isEmpty ? project.name : project.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.aiText1)
                    
                    HStack {
                        StatusBadge(status: project.status)
                        if let series = project.seriesName, !series.isEmpty {
                            Text("•")
                                .foregroundStyle(Color.aiText2)
                            Text(series)
                                .font(.caption)
                                .foregroundStyle(Color.aiText2)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(project.progressPercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(projectStatusColor)
                    
                    Text(project.statusDisplay)
                        .font(.caption)
                        .foregroundStyle(Color.aiText2)
                }
            }
            
            // Progress bar
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.aiBorder)
                    Rectangle()
                        .fill(LinearGradient(colors: [Color.aiPrimary, Color.aiSuccess], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(project.progressPercentage) / 100)
                }
                .cornerRadius(4)
                .frame(height: 4)
            }
            
            // Stats
            HStack(spacing: 16) {
                StatItem(icon: "text.word.spacing", value: "\(project.stagesCount)")
                StatItem(icon: "checkmark.circle", value: "\(project.completedStagesCount)")
                if project.failedStagesCount > 0 {
                    StatItem(icon: "xmark.circle", value: "\(project.failedStagesCount)", color: Color.aiError)
                }
                Spacer()
                Text(formatDate(project.createdAt))
                    .font(.caption2)
                    .foregroundStyle(Color.aiText2)
            }
        }
        .padding()
        .background(Color.aiSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.aiBorder, lineWidth: 0.5))
    }
    
    private var projectStatusColor: Color {
        switch project.status {
        case "completed": return Color.aiSuccess
        case "processing", "queued": return Color.aiWarning
        case "failed": return Color.aiError
        default: return Color.aiText2
        }
    }
    
    private func formatDate(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        if let d = formatter.date(from: date) {
            return formatter.string(from: d)
        }
        return date
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusDisplay)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .cornerRadius(4)
    }
    
    private var badgeColor: Color {
        switch status {
        case "completed": return Color.aiSuccess
        case "processing", "queued": return Color.aiWarning
        case "failed": return Color.aiError
        case "paused": return Color.aiWarning
        default: return Color.aiText2
        }
    }
    
    private var statusDisplay: String {
        switch status {
        case "completed": return "已完成"
        case "processing": return "处理中"
        case "queued": return "等待中"
        case "failed": return "失败"
        case "paused": return "已暂停"
        default: return status
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    var color: Color? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color ?? Color.aiText2)
            Text(value)
                .font(.caption)
                .foregroundStyle(color ?? Color.aiText2)
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.aiText2)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.aiText1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.aiText2)
            }
            
            if let title = actionTitle, let action = onAction {
                Button {
                    action()
                } label: {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.aiPrimary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
