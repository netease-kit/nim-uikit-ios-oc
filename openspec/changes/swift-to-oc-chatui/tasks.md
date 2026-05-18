## 1. Project Scaffolding

- [x] 1.1 创建 IMUIKit/NEChatUIKitOC/ 目录结构（Classes/Base, Chat/Controller, Chat/Model, Chat/ViewModel, Chat/View/Cell, Chat/View/ChatView, Chat/Emoji, Chat/Helper, Chat/HistorySearch, ChatConfig, ChatRouter, Common, Extension, Markdown, Protocol）
- [x] 1.2 创建 NEChatUIKitOC.podspec（依赖 NEChatKitOC, NECommonUIKitOC, NECoreIM2KitOC, NIMSDK, SDWebImage, MJRefresh）
- [x] 1.3 在 PodConfigs 中添加 NEChatUIKitOC 配置模块
- [x] 1.4 在 Podfile 中引入 NEChatUIKitOC，执行 pod install 验证

## 2. Base + Protocol + Config + Router（Phase 1）

- [x] 2.1 转换 NEChatBaseCell.h/m（Base UITableViewCell + setModel: + uploadProgress:）
- [x] 2.2 转换 NEChatBaseViewController.h/m（自定义导航栏、标题设置、返回手势）
- [x] 2.3 转换 NEChatLoaderService.h/m（单例 + 模块初始化）
- [x] 2.4 转换 NEChatService.h/m（单例 + router 注册 + emoji 管理 + SDWebImage codec）
- [x] 2.5 转换 ChatInputViewDelegate.h（@protocol 15+ 代理方法）
- [x] 2.6 转换 ChatUIConfig.h/m + MessageProperties.h/m + NEChatAvatarType 枚举
- [x] 2.7 转换 NEBaseChatRouter.h/m（路由注册 + ChatAddFriendRouter）
- [ ] 2.8 编译验证 Phase 1

## 3. Common + Extensions（Phase 1 续）

- [x] 3.1 转换 NEChatUIKitClient.h/m（单例 + moreAction 数据管理 + 自定义 Cell 注册）
- [x] 3.2 转换 ChatConstant.h/m（全局常量 + ViewModelDelegate 协议 + JSON 工具函数）
- [x] 3.3 转换 ChatCellConstantValue.h/m（16 个布局常量）
- [x] 3.4 转换 NETranslateLanguageManager.h/m（单例 + 语言数据）
- [x] 3.5 转换 NSBundle+NEChatUIKit.h/m（Category: emoji bundle 查找）
- [x] 3.6 转换 UIAlertController+Chat.h/m（Category）
- [x] 3.7 转换 UIImage+Chat.h/m（Category: 图片加载）
- [x] 3.8 转换 NSString+Chat.h/m（Category: 字符串工具）
- [x] 3.9 转换 NSError+Chat.h/m（Category: 错误描述）
- [ ] 3.10 编译验证 Phase 1 完整

## 4. Models（Phase 2）

- [x] 4.1 转换枚举：MessageType, DownloadState, NEMoreActionType, UserSettingType
- [x] 4.2 转换 MessageModel 协议 + MessageContentModel.h/m（基类 + 20+ 属性）
- [x] 4.3 转换 MessageTextModel.h/m
- [x] 4.4 转换 MessageImageModel.h/m
- [x] 4.5 转换 MessageVideoModel.h/m
- [x] 4.6 转换 MessageAudioModel.h/m
- [x] 4.7 转换 MessageFileModel.h/m
- [x] 4.8 转换 MessageLocationModel.h/m
- [x] 4.9 转换 MessageCustomModel.h/m
- [x] 4.10 转换 MessageTipsModel.h/m
- [x] 4.11 转换 MessageRichTextModel.h/m
- [x] 4.12 转换 MessageCallRecordModel.h/m
- [x] 4.13 转换 MessageAIStreamModel.h/m
- [x] 4.14 转换 MessageAtCacheModel.h/m + MessageAtInfoModel.h/m
- [x] 4.15 转换 NEPinMessageModel.h/m
- [x] 4.16 转换 CollectionMessageModel.h/m + CollectionFileModel.h/m + PinMessageFileModel.h/m
- [x] 4.17 转换 NEMoreItemModel.h/m
- [x] 4.18 转换 UserSettingCellModel.h/m
- [x] 4.19 转换 OperationItemExtension（Category: 19 个工厂方法）→ OperationItem+NEChatUIKit.h/m
- [ ] 4.20 编译验证 Phase 2

## 5. Helpers（Phase 3）

- [x] 5.1 转换 ChatMessageHelper.h/m（20+ 静态方法：模型构建、Cell 注册、内容展示）
- [x] 5.2 转换 MessageUtils.h/m（10 个消息工厂方法）
- [x] 5.3 转换 NETeamUserManager.h/m（单例 + 缓存 + 多代理 + 名称解析）
- [x] 5.4 转换 NEP2PChatUserCache.h/m（单例 + 非好友缓存）
- [x] 5.5 转换 ChatDeduplicationHelper.h/m（消息去重集合 + 登录感知清理）
- [x] 5.6 转换 NotificationMessageUtils.h/m（群通知格式化）
- [x] 5.7 转换 ReplyMessageUtil.h/m（回复预览文本）
- [x] 5.8 转换 NEAudioSessionManager.h/m（扬声器/听筒切换 + 距离感应）
- [ ] 5.9 编译验证 Phase 3

## 6. Emoji（Phase 4）

- [x] 6.1 转换 NIMInputEmoticonDefine.h（常量定义）
- [x] 6.2 转换 NIMInputEmoticon / NIMInputEmoticonLayout / NIMInputEmoticonCatalog 模型
- [x] 6.3 转换 NIMInputEmoticonManager.h/m（单例 + plist 解析 + 查找方法）
- [x] 6.4 转换 NIMInputEmoticonButton.h/m + 代理协议
- [x] 6.5 转换 NEEmotionAttachment.h/m（NSTextAttachment 子类）
- [x] 6.6 转换 NEEmotionTool.h/m（正则匹配 + 富文本转换）
- [x] 6.7 转换 EmojiPageView.h/m + DataSource/Delegate 协议
- [x] 6.8 转换 InputEmoticonContainerView.h/m + 代理协议
- [x] 6.9 转换 InputEmoticonTabView.h/m + 代理协议
- [ ] 6.10 编译验证 Phase 4

## 7. ViewModels（Phase 5）

- [ ] 7.1 转换 ChatViewModelDelegate 协议
- [ ] 7.2 转换 ChatViewModel.h/m（核心 ViewModel：消息收发、分页、Pin、转发、操作列表）
- [ ] 7.3 转换 P2PChatViewModel.h/m（输入中状态、在线状态、已读回执）
- [ ] 7.4 转换 TeamChatViewModel.h/m（群信息、置顶消息、群已读、缓存监听）
- [ ] 7.5 转换 CollectionMessageViewModel.h/m
- [ ] 7.6 转换 MultiForwardViewModel.h/m
- [ ] 7.7 转换 PinMessageViewModel.h/m
- [ ] 7.8 转换 ReadViewModel.h/m
- [ ] 7.9 转换 SelectLanguageViewModel.h/m
- [ ] 7.10 转换 TeamHistoryMessageViewModel.h/m
- [ ] 7.11 转换 UserSettingViewModel.h/m
- [ ] 7.12 编译验证 Phase 5

## 8. Views（Phase 6）

- [ ] 8.1 转换 NEBaseChatInputView.h/m（ChatMenuType/ChatInputMode 枚举 + 输入栏完整实现）
- [ ] 8.2 转换 ChatRecordView.h/m + ChatRecordViewDelegate
- [ ] 8.3 转换 ReplyView.h/m
- [ ] 8.4 转换 TopMessageView.h/m + TopMessageViewDelegate
- [ ] 8.5 转换 MessageOperationView.h/m + MessageOperationViewDelegate
- [ ] 8.6 转换 NEAITranslateView.h/m（TranslateState 枚举 + NETranslateViewDelegate）
- [ ] 8.7 转换 NEChatTextView.h/m
- [ ] 8.8 转换 ChatNavigationView.h/m
- [ ] 8.9 转换 NEMutilSelectBottomView.h/m + NEMutilSelectBottomViewDelegate
- [ ] 8.10 转换 CirleProgressView.h/m
- [ ] 8.11 转换 ChatActivityIndicatorView.h/m + ChatSendMessageStatus 枚举
- [ ] 8.12 转换 ChatBrokenNetworkView.h/m
- [ ] 8.13 转换 NEBaseChatNewMessageView.h/m
- [ ] 8.14 转换 NEChatMoreActionView.h/m + NEMoreViewDelegate
- [ ] 8.15 转换 NEInputMoreCell.h/m
- [ ] 8.16 编译验证 Phase 6 Views

## 9. Cells（Phase 6 续）

- [ ] 9.1 转换 NEBaseChatMessageCell.h/m（基类 + ChatBaseCellDelegate + ChatAudioCellProtocol）
- [ ] 9.2 转换 NEBaseChatMessageTipCell.h/m
- [ ] 9.3 转换 NEBaseChatTeamMemberCell.h/m
- [ ] 9.4 转换 NEBaseLanguageCell.h/m
- [ ] 9.5 转换 NEBaseUserSettingCell.h/m + SelectCell + SwitchCell
- [ ] 9.6 转换 UserBaseTableViewCell.h/m + OperationCell.h/m
- [ ] 9.7 转换 CollectionCell/ 目录（10 个 Cell：Text/Image/Video/Audio/File/Location/MultiForward/RichText/Default + CollectionMessageCellDelegate）
- [ ] 9.8 转换 PinCell/ 目录（10 个 Cell：Text/Image/Video/Audio/File/Location/MultiForward/RichText/Default + PinMessageCellDelegate）
- [ ] 9.9 编译验证 Phase 6 Cells

## 10. Controllers（Phase 7）

- [ ] 10.1 转换 ChatViewController.h/m（主聊天控制器：生命周期、7 个代理、工厂方法、媒体发送、音频播放、消息点击处理）
- [ ] 10.2 转换 MultiForwardViewController.h/m
- [ ] 10.3 转换 NEBaseCollectionMessageController.h/m
- [ ] 10.4 转换 NEBasePinMessageViewController.h/m
- [ ] 10.5 转换 NEBaseReadViewController.h/m
- [ ] 10.6 转换 NEBaseForwardAlertViewController.h/m + ForwardItem 模型
- [ ] 10.7 转换 NEBaseSelectUserViewController.h/m
- [ ] 10.8 转换 NEBaseUserSettingViewController.h/m
- [ ] 10.9 转换 NEBaseSelectLanguageViewController.h/m + SelectLanguageDelegate
- [ ] 10.10 转换 TextViewController.h/m
- [ ] 10.11 转换 CustomPresentationController.h/m
- [ ] 10.12 编译验证 Phase 7

## 11. HistorySearch（Phase 8）

- [ ] 11.1 转换 NEBaseHistorySearchController.h/m
- [ ] 11.2 转换 NEBaseHistoryMediaResultController.h/m
- [ ] 11.3 转换 NEHistoryDatePickerViewController.h/m
- [ ] 11.4 转换 NEHistorySearchDateCell / ImageCell / VideoCell / FileCell
- [ ] 11.5 转换 NEHistorySearchMediaCollectionSectionHeader / MediaTableSectionHeader / MonthHeaderView
- [ ] 11.6 转换 NEHistorySearchMonthYearPickerView.h/m
- [ ] 11.7 转换 NERefreshHasNoMoreView.h/m
- [ ] 11.8 编译验证 Phase 8

## 12. Markdown（Phase 9）

- [ ] 12.1 转换 NEMarkdownElement 协议 + NEMarkdownStyle 协议
- [ ] 12.2 转换 NEMarkdownCommonElement / NEMarkdownLevelElement / NEMarkdownLinkElement 基类
- [ ] 12.3 转换所有具体元素类（Bold, Italic, Code, Strikethrough, Header, List, OrderedList, Quote, Link, AutomaticLink, Image, HorizontalRule）
- [ ] 12.4 转换 NEMarkdownTable.h/m + NEMarkdownTableView.h/m + NEMarkdownTableAttachment.h/m
- [ ] 12.5 转换 Escaping 管线（CodeEscaping, Escaping, Unescaping）
- [ ] 12.6 转换 NEMarkdownParser.h/m（核心解析器 + NEEnabledElements OptionSet）
- [ ] 12.7 转换 String+UTF16.h/m + UIFont+Traits.h/m
- [ ] 12.8 编译验证 Phase 9

## 13. Integration & Verification（Phase 10）

- [ ] 13.1 创建 NEChatUIKitOC umbrella header（导出所有 public 头文件）
- [ ] 13.2 更新 Podfile 并执行 pod install
- [ ] 13.3 全量编译验证（解决所有编译错误）
- [ ] 13.4 与 Swift 版本进行 API 对照检查（确保 1:1 方法签名覆盖）

## 14. Known Issues & Gaps（审计结论 2025-04）

### 14.1 缺失文件（Phase 5~9 全部未动工，约 90 个文件）

- **ViewModel（11 个）**：ChatViewModel、P2PChatViewModel、TeamChatViewModel、CollectionMessageViewModel、MultiForwardViewModel、PinMessageViewModel、ReadViewModel、SelectLanguageViewModel、TeamHistoryMessageViewModel、TeamMemberSelectVM、UserSettingViewModel
- **View/ChatView（15 个）**：NEBaseChatInputView、ChatActivityIndicatorView、ChatBrokenNetworkView、ChatNavigationView、ChatRecordView、CirleProgressView、MessageOperationView、NEAITranslateView、NEBaseChatNewMessageView、NEChatMoreActionView、NEChatTextView、NEInputMoreCell、NEMutilSelectBottomView、ReplyView、TopMessageView
- **Cell（25 个）**：NEBaseChatMessageCell、NEBaseChatMessageTipCell、NEBaseChatTeamMemberCell、NEBaseLanguageCell、NEBaseUserSettingCell、NEBaseUserSettingSelectCell、NEBaseUserSettingSwitchCell、OperationCell、UserBaseTableViewCell + CollectionCell 目录全部 + PinCell 目录全部
- **Controller（11 个）**：ChatViewController、CustomPresentationController、MultiForwardViewController + 所有 NEBase* 控制器
- **HistorySearch（10 个）**：所有 NEBaseHistorySearch* / NEHistorySearch* 文件
- **AIChat（4 个）**：AIChatCellModel/AIChatTableViewCell/AIChatViewController/AIChatViewModel（Swift 新增，design.md 未覆盖）
- **Markdown（26 个）**：所有 NEMarkdown* 文件

### 14.2 已修复 Bug（2025-04 审计后）

- [x] `MessageContentModel.m`、`MessageCallRecordModel.m`：`isSelfWithMessage:` → `isSelf:`（方法签名不匹配）
- [x] `ReplyMessageUtil.m`：`V2NIM_MESSAGE_TYPE_TEXT` → `MessageTypeText`、`V2NIM_MESSAGE_TYPE_CUSTOM` → `MessageTypeAIStreamText`（枚举类型混用）
- [x] `ReplyMessageUtil.m`：`<NEChatKitOC/NECustomUtils.h>` → `<NECoreIM2KitOC/NECustomUtils.h>`（模块归属错误）
- [x] 7 个 Model 文件：`<NEChatKitOC/ChatMessageHelper.h>` / `<NEChatKitOC/ReplyMessageUtil.h>` / `<NEChatKitOC/NotificationMessageUtils.h>` → 本地 `#import "xxx.h"`（这些文件属于 NEChatUIKitOC 本模块）

### 14.3 ChatMessageHelper.m 方法缺失（23/28 方法未实现）

以下方法已在 `.h` 中声明但 `.m` 中无实现，将在后续 Phase 完善：`modelFromMessage:`、`contentOfMessage:`、`addTimeMessage:lastModel:`、`getSenderId:`、`isSelf:`、`getUserFromCache:` 等共 23 个方法。