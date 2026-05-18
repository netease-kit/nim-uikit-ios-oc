## ADDED Requirements

### Requirement: Demo 首批闭环可运行
`NIMUIKit-SwiftUI` Demo SHALL 至少跑通登录、会话、通讯录、聊天、群设置、我的页闭环。

#### Scenario: 登录进入主界面
- **WHEN** 用户登录成功
- **THEN** Demo 进入 `TabView` 主壳

#### Scenario: 会话进入聊天
- **WHEN** 用户点击会话项
- **THEN** 页面通过 `NavigationStack` 进入聊天页

#### Scenario: 通讯录进入详情
- **WHEN** 用户点击联系人或群入口
- **THEN** 页面进入对应详情页，并可继续跳转到聊天或设置页

### Requirement: Demo 不退化为 UIKit 壳
`NIMUIKit-SwiftUI` Demo SHALL 以 SwiftUI 页面为主，不应使用整页 UIKit 包装冒充 SwiftUI Demo。

#### Scenario: 页面主实现
- **WHEN** 审查 Demo 页面实现
- **THEN** 页面主结构由 SwiftUI View 组成，仅在白名单能力点使用局部 Bridge
