## ADDED Requirements

### Requirement: SwiftUI 模块命名规范
SwiftUI UI 模块 SHALL 使用 `SwiftUI` 后缀，Swift 业务支撑模块 SHALL 使用 `Swift` 后缀。

#### Scenario: UI 模块命名
- **WHEN** 创建会话、通讯录、聊天、团队相关 UI 模块
- **THEN** 模块名分别为 `NEConversationUIKitSwiftUI`、`NEContactUIKitSwiftUI`、`NEChatUIKitSwiftUI`、`NETeamUIKitSwiftUI`

#### Scenario: 业务支撑模块命名
- **WHEN** 创建基础业务模块
- **THEN** 模块名为 `NECoreKitSwift`、`NECoreIM2KitSwift`、`NECommonKitSwift`、`NEChatKitSwift`

### Requirement: 每个模块都必须具备稳定的目录骨架
每个 Swift / SwiftUI 模块 SHALL 至少包含 `podspec` 与 `ModuleName/Classes` 目录；SwiftUI UI 模块还 SHALL 包含 `ModuleName/Assets`。

#### Scenario: 纯 Swift 支撑模块
- **WHEN** 创建 `NECoreKitSwift`、`NECoreIM2KitSwift`、`NECommonKitSwift`、`NEChatKitSwift`
- **THEN** 目录结构为 `模块目录/模块名.podspec + 模块目录/模块名/Classes`

#### Scenario: SwiftUI UI 模块
- **WHEN** 创建会话、通讯录、聊天、团队、地图、AI 搜索模块
- **THEN** 目录结构为 `模块目录/模块名.podspec + 模块目录/模块名/Classes + 模块目录/模块名/Assets`

### Requirement: UI 与业务分层明确
SwiftUI 页面层 SHALL 复用底层 Swift 业务逻辑，不应为 SwiftUI 再重写一套业务 Repo / Provider。

#### Scenario: SwiftUI 页面接入底层逻辑
- **WHEN** 页面需要加载会话、联系人或消息数据
- **THEN** 通过 ViewModel 调用现有 Swift 业务模块

### Requirement: UIKit Bridge 受控
系统 SHALL 允许 Bridge，但 Bridge 只用于复杂 UIKit 能力点。

#### Scenario: 允许 Bridge 的能力
- **WHEN** 页面依赖地图、图片浏览或复杂输入框
- **THEN** 可以使用 `UIViewRepresentable` 或 `UIViewControllerRepresentable`

### Requirement: SwiftUI UI 模块资源结构统一
每个 SwiftUI UI 模块 SHALL 使用统一的资源组织方式，支持 Base、FunUI、NormalUI 和本地化。

#### Scenario: UI 模块资源布局
- **WHEN** 创建 SwiftUI UI 模块资源目录
- **THEN** `Assets` 下包含 Base 资源、FunUI 资源、NormalUI 资源以及 `en.lproj`、`zh-Hans.lproj`
