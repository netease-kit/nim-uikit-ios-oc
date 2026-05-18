## Why

NEChatUIKit 是 IM UIKit 中最核心的聊天 UI 模块，目前仅有 Swift 版本（位于 xkit-ios 项目中）。为了支持纯 OC 项目接入，需要将 NEChatUIKit 完整转换为 Objective-C 版本 NEChatUIKitOC，与已有的 NECoreKitOC、NECoreIM2KitOC、NEChatKitOC、NECommonUIKitOC 形成完整的 OC 技术栈。

## What Changes

- 新增 `NEChatUIKitOC` pod 模块，包含完整的聊天 UI 功能
- 将 300+ Swift 文件按 1:1 逻辑镜像转换为 Objective-C
- 分批转换：Base/Common/Config → Models → ViewModels → Views/Cells → Controllers → Markdown
- 所有 Swift protocols 转换为 OC @protocol
- 所有 Swift extensions 转换为 OC categories
- 所有 Swift closures 转换为 OC blocks
- 所有 Swift enums 转换为 NS_ENUM
- 仅转换 Base 层（NormalUI/FunUI 皮肤层后续按需转换）

## Capabilities

### New Capabilities
- `chatui-base`: Base 层基础架构（NEChatBaseViewController、NEChatBaseCell、NEChatService、NEChatLoaderService、ChatUIConfig）
- `chatui-common`: 公共工具与常量（NEChatUIKitClient、ChatConstant、ChatCellConstantValue、NETranslateLanguageManager、Extensions）
- `chatui-models`: 消息模型层（MessageContentModel 及 22 个子类型模型、NEMoreItemModel、UserSettingCellModel 等）
- `chatui-viewmodels`: ViewModel 层（ChatViewModel、P2PChatViewModel、TeamChatViewModel 等 10 个 ViewModel）
- `chatui-helpers`: Helper 工具层（ChatMessageHelper、MessageUtils、NETeamUserManager、NEP2PChatUserCache、ReplyMessageUtil 等）
- `chatui-views`: 核心视图层（NEBaseChatInputView、ChatRecordView、ReplyView、TopMessageView、MessageOperationView 等 20+ 视图）
- `chatui-cells`: 消息 Cell 层（NEBaseChatMessageCell 及其所有子类型 Cell、PinCell、CollectionCell、HistorySearchCell 等）
- `chatui-controllers`: 控制器层（ChatViewController、MultiForwardViewController、NEBasePinMessageViewController 等 10+ 控制器）
- `chatui-emoji`: 表情模块（EmojiPageView、InputEmoticonContainerView、NIMInputEmoticonManager 等）
- `chatui-markdown`: Markdown 渲染引擎（NEMarkdownParser 及 26 个 Markdown 元素解析类）
- `chatui-router`: 路由层（NEBaseChatRouter）

### Modified Capabilities

（无需修改已有能力的 spec）

## Impact

- **新增代码**：IMUIKit/NEChatUIKitOC/ 目录下 300+ 个 .h/.m 文件
- **依赖关系**：依赖 NEChatKitOC、NECommonUIKitOC、NECoreIM2KitOC、NECoreKitOC、NECommonKitOC、NIMSDK
- **第三方依赖**：SDWebImage、MJRefresh、lottie-ios
- **Podspec**：新增 NEChatUIKitOC.podspec
- **Podfile**：新增 NEChatUIKitOC pod 引用
- **构建系统**：PodConfigs 中新增 NEChatUIKitOC 配置模块