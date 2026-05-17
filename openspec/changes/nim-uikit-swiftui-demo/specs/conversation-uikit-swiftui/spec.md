## ADDED Requirements

### Requirement: 会话列表 SwiftUI 化
`NEConversationUIKitSwiftUI` SHALL 提供会话列表页和搜索页的 SwiftUI 实现。

#### Scenario: 主会话列表
- **WHEN** 用户进入会话 Tab
- **THEN** 页面展示会话列表、下拉刷新、空态和点击进入聊天页能力

#### Scenario: 搜索会话
- **WHEN** 用户触发会话搜索
- **THEN** 页面通过 SwiftUI 搜索态展示搜索结果并支持跳转
