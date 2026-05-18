## Why

当前仓库已经有 `NIMUIKitDemo`，用于承载 Swift UIKit → Objective-C 的完整重写方案。但仍缺少一套并行的 SwiftUI 版本 Demo 和模块化工程方案，无法为后续 Swift UIKit → SwiftUI 迁移提供工程落点。

需要在 `NIM/NIMUIKitDemo/` 目录内新增一套 **安装方式和使用形态对齐 `NIMUIKitDemo`** 的 SwiftUI Demo 方案，名称固定为 **`NIMUIKit-SwiftUI`**。它既要能独立编译运行，也要能作为 SwiftUI 模块化组件的集成示例，同时必须下沉到真实工程骨架和模块目录级别。

## What Changes

- **新增 NIMUIKit-SwiftUI Demo 方案**：在 `NIMUIKitDemo` 目录内定义一个新的 SwiftUI Demo 工程形态，名称为 `NIMUIKit-SwiftUI`
- **明确工程入口**：新增独立 `NIMUIKit-SwiftUI/Podfile`、独立 `NIMUIKit-SwiftUI/NIMUIKit-SwiftUI.xcworkspace`，并新增 `app/NIMUIKit-SwiftUI.xcodeproj`
- **新增 Swift / SwiftUI 模块规划**：定义 `NECommonUIKitSwiftUI`、`NEConversationUIKitSwiftUI`、`NEContactUIKitSwiftUI`、`NEChatUIKitSwiftUI`、`NETeamUIKitSwiftUI` 等模块
- **沿用 NIMUIKitDemo 的安装方式**：继续采用本地 Pod 模块化、独立 workspace、App 壳承载的接入方式
- **明确模块目录骨架**：所有 Swift / SwiftUI 模块都明确到 `podspec + Classes (+ Assets)` 级别
- **明确 Demo 页面范围**：登录、Tab、会话、通讯录、聊天、群设置、我的页作为首批必备页面
- **明确 SwiftUI 迁移边界**：底层业务逻辑层保留 Swift，实现 UI 层迁移到 SwiftUI；复杂 UIKit 能力通过 Bridge 适配

## Capabilities

### New Capabilities

- `project-setup`: `NIMUIKit-SwiftUI` 工程创建、独立 Podfile、独立 workspace、Bundle 配置
- `module-architecture`: Swift / SwiftUI 模块命名、依赖关系、目录结构定义
- `commonuikit-swiftui`: 公共 SwiftUI UI 壳层定义（导航、主题、空态、Bridge 基类）
- `conversation-uikit-swiftui`: 会话列表和搜索页的 SwiftUI 方案
- `contact-uikit-swiftui`: 通讯录、联系人详情、选择器等页面的 SwiftUI 方案
- `chat-uikit-swiftui`: 聊天页、输入区、消息列表、历史搜索的 SwiftUI 方案
- `team-uikit-swiftui`: 群详情、群设置、成员管理的 SwiftUI 方案
- `demo-integration`: `NIMUIKit-SwiftUI` Demo 的登录、Tab、路由和验收闭环

### Modified Capabilities

- 无。该 Demo 方案消费通用 `swift-to-swiftui` skill，但不将项目专属约定回写到 skill 内。

## Impact

- 新增一套与 `NIMUIKitDemo` 并行的 SwiftUI Demo 设计规范
- 新增一个项目级 openspec change，用于约束 Demo 工程、模块结构和验收标准
- 不直接修改现有 `NIMUIKitDemo` OC 方案和现有 App 代码
