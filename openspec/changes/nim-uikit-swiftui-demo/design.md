## Context

当前仓库已经有一套真实可运行的 Objective-C UIKit 工程形态：

- 根 `Podfile`
- 根 `NIMUIKitDemo.xcworkspace`
- `PodConfigs/` 按层组织本地 Pod
- `app/NIMUIKitDemo.xcodeproj` 承载 Demo App
- `NIMLib.xcodeproj` 产出 `NIMSDK.framework`

因此 `NIMUIKit-SwiftUI` 的首版设计重点，不是再讨论一次“是否要模块化”，而是把 SwiftUI Demo 如何以独立链路接入这套仓库说清楚，避免后续实际落目录时再推翻方案。

## Goals / Non-Goals

**Goals:**

- 定义 `NIMUIKit-SwiftUI` 的真实工程骨架
- 明确独立 `Podfile`、独立 workspace、SwiftUI app project、podspec 和模块目录的关系
- 明确每个 Swift / SwiftUI 模块至少应具备的目录结构
- 明确 App 壳的首批目录与职责边界

**Non-Goals:**

- 本次变更不直接创建 Xcode 工程文件
- 不直接创建模块源码
- 不直接迁移现有页面
- 不解决 iOS 16 以下的兼容策略

## Decisions

### D1：首版使用独立 Podfile 与独立 workspace
**决定**：新建 `NIMUIKit-SwiftUI/Podfile` 和 `NIMUIKit-SwiftUI/NIMUIKit-SwiftUI.xcworkspace`，并新增 `app/NIMUIKit-SwiftUI.xcodeproj`

**理由**：
- 和 OC 线入口彻底隔离
- SwiftUI 线可以单独维护依赖、deployment target 和 post_install
- 更符合“新建一条”的要求

### D2：App 与 workspace 都隔离
**决定**：新增独立 SwiftUI App 壳 project，并配套独立 workspace

**理由**：
- SwiftUI Demo 需要独立 target、Bundle ID、Deployment Target
- 再加上独立 Pod 安装入口，SwiftUI 线的工程边界更清晰

### D3：Pod 安装配置独立，podspec 编译配置共享
**决定**：新增 `NIMUIKit-SwiftUI/PodConfigs/` 作为独立安装配置目录，同时保留根 `PodConfigs/config_podspec_swiftui.rb` 作为共享 podspec 编译配置

**理由**：
- SwiftUI 线不应再去改动根 Pod 安装入口
- 模块 podspec 仍需要统一的 Swift 编译设置
- 这样既能隔离安装链路，也不必复制一份 podspec 通用配置

### D4：SwiftUI Demo 首版系统版本固定为 iOS 16.0
**决定**：`NIMUIKit-SwiftUI` app target 与 SwiftUI UI 模块首版统一使用 iOS 16.0

**理由**：
- 方案默认使用 `NavigationStack`
- 搜索、刷新、导航和状态容器可以直接用现代 SwiftUI API
- 避免为了低版本兼容在首版引入大量条件分支

### D5：按现有分层追加 Swift / SwiftUI 模块
**决定**：继续使用 `CoreKit/`、`Common/`、`IMUIKit/` 三层，而不是额外新建 `SwiftUI/` 顶层目录

**理由**：
- 和现有 OC 工程层次一致
- 模块职责对位更清楚
- 不会产生第二套并列目录体系

### D6：每个模块必须满足 podspec + Classes (+ Assets) 骨架
**决定**：
- 纯 Swift 模块：`podspec + Module/Classes`
- SwiftUI UI 模块：`podspec + Module/Classes + Module/Assets`

**理由**：
- 对齐现有 `NIMUIKitDemo` 的 Pod 组织方式
- 让 `podspec` 与目录结构稳定可预期

### D7：App 壳只做根容器与环境注入
**决定**：`app/NIMUIKit-SwiftUI/` 只承载登录态、Tab、ThemeState、SessionState 和根路由

**理由**：
- 避免 App 壳把模块业务逻辑吃掉
- 让 UI 模块仍可独立以 Pod 形式被其他宿主接入

## Risks / Trade-offs

- [独立 workspace / Podfile] → 维护对象增多，但边界更清晰
- [iOS 16.0 基线] → 首版推进更快，但暂不覆盖老系统
- [模块骨架先行] → 前期文档更重，但能显著减少后续文件搬迁和 podspec 返工
