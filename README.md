# AI Story iOS

iOS 原生 App，连接后端 ai_story Django REST API，所有功能在 iOS 上原生呈现。

## 包名

`com.qingyao.aistory`

## 技术栈

- **语言**: Swift 5.9+
- **框架**: SwiftUI
- **最低目标**: iOS 16.0
- **构建系统**: Xcode / Swift Package Manager

## 项目结构

```
Sources/
├── App/
│   └── AIStoryApp.swift          # @main 入口，TabView 主框架（首页/设置），AppGroup 配置
├── Models/
│   └── APIModels.swift           # 所有 API 数据模型（Project, ProjectStage, StoryboardItem, GeneratedImage, GeneratedVideo, ServerConfig）
├── Network/
│   └── APIClient.swift           # 封装所有 HTTP 调用（URLSession + JSON）
├── Store/
│   └── AppState.swift            # @Observable 全局状态管理，UserDefaults 持久化 serverConfig
├── Views/
│   └── Components/
│       ├── ProjectCard.swift     # 项目卡片（名称、进度条、状态徽章、集数）
│       └── StageBadge.swift      # 阶段状态徽章（绿色=完成、橙色=运行中、红色=失败、灰色=未开始）
└── Screens/
    ├── HomeScreen.swift          # 项目列表（+新建按钮，下拉刷新）
    ├── NewProjectScreen.swift    # 新建项目表单（名称、原始主题/小说片段）
    ├── ProjectDetailScreen.swift # 项目详情：进度概览 + 阶段卡片列表
    ├── StageView.swift           # 单阶段详情：rewrite/storyboard/image/video
    └── SettingsScreen.swift      # 服务器配置（URL、用户名、密码/token）
```

## 设计系统

深色主题（参考 DeepSeek Harness dsw）：

| 颜色 | 值 | 用途 |
|------|-----|------|
| 背景 | #0F0F0F | 页面底色 |
| 卡片 | #1A1A1A | 内容卡片 |
| 边框 | #2A2A2A | 分界线、发丝线 |
| 主色 | #00D4FF | 按钮、链接、强调 |
| 成功 | #34C759 | 完成状态 |
| 警告 | #FF9500 | 运行中 |
| 错误 | #FF3B30 | 失败 |
| 文字主 | #FFFFFF | 标题、正文 |
| 文字次 | #BBBBBB | 说明文字 |
| 文字弱 | #666666 | 辅助信息 |

圆角：卡片 12pt，按钮 8pt，输入框 10pt  
间距：4pt 基线网格

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/projects` | 获取项目列表 |
| POST | `/api/projects` | 创建项目 |
| GET | `/api/projects/{id}` | 获取项目详情 |
| POST | `/api/projects/{id}/execute_stage` | 执行阶段 |
| GET | `/api/projects/{id}/stages/{name}` | 获取阶段数据 |
| GET | `/api/projects/{id}/storyboards` | 获取分镜列表 |
| GET | `/api/projects/{id}/images` | 获取图片列表 |
| GET | `/api/projects/{id}/videos` | 获取视频列表 |
| GET | `/storage/images/{path}` | 图片存储访问 |
| GET | `/storage/videos/{path}` | 视频存储访问 |

## 阶段类型

| stage_name | 显示名 | 说明 |
|------------|--------|------|
| rewrite | 文本改写 | AI 改写润色原始文本 |
| storyboard | 分镜设计 | 生成分镜脚本和画面描述 |
| image_generation | 图片生成 | 根据分镜生成画面素材 |
| video_generation | 视频生成 | 合成最终视频作品 |

## 构建

```bash
# 使用 Xcode
open AIStory.xcodeproj

# 或使用 Swift Package Manager
swift build
swift run
```

## 认证

支持两种认证方式：
1. **Basic Auth**: 用户名 + 密码
2. **Token Auth**: 将 Token 填入密码框（同时作为 Bearer Token 发送）
