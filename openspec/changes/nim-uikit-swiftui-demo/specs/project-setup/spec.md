## ADDED Requirements

### Requirement: NIMUIKit-SwiftUI 工程以独立链路接入
系统 SHALL 在 `NIM/NIMUIKitDemo/` 下定义独立的 `NIMUIKit-SwiftUI` Demo 工程链路，拥有独立的 `Podfile` 和独立的 workspace。

#### Scenario: 工程入口
- **WHEN** 创建 SwiftUI Demo 工程
- **THEN** 独立 Pod 管理入口为 `NIMUIKit-SwiftUI/Podfile`
- **AND** 独立 workspace 入口为 `NIMUIKit-SwiftUI/NIMUIKit-SwiftUI.xcworkspace`
- **THEN** 工程路径为 `app/NIMUIKit-SwiftUI.xcodeproj`

### Requirement: 独立 Podfile 必须安装 NIMUIKit-SwiftUI target
`NIMUIKit-SwiftUI/Podfile` SHALL 安装 `NIMUIKit-SwiftUI` target，用于集成 Swift / SwiftUI 模块。

#### Scenario: 本地模块安装
- **WHEN** Demo 集成 Swift / SwiftUI 模块
- **THEN** 通过 `PodConfigs` + 本地 `:path` podspec 的方式安装

### Requirement: Demo 使用独立 App 壳目录
`NIMUIKit-SwiftUI` SHALL 拥有独立 App 壳目录，用于承载登录、Tab 和环境注入。

#### Scenario: App 壳职责
- **WHEN** 启动 Demo
- **THEN** App 壳负责登录态切换、Tab 容器、路由状态和主题状态分发
- **AND** App 壳不负责业务 Repo / Provider 逻辑

### Requirement: SwiftUI Demo 首版系统版本固定
`NIMUIKit-SwiftUI` App target 与 SwiftUI UI 模块 SHALL 使用 iOS 16.0 作为首版 Deployment Target。

#### Scenario: 生成工程
- **WHEN** 创建 `NIMUIKit-SwiftUI` target
- **THEN** `IPHONEOS_DEPLOYMENT_TARGET` 为 `16.0`
