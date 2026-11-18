# 表情评论 / Emoji Reaction（OC）移除清单

## 边界

移除范围只包括 OC 开源仓库 `NEChatUIKitOC/` 与 Demo `app/` 中的“表情评论”。`NEChatKit` 是闭源组件，禁止扫描或修改；只移除 UI 对 Reaction API 的接线。`MessageReactionManager`、`IMKitConfigCenter.enableEmojiReaction`、`NEMessageReactionEmojiRegistry` 等闭源符号定义保留不动。

核心名称：`NEMessageReaction*`、`MessageReactionManager`、`reactionGroups`、`reactionHeight`、`enableEmojiReaction`、`configureReactions`、`onReactionModifiedMessage`。

## 整体删除

- `NEChatUIKitOC/NEChatUIKitOC/Classes/Chat/View/Reaction/`（`NEMessageReactionView.{h,m}`）
- `NEChatUIKitOC/NEChatUIKitOC/Assets/reaction_emoji/`
- `NEChatUIKitOC/NEChatUIKitOC/Assets/NEBaseChatUIKit.xcassets/operation/reaction_add_emoji.imageset/`
- `NEChatUIKitOC/NEChatUIKitOC/Assets/NEBaseChatUIKit.xcassets/operation/reaction_more_emoji.imageset/`
- `NEChatUIKitOC/NEChatUIKitOC/Assets/NEBaseChatUIKit.xcassets/operation/reaction_less_emoji.imageset/`

## Demo 与文案

- `app/en.lproj/Localizable.strings`、`app/zh-Hans.lproj/Localizable.strings`：删除 `emoji_reaction`。
- `NEChatUIKitOC/NEChatUIKitOC/Assets/en.lproj/Localizable.strings`、`zh-Hans.lproj/Localizable.strings`：删除 `reaction_sync_failed`。
- Demo 没有需要修改的工程文件或依赖；不得因移除本功能修改 `app.xcodeproj/` 或 `Podfile`。

## UI 接线

### ChatViewModel

删除 `NEMessageReactionObserver` 遵循、`reactionManager` 属性、`setupReactionManagerWithConversationId:`、`startReactionManager` / `stopReactionManager`、`toggleReactionMessage:index:completion:`、`reactionEmojiProvider`、`reactionManager:didUpdateMessage:snapshot:` 回调；删除进入/退出会话、消息加载/更新中的 Reaction 调用（包括 `loadMessages:` 相关行）。保留普通消息分页、发送、撤回、已读与 Quick Comment 通知日志——不得仅因出现 `quickComment` 就删除。

### ChatViewController

删除 `NEChatReactionPanelQuickIndexes()`、`NEChatReactionErrorMessage()`、`NEChatSupportsReactionConversation()`、`pendingReactionReloadIndexPaths` / `isReactionReloadScheduled` / `isReactionReloadInProgress` / `keepsBottomPinnedForPendingReactionUpdates`、`onReactionModifiedMessage:` 及 `scheduleReactionReloadIfNeeded` / `flushPendingReactionReloads` / `finishPendingReactionReloads` / `cancelPendingReactionBottomPinning`、生命周期中的 start/stop 调用、长按面板 Reaction 配置与选择回调、错误提示；只移除针对 Reaction 的 `isLocatingLastReadPosition` 交叉 guard，不得删除最早未读定位流程。

### MessageOperationView

删除 `MessageReactionEmojiCell`、`kReactionPanelItemSize` / `kReactionPanelImageSize`、`quickReactionItems` / `allReactionItems`、`emojiCollection` / `emojiAllCollection` / `moreButton` 及其约束、`onSelectReaction`、`configureReactionsWithProvider:quickIndexes:showEmoji:showMoreButton:` 与 data source/delegate 分支。普通 operation grid 必须恢复为唯一布局来源，不能留下固定空白或悬空约束。

### 模型与基类 Cell

- `MessageContentModel.h/m`：删除 `reactionGroups`、`reactionHeight`、`hasReaction` 及撤回/复用时的 Reaction 清理；保持原始 `height` 计算与撤回状态。
- `NEBaseChatMessageCell.h/m`：删除 `NEMessageReactionViewDelegate` 遵循与回调、`reactionViewLeft/Right`、`reactionBackdropLeft/Right`、`reactionTopAnchor*`、`supportsReactionLongPress`、`usesInlineReactionSurface`、`reactionTopSpacing*`、`reactionBottomSpacing*`、`reactionHorizontalInset*`、`reactionBodyPadding*`、`reactionLeadingInset*`、`reactionTrailingInset*`、`reactionBackdropTailInset*`、`usesFixedReactionSurface*`、`locksReactionSurfaceToMessageWidth*`、`reactionBackdropImage*`、`shouldCopyBubbleBackground*`、`resetReactionSurfaceForReuse`、configure/layout/update 系列与尺寸缓存；恢复无 Reaction 分支的 cell 高度、气泡宽高、已读位置、复用和长按逻辑。

### 两套皮肤 Cell

以下文件删除所有 `reaction*` override、Reaction 尺寸/backdrop 更新、bringSubview 与复用清理，保留各自气泡、翻译、语音转文字、已读和点击行为：

- `NEChatUIKitOC/NEChatUIKitOC/Classes/NormalUI/Cell/`：`NormalChatMessageBaseCell.m`、`ChatMessageTextCell.m`、`ChatMessageRichTextCell.m`、`ChatMessageAudioCell.m`、`ChatMessageImageCell.m`、`ChatMessageVideoCell.m`、`ChatMessageCallCell.m`、`ChatMessageMultiForwardCell.m`、`ChatMessageRevokeCell.m`
- `NEChatUIKitOC/NEChatUIKitOC/Classes/FunUI/Cell/`：`FunChatMessageBaseCell.m`、`FunChatMessageTextCell.m`、`FunChatMessageRichTextCell.m`、`FunChatMessageAudioCell.m`、`FunChatMessageImageCell.m`、`FunChatMessageVideoCell.m`、`FunChatMessageFileCell.m`、`FunChatMessageLocationCell.m`、`FunChatMessageCallCell.m`、`FunChatMessageMultiForwardCell.m`、`FunChatMessageRevokeCell.m`

FunUI 必须恢复微信气泡 tail、媒体遮罩和文本内边距，不要用 NormalUI 数值替换。

### 其他共享文件

- `Chat/HistorySearch/NEBaseHistorySearchController.m`：删除为隐藏搜索结果 Reaction 添加的 `stopReactionManager` 调用；不要改变关键词/群成员搜索行为。
- `Chat/Topic/NETopicChatViewModel.m`：删除 Reaction 空实现 override。
- `NEMoreItemModel.h` / `MessageEnum.h` 中只有通用 `NEMoreActionType*`，不是 Reaction，保留。

## 交叉边界

`ChatViewController` 中 Reaction reload 的底部固定逻辑曾与最早未读定位共享 guard；移除 Reaction 时只删除 Reaction 分支，保留 Last Read 定位流程。自适应外壳接线属于独立 `adaptive-shell` 清单，不随本功能删除。

## 实测提示：不要用关键词行过滤

自动化尝试已确认不可行：`@interface NEBaseChatMessageCell : NEChatBaseCell <NEMessageReactionViewDelegate>`、`@end`、方法声明等结构行都会因含 `Reaction` 被误删，直接把头文件/实现切坏。必须按“成员/方法边界”删除，且每改一个文件就编译一次。

## 真实移除执行顺序（10.9.30 已实测通过）

按依赖闭合后的顺序执行，每段结束都要 `pod install --no-repo-update` + `xcodebuild`：

1. 资源与文案：`Assets/reaction_emoji/`、三个 `operation/reaction_*` imageset、两处 `emoji_reaction`、组件内 `reaction_sync_failed`。
2. `MessageOperationView` + `ChatViewController` 面板接线一起删：`MessageReactionEmojiCell`、`kReactionPanel*`、quick/all items、emoji 集合与约束、`onSelectReaction`、`configureReactionsWithProvider:`；同时删 `ChatViewController` 的 `NEChatReactionPanel*`、`presentReactionPanel`、`didTapReaction:index:`、译文/长按菜单里的 `configureReactions` 调用。
3. `ChatViewModel` + 生命周期 + 历史搜索一起删：`NEMessageReactionObserver`、`reactionManager`、setup/start/stop/toggle/provider、`onReactionModifiedMessage:`，以及 `NEBaseHistorySearchController` 的 `stopReactionManager`（它是被删 API 的调用点，必须同段）。
4. `ChatViewController` 的 reload/pinning 段：`pendingReactionReload*`、`isReactionReload*`、`schedule/flush/finish`、`cancelPendingReactionBottomPinning`。注意它同时复位非 Reaction 的 `keepsBottomPinnedForInitialMessageDetails`，要内联到 `scrollViewWillBeginDragging:` / `scrollViewDidScroll:`，不能直接丢。
5. 两套皮肤 cell（Normal 9 个 + Fun 11 个）：删 `reaction*` override、inline surface、bringSubview/hidden、`resetReactionSurfaceForReuse`、`model.reactionHeight` 高度追加。Fun 锚点恢复：`replyView.top = bubbleImage.bottom`、`translationBubble.top = bubbleImage.bottom + 4`，文本气泡宽度保持 `+funMargin`。
6. 基类 `NEBaseChatMessageCell.h/m` 与 `Classes/Chat/View/Reaction/` 同段删（基类头 `#import "NEMessageReactionView.h"` 依赖该目录）；`ChatBaseCellDelegate` 去掉 `didTapReaction:`。
7. 最后删 `MessageContentModel` 的 `reactionGroups`/`reactionHeight`/`hasReaction`（皮肤与基类仍在读，必须最后）；同时清掉语音/话单 cell 的 `+ model.reactionHeight`。

## 文档之外必须手工确认的点

- 语音/话单 cell 的 `audioBodyBackgroundViewLeft/Right`、`callBodyBackgroundViewLeft/Right` 只在 Reaction 存在时显示，用 `ne_chatReactionReceive/ContentBackground/Border` 上色，是纯 Reaction 表面；`ne_chatReaction*` 已加入审计 patterns，但改完仍要肉眼 grep 一次。
- `MessageOperationView` 的 `showEmoji/showMoreButton/oldFrameWidth/oldFrameHeight/showingAllEmoji/showAllEmoji/showOperation` 都是表情条脚手架：`oldFrameHeight` 仅被 `moreButtonAction` 读，删除时 `ChatViewController` 有 3 处赋值必须同删，`showOperation` 在长按菜单与译文菜单各有一处调用。
- 每文件单独编辑：方法块锚点要识别 `@end` 与 `#pragma mark` 两种结尾；编译前先做一次花括号 / `@interface`↔`@end` 配平检查，再逐文件看 diff。

## 验证

1. `python3 skills/oc-feature-removal/scripts/audit_inventory.py emoji-reaction --phase after` 不允许任何残留。
2. 资源目录不再有 `reaction_emoji` 与三个 `operation/reaction_*.imageset`。
3. `git diff --check` 通过；重新 `pod install --no-repo-update` 后构建 `NEChatUIKitOC` 与 `app`。
4. 运行时检查 NormalUI/FunUI：普通长按菜单无 Reaction 区域；文本、富文本、语音转文字、图片、视频、文件、位置、合并转发、撤回、话单、AIStream 无额外空白或复用残影。
5. 最终业务 diff 只能位于 `NEChatUIKitOC/` 与 `app/`。
