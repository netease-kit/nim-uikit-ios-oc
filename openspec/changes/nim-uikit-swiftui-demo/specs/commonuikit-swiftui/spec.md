## ADDED Requirements

### Requirement: NECommonUIKitSwiftUI 提供公共 SwiftUI UI 壳层
`NECommonUIKitSwiftUI` SHALL 提供导航壳、主题注入、空态、错误态、加载态和 Bridge 基类。

#### Scenario: 主题注入
- **WHEN** SwiftUI 页面需要切换 FunUI / NormalUI
- **THEN** 通过 ThemeState 和 Environment 注入实现，而不是依赖 UIKit appearance 作为主路径

#### Scenario: 通用状态页
- **WHEN** 页面处于 loading / empty / failed 状态
- **THEN** 使用公共状态视图承载，不通过 UIKit 视图隐藏切换实现
