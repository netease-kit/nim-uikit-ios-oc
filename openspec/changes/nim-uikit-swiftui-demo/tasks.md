## 0. 工程入口 (project-setup)

- [ ] 0.1 创建独立目录 `NIMUIKit-SwiftUI/`
- [ ] 0.2 创建 `NIMUIKit-SwiftUI/Podfile`
- [ ] 0.3 创建 `NIMUIKit-SwiftUI/NIMUIKit-SwiftUI.xcworkspace`
- [ ] 0.4 创建 `app/NIMUIKit-SwiftUI.xcodeproj`
- [ ] 0.5 新增 `app/generate_swiftui_project.rb`
- [ ] 0.6 在 `NIMUIKit-SwiftUI/Podfile` 中配置独立 `post_install`，让 SwiftUI 线 target 能找到 `NIMSDK.framework`

## 1. Pod 配置层

- [ ] 1.1 新增 `PodConfigs/config_podspec_swiftui.rb`
- [ ] 1.2 新增 `NIMUIKit-SwiftUI/PodConfigs/config_third.rb`
- [ ] 1.3 新增 `NIMUIKit-SwiftUI/PodConfigs/config_local_core.rb`
- [ ] 1.4 新增 `NIMUIKit-SwiftUI/PodConfigs/config_local_common.rb`
- [ ] 1.5 新增 `NIMUIKit-SwiftUI/PodConfigs/config_local_im.rb`

## 2. App 壳骨架

- [ ] 2.1 创建 `app/NIMUIKit-SwiftUI/Bootstrap`
- [ ] 2.2 创建 `app/NIMUIKit-SwiftUI/Root`
- [ ] 2.3 创建 `app/NIMUIKit-SwiftUI/Login`
- [ ] 2.4 创建 `app/NIMUIKit-SwiftUI/Main`
- [ ] 2.5 创建 `app/NIMUIKit-SwiftUI/State`
- [ ] 2.6 创建 `app/NIMUIKit-SwiftUI/Support`
- [ ] 2.7 创建 `NIMUIKit_SwiftUIApp.swift`、`AppDelegate.swift`、`Info.plist`

## 3. 基础层模块骨架

- [ ] 3.1 创建 `CoreKit/NECoreKitSwift/NECoreKitSwift.podspec`
- [ ] 3.2 创建 `CoreKit/NECoreKitSwift/NECoreKitSwift/Classes/{Common,Router,StatisticsReport,Utils}`
- [ ] 3.3 创建 `CoreKit/NECoreIM2KitSwift/NECoreIM2KitSwift.podspec`
- [ ] 3.4 创建 `CoreKit/NECoreIM2KitSwift/NECoreIM2KitSwift/Classes/{Client,Provider,Listener,Adapter,Model}`
- [ ] 3.5 创建 `Common/NECommonKitSwift/NECommonKitSwift.podspec`
- [ ] 3.6 创建 `Common/NECommonKitSwift/NECommonKitSwift/Classes/{Constant,Extension,Manager,Utils,Permission}`
- [ ] 3.7 创建 `Common/NECommonUIKitSwiftUI/NECommonUIKitSwiftUI.podspec`
- [ ] 3.8 创建 `Common/NECommonUIKitSwiftUI/NECommonUIKitSwiftUI/Classes/{Base,Theme,Component,StateView,Navigation,Bridge,Modifier,Extension}`
- [ ] 3.9 创建 `Common/NECommonUIKitSwiftUI/NECommonUIKitSwiftUI/Assets`

## 4. 数据层模块骨架

- [ ] 4.1 创建 `IMUIKit/NEChatKitSwift/NEChatKitSwift.podspec`
- [ ] 4.2 创建 `IMUIKit/NEChatKitSwift/NEChatKitSwift/Classes/{Model,Repo,Provider,Service,Cache,Config,Factory}`

## 5. UI 模块骨架

- [ ] 5.1 创建 `IMUIKit/NEConversationUIKitSwiftUI/NEConversationUIKitSwiftUI.podspec`
- [ ] 5.2 创建 `IMUIKit/NEConversationUIKitSwiftUI/NEConversationUIKitSwiftUI/{Classes,Assets}`
- [ ] 5.3 创建 `IMUIKit/NEContactUIKitSwiftUI/NEContactUIKitSwiftUI.podspec`
- [ ] 5.4 创建 `IMUIKit/NEContactUIKitSwiftUI/NEContactUIKitSwiftUI/{Classes,Assets}`
- [ ] 5.5 创建 `IMUIKit/NEChatUIKitSwiftUI/NEChatUIKitSwiftUI.podspec`
- [ ] 5.6 创建 `IMUIKit/NEChatUIKitSwiftUI/NEChatUIKitSwiftUI/{Classes,Assets}`
- [ ] 5.7 创建 `IMUIKit/NETeamUIKitSwiftUI/NETeamUIKitSwiftUI.podspec`
- [ ] 5.8 创建 `IMUIKit/NETeamUIKitSwiftUI/NETeamUIKitSwiftUI/{Classes,Assets}`
- [ ] 5.9 创建 `IMUIKit/NEMapKitSwiftUI/NEMapKitSwiftUI.podspec`
- [ ] 5.10 创建 `IMUIKit/NEMapKitSwiftUI/NEMapKitSwiftUI/Classes`
- [ ] 5.11 创建 `IMUIKit/NEAISearchKitSwiftUI/NEAISearchKitSwiftUI.podspec`
- [ ] 5.12 创建 `IMUIKit/NEAISearchKitSwiftUI/NEAISearchKitSwiftUI/{Classes,Assets}`

## 6. 首批页面闭环

- [ ] 6.1 登录页与登录态切换
- [ ] 6.2 `TabView` 主壳（会话 / 通讯录 / 我的）
- [ ] 6.3 会话列表 -> 聊天页
- [ ] 6.4 通讯录 -> 用户详情 / 群详情
- [ ] 6.5 群详情 -> 群设置
- [ ] 6.6 主题切换、空态、错误态、返回、sheet、fullScreenCover

## 7. 验收

- [ ] 7.1 `NIMUIKit-SwiftUI/Podfile` 执行 `pod install` 成功
- [ ] 7.2 `NIMUIKit-SwiftUI/NIMUIKit-SwiftUI.xcworkspace` 可独立打开
- [ ] 7.3 `NIMUIKit-SwiftUI` target 独立编译通过
- [ ] 7.4 SwiftUI 页面结构与状态拆分符合通用 `swift-to-swiftui` skill
