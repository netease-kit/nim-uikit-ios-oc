## ADDED Requirements

### Requirement: 聊天页面 SwiftUI 化
`NEChatUIKitSwiftUI` SHALL 提供聊天页、消息列表、输入区、底部面板和历史搜索的 SwiftUI 方案。

#### Scenario: 聊天主页面
- **WHEN** 用户从会话列表进入单聊或群聊
- **THEN** 页面展示消息流、输入区和常用操作

#### Scenario: 复杂输入区
- **WHEN** 聊天页需要富文本输入、附件面板或键盘联动
- **THEN** 允许通过局部 UIKit Bridge 保持行为完整
