# 跳转最早未读 / 上次阅读位置（OC）移除清单

## 边界

移除范围只包括 OC 开源仓库 `NEChatUIKitOC/` 与 Demo `app/` 的“跳转最早未读/上次阅读位置”。`NEChatKit` 是闭源组件，禁止扫描或修改；只移除 UI 对其 Last Read API 的接线。`enableLastReadPosition`、`NELastReadPositionService` 等闭源定义保留不动。

核心名称：`NELastReadPosition*`、`LastReadPositionState*`、`lastReadPosition*`、`supportsLastReadPosition`。

## 整体删除

- `NEChatUIKitOC/NEChatUIKitOC/Classes/Chat/View/ChatView/NEBaseChatLastReadPositionView.h`
- `NEChatUIKitOC/NEChatUIKitOC/Classes/Chat/View/ChatView/NEBaseChatLastReadPositionView.m`

## 文案

- `NEChatUIKitOC/NEChatUIKitOC/Assets/en.lproj/Localizable.strings` 与 `zh-Hans.lproj/Localizable.strings`：删除 `last_read_position_count`、`last_read_position_overflow`、`last_read_position_accessibility_hint`。

本功能没有 Demo 工程文件或依赖需要修改；不得因移除本功能修改 `app.xcodeproj/` 或 `Podfile`。

## ChatViewModel 接线

删除：

- `lastReadPositionSnapshot`、`lastReadPositionLocating`、`lastReadPositionSuppressed`、`lastReadPositionAnchorSuppressed`、`lastReadPositionConsumed`、`lastReadPositionPreparationStarted`、`lastReadPositionPreparationSettled`、`lastReadPositionConversationActive`、`lastReadPositionGeneration`。
- delegate 的 `lastReadPositionStateChanged` 与 `notifyLastReadPositionStateChanged`。
- `supportsLastReadPosition`、`shouldSuppressLastReadPositionForAnchor:`、`refreshLastReadPositionSuppression`、`locateLastReadPosition:`、`completeLastReadPositionLocation:`、`updateLastReadPositionVisibility:`、`loadAroundLastReadAnchor*` 等 prepare/settle/snapshot/read-flow 方法。
- 进入/退出会话中的 Last Read 准备、冻结 read time、状态恢复和 generation 逻辑；恢复原有 set-current-conversation / clear-unread 流程。
- 历史分页、消息合并中仅为 Last Read 存在的调用或 guard。

保留通用属性 `anchor` 本身（历史跳转仍在用），只删除 `anchor` 的 `didSet` 中仅为 Last Read 存在的调用；不得删除普通历史分页、锚点加载、消息去重、稳定 ID 查找或会话未读清零。

## ChatViewController 接线

删除 `lastReadPositionRequestId`、`lastReadPositionView` 与 tap recognizer、`lastReadPositionTopAnchor` 及布局约束、`getLastReadPositionView`、`jumpToLastReadPosition`、`scrollToLastReadPosition`、`lastReadPositionStateChanged`、`renderLastReadPositionState`、`refreshLastReadPositionVisibility`、`updateLastReadPositionTopConstraint`、`finishLastReadPositionScrollToMessage:requestId:`、`loadLastReadPositionAroundMessage:requestId:`、`isLastReadPositionMessageVisible:` 及其调用；删除多选进入/退出时的隐藏与恢复、lifecycle 渲染、历史预加载与回到底部流程中仅针对 Last Read 的 guard、顶部置顶变化时专为入口调整约束的调用。

移除 guard 后必须保留普通历史预加载、回到底部按钮、多选状态机、Reaction reload 与初始消息详情加载的原有行为。

## 皮肤与模型

- `NEChatUIKitOC/NEChatUIKitOC/Classes/FunUI/Controller/FunChatViewController.m`：删除 `getLastReadPositionView` override；保留 `fun_chat_jump_to_new` 资源（仍由 `FunChatNewMessageView` 使用）。
- `NEChatUIKitOC/NEChatUIKitOC/Classes/Chat/Topic/TopicChatViewModel.h` 与 `NETopicChatViewModel.m`：删除 `supportsLastReadPosition` 声明与 `return NO` override。
- `NEChatUIKitOC/NEChatUIKitOC/Classes/Common/NEChatUIKitObjCModels.h/m`：删除 `LastReadPositionStateKind` 枚举与 `LastReadPositionState` 类；当前仓库中它们只被本功能适配层引用，删除后不得保留空壳。
- NormalUI 没有独立 override，使用基类默认视图；不要为删除功能新增空 override。

## 交叉边界

`ChatViewController` 中 Reaction reload 的底部固定逻辑曾增加 Last Read 定位 guard；移除 Last Read 时只删除该 guard，不得删除 Reaction 队列。反过来移除 Reaction 时也不得删除 Last Read 定位流程。

## 实测记录（10.9.30 模拟器）

- 在本仓库根就地删除 2 个专属文件并清理 ViewModel/Controller/Topic/ObjC 模型/Fun 聊天页后，一次 `xcodebuild` 即 `BUILD SUCCEEDED`。
- 真实移除树 `--phase after`：`owned paths present: 0/2`、`residual files: 0`。
- 安装到已登录 Demo 后运行 Demo 的会话打开/返回 UI 流程（有 UI 测试时）：列表 → 聊天页 → 输入框 → 更多面板 → 长按菜单 → 返回，`TEST_EXIT=0`，聊天页无最早未读入口。

## 验证

1. `python3 skills/oc-feature-removal/scripts/audit_inventory.py earliest-unread --phase after` 不允许任何残留。
2. 本地化文件不再包含三个 `last_read_position_*` key。
3. `git diff --check` 通过；重新 `pod install --no-repo-update` 后构建 `NEChatUIKitOC` 与 `app`。
4. 运行时检查 NormalUI/FunUI：聊天页无最早未读入口；顶部置顶、回到底部、多选、历史分页、Reaction 更新仍正常。
5. 最终业务 diff 只能位于 `NEChatUIKitOC/` 与 `app/`。
