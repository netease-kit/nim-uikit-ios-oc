# Adaptive Shell 可选接线移除清单（OC）

## 范围

本清单仅覆盖 OC 开源根目录 `IMUIKitOCExample/` 与 `NEChatUIKitOC/` 中与自适应呈现相关的**可选接线**。`NEAdaptiveUIKitOC/` 是独立组件，不在删除范围；客户若确实不再需要折叠屏能力，应另行移除该组件依赖。不扫描闭源 `NEChatKit`、Swift/SwiftUI 工程或旧副本。

## 整体删除

没有本范围内的整文件删除项。

## Demo 局部编辑

- `IMUIKitOCExample/Main/NETabBarController.h`：删除 `makeAdaptiveShellIfEnabled` 声明。
- `IMUIKitOCExample/Main/NETabBarController.m`：删除 `NEAdaptiveUIKitOC` / `NEConversationOpenIntent` import、`NEAdaptiveDemoNavigationController` 类、`adaptiveShell` 属性与 `NEAdaptivePresentationDidChange` 通知监听、`makeAdaptiveShellIfEnabled`、`clearAdaptiveConversation:`、`adaptiveEmptyDetailControllerForSection:` / `adaptiveEmptyDetailController`、`adaptiveConversationForIntent:`、`syncRailBadgeForSection:count:` 及其在 `updateSessionBadge:` / `setUpContactBadgeValue` 中的调用、`ne_disablePagingSafeAreaInsetsIn:`、`ne_updateScrollGeometryInView:managedByContainer:`、`ne_updatePagingGeometryInController:managedByContainer:`、`ne_setTopConstantIfSupported:`、`ne_setAdaptiveNavigationButtonWidths:paired:`、`ne_setAdaptiveSelectionButtonWidth:`、`ne_prepareAdaptivePage:paired:managedByContainer:`、`ne_scheduleLeftColumnSelectionUpdateInShell:`、`ne_updateLeftColumnSelectionInShell:`、`ne_updateConversationGroupRetentionInShell:`、`setLeftColumnSelectionEnabled:inShell:` 与 `NEAdaptivePagingOriginalSafeAreaKey` swizzle；`useAdaptiveNavigation = [NEAdaptiveDeviceGate isFoldableDevice]` 分支恢复为原三个导航栈的 tab 宿主。保留 unread/contact/team 监听、皮肤资源、角标、语言更新与旧路由行为。
- `IMUIKitOCExample/SceneDelegate.m`：删除 `NEAdaptiveUIKitOC` import、`makeAdaptiveShellIfEnabled` 根控制器分支、`NEAdaptiveShellViewController` 的窗口刷新（`didUpdateCoordinateSpace`）与通知入口选择 shell section；通知回退到原 tab 消息导航栈。保留登录、推送、呼叫的模拟器编译保护与 `pendingPushUserInfo` 业务逻辑。
- `IMUIKitOCExample/en.lproj/Localizable.strings`、`IMUIKitOCExample/zh-Hans.lproj/Localizable.strings`：删除 `adaptive_back`、`adaptive_empty_conversation`、`adaptive_empty_contact`、`adaptive_empty_mine`。

## 组件层局部编辑

- `NEChatUIKitOC/NEChatUIKitOC/Classes/ChatRouter/NEBaseChatRouter.h/m`：删除 `NEChatConversationPresentationHandler`、关联对象 key、`setConversationPresentationHandler:`、`setConversationFallbackHandler:`、`presentConversationIfHandledWithRoute:parameters:`、`applyPresentationParameters:`。保留 `registerCommon` 与原业务路由。
- `NEChatUIKitOC/NEChatUIKitOC/Classes/FunUI/FunChatRouter.m`、`Classes/Compat/NormalChatRouter.m`：删除四类默认会话路由开头的 `presentConversationIfHandledWithRoute:` 拦截，完整保留默认 handler 创建、anchor、新消息恢复、旧栈回收以及客户 Router 覆盖机制。
- `NEChatUIKitOC/NEChatUIKitOC.podspec`：仅在确认本模块剩余源码没有实际依赖后删除 `NEAdaptiveUIKitOC` 依赖；其他依赖不变。

没有专属图片或 asset，没有新增 Demo Xcode 文件引用需要删除。

## 必须保留

- `NEAdaptiveDeviceGate` 与 `NEAdaptiveContentInsets`：普通设备与折叠屏都使用的响应式宽度/安全区能力，`isFoldableDevice` 门禁本身保留；删除的只是 Demo 的外壳宿主接线。资料表头、菜单 footer、网格及多选 tab 的父容器宽度约束属于通用响应式修复，不回滚。
- 自适应根列表的选中行恢复（`adaptiveSelectedConversationId` / `adaptiveSelectedIndexPath` 这类稳定标识 + 刷新后恢复）是通用列表能力，保留；只移除外壳专属的 rail/空详情/侧栏选择接线。
- `NEBaseUIKitOC` 的 `NENavigationView` 动态按钮通知、`NEUnifiedBackButton` 等共享组件保留。
- 客户端替换 `NEChatConversationPresentationHandler` 的外部模块清理不在本 skill 范围；默认路由在注册 Router 执行之后捕获呈现，移除本接线后客户自定义 handler 仍应保持优先。删除完整能力前需客户明确外部模块范围，不得暗中扩展本技能。

## 验证

1. `python3 skills/oc-feature-removal/scripts/audit_inventory.py adaptive-shell --phase after` 不允许任何残留。
2. `git diff --check` 通过；重新 `pod install --no-repo-update` 后构建 `NEChatUIKitOC` 与 `IMUIKitOCExample`。
3. 运行时检查：非折叠屏启动仍为普通 tab bar；折叠屏（或模拟 `NEAdaptiveDeviceGate`）下不再进入双栏外壳，而是普通 tab；会话/联系人/我的根导航恢复原 push；通知点击进入消息页；自定义 Router 覆盖仍生效；返回与重复点击无异常。
4. 删除后不得留下本清单唯一指纹；通用 viewport 与外部组件不作为 required-remove 指纹。

## 实测记录（10.9.30 模拟器）

- 在本仓库根就地删除 `NEAdaptiveUIKitOC`/`NEConversationOpenIntent` import、`NEAdaptiveDemoNavigationController` 类、`adaptiveShell` 属性与通知、`makeAdaptiveShellIfEnabled`、`adaptiveEmptyDetailController*`、`adaptiveConversationForIntent:`、`syncRailBadgeForSection:` 及其调用、paging/rail 系列 `ne_*` 方法与 `NEAdaptivePagingOriginalSafeAreaKey`，`SceneDelegate` 恢复普通 tab 根控制器与通知导航。
- 同步删除 `NEBaseChatRouter` 的 presentation handler API 及 Normal/Fun 路由与 Demo 自定义路由的拦截，清理 `adaptive_back` / `adaptive_empty_*` 文案。
- `xcodebuild`：**BUILD SUCCEEDED**；真实树 `--phase after`：`residual files: 0`；安装启动正常（模拟器登录态已丢，停在登录页）。
- 注意：`makeAdaptiveShellIfEnabled` 仅从头文件删除、实现留在 .m 时编译仍能通过（ObjC 动态消息），必须同时清掉 SceneDelegate 调用，否则运行期 unrecognized selector。
