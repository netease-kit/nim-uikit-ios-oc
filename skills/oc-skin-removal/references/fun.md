# 移除 FunUI（微信/娱乐风格），保留 NormalUI

下列路径相对 OC 开源源码根；完整路径枚举及定向审计见 `skin-inventory.json`。按清单处理，不要重扫全仓。审计输出中的 `MOVED`、`PROJECT REFS clean` 和 `KEEP` 是预期成功状态。

## 专属删除项

- `NEChatUIKitOC/NEChatUIKitOC/Classes/FunUI/`、`NEContactUIKitOC/NEContactUIKitOC/Classes/FunUI/`、`NETeamUIKitOC/NETeamUIKitOC/Classes/FunUI/`。
- 皮肤资源：`NEChatUIKitOC/NEChatUIKitOC/Assets/FunChatUIKit.xcassets/`、`NEContactUIKitOC/NEContactUIKitOC/Assets/FunContactUIKit.xcassets/`、`NEConversationUIKitOC/NEConversationUIKitOC/Assets/FunConversationUIKit.xcassets/`、`NETeamUIKitOC/NETeamUIKitOC/Assets/FunTeamUIKit.xcassets/`，以及基础组件 `NEBaseUIKitOC/NEBaseUIKitOC/Assets/NECommonUI.xcassets/FunUI/`。
- `NEBaseUIKitOC/NEBaseUIKitOC/Classes/CommonView/FunSearchView.{h,m}`：先把 `SearchSessionBaseView` 迁到同目录 `SearchSessionBaseView.{h,m}`（迁移已登记，`--phase after` 必须输出 `MOVED`），再删除 `FunSearchView`、`FunSearchSessionHeaderView` 与 `fun_` 资源引用。
- 会话组件无 `FunUI/` 目录：删除 `FunConversationSearchCell.{h,m}`、`FunConversationSearchController.{h,m}`，以及 `NEConversationListCell.h/m`、`NEConversationViewController.h/m` 里的 Fun 类与 Fun 分支；保留 Normal 类、`NEBase*` 基类与 `SearchSessionBaseView`。
- Demo 资源：`IMUIKitOCExample/Assets.xcassets/Tabbar/` 的 `funChat/funChatSelect/funContact/funContactSelect/funPerson/funPersonSelect.imageset`；`IMUIKitOCExample/Assets.xcassets/Mine/clicked_fun.imageset`、`style_fun.imageset`。
- 两个移除方向都会删的公共项：`IMUIKitOCExample/Mine/Controller/StyleSelectionViewController.{h,m}` 与 `IMUIKitOCExample.xcodeproj/project.pbxproj` 中对应引用。`Mine/unclicked.imageset` 只在选择页无别处引用时删。

## 必须编辑的接线

- 各服务 `registerRouter:` 收敛为只注册 Normal：`NEChatService.m` 删除 `FunChatRouter` import 与 `[ChatRouter registerFun]`，保留 `[NormalChatRouter register]`；`NEContactService.m` 固定 `[ContactRouter registerRouter]`；`NEConversationService.m` 固定 `[ConversationRouter register]`；`NETeamService.m` 固定 `[TeamRouter register]`。同时删除 `NEBaseContactRouter.h`、`ConversationRouter.h`、`TeamRouter.h` 中不再有实现的 `+ (void)registerFun;` 声明。
- `TeamRouter.m` 的 `iconUrlsFun` / `teamIconUrlsFun` / `setIconUrlsFun:` 在确认无外部调用后删除；`registerFun` 实现一并删除。
- `ChatMessageHelper.h/m` 三张 cell 注册表删除 Fun 类型与 `Fun*` 前向声明，只保留 Normal；`getChatCellRegisterDic:` 等仍接受 `isFun` 兼容入参但忽略并返回 Normal 类型。
- 共享常量与 ObjC 桥：`ChatCellConstantValue.h/m` 的 `fun_chat_min_h`、`fun_chat_reply_height` 以及 `NEChatUIKitObjCBridge.h/m` 的 `funChatMinimumHeight`、`funChatReplyHeight` 没有存活调用者（只有基类 cell 用常量）时，改为中性名（如 `chat_avatar_min_h`、`chat_reply_height`）并更新 `NEBaseChatMessageCell.m`、`NEBaseUserSettingViewController.m`、`NEBaseChatTeamMemberCell.m`；确认有外部兼容约束时才能登记为 `accepted_candidates`。
- `NEChatUIKitClient.m` 共享默认按钮加载的 `fun_chat_photo`、`fun_chat_aiChat` 改为 `NEBaseChatUIKit.xcassets/Chat/photo.imageset` 与 Normal 的 `AIChat/ai_icon_default.imageset`（结合 UI 效果确认）。
- 共享聊天搜索：`NEHistorySearchFileCell.m`、`NEHistorySearchMonthHeaderView.m` 删除 `FunChatUIColor.h` import，`funChatLineBorderColor` 等改为 `ne_defaultLineColor`；通讯录基类 `funContactLineBorderColor` / `funContactNavigationBackgroundColor` 改为 `ne_default*`，不得因为 Fun 删除而删基类。
- `NEChatBaseViewController.h` 删除 `FunChatUIColor.h` import（`showCustomBottomVideoAction:` 等共享方法保留）；`NEBaseCollectionMessageCell.h/m` 的 `setFunStyle` 无存活调用者时删除。
- 会话共享文件：`NEConversationViewController.m` 删除 Fun 图片名分支（`fun_user_empty`、`fun_add_friend`、`fun_join_team`、`fun_create_*`、`fun_scan_qr` 等）与 `FunConversationController` 分支；`NEConversationListCell.m` 删除 `FunConversationListCell`、`FunStickTopCell` 与 `NEStyleManager` 反射判断；`NEConversationGroupBar.m`、`NEConversationGroupManageController.m` 的 Fun 颜色/空态分支收敛到 Normal。
- `NEBaseConversationSearchController.m`、`ConversationSearchController.{h,m}` 与 `NEBaseUIKitOC.h` 的 `FunSearchView.h` import 更新为 `SearchSessionBaseView.h`；`NEConversationViewController.m` 的 `FunSearchView` 属性与创建改为共享搜索头部（Normal 搜索页仍在用）。
- Demo：
  - `IMUIKitOCExample/Main/NEStyleManager.{h,m}`：删除 `setFunStyle` 与旧 `UserDefaults` 读取逻辑；`isNormalStyle` 保留为组件层反射契约并固定返回 `YES`（存活 Normal）。
  - `IMUIKitOCExample/SceneDelegate.m` 固定 `isFunUI = NO`；`CustomConfig.m` 的 `registerCustomChatRouterForFunUI:` 固定走 `CustomNormalChatViewController`，删除 `CustomFunChatViewController`。
  - `IMUIKitOCExample/Main/NETabBarController.m`、`Mine/Controller/MessageRemindViewController.m`、`PersonInfoViewController.m`、`MineSettingViewController.m`、`LanguageViewController.m`、`MeViewController.m`、`ConfigTestViewController.m`、`IMPocConfigViewController.m`、`IMPushConfigViewController.m`、`InputPersonInfoController.m`、`Mine/View/CustomSettingInputCell.m`、`CustomSettingTextviewCell.m`、`CustomThemeCells.m` 的 `isNormalStyle ? normal : fun` 收敛到 Normal 分支，`ne_funTheme` 改为 `ne_defaultPrimaryColor`。
  - `MineSettingViewController.m` 删除外观入口数据行与 `didStyleClick` 跳转，`MeViewController.m` 保留 Normal 收藏入口；`Localizable.strings` 删除 `style_selection`、`style_fun`、`style_normal` 三个 key。
- `NEConversationGroupManageController.m` 等 `NEGroupIsFunStyle()` 判断固定为 Normal；不要再保留 `fun_*` 图片名。

## 实测收敛记录（10.9.30 模拟器跑通）

- 迁移 `SearchSessionBaseView` 后必须同步改 `NEBaseUIKitOC.h`、`NEBaseConversationSearchController.m`、`NEConversationViewController.m`、`ConversationSearchController.h` 的 import；`NEConversationViewController` 的 `FunSearchView` 属性/getter/搜索栏约束块要整段删除，基类改走 `searchBarButton`。
- 删除 Fun 类时注意 `NEConversationListCell.m` 的实现顺序：`FunConversationListCell` 与 `NEBaseStickTopCell`/`StickTopCell` 相邻，整段截取会误删共享置顶 cell；只删 Fun 实现，保留 `NEBaseStickTopCell` 的类扩展与 `StickTopCell`。
- `fun_chat_reply_height` 与已有 `chat_reply_height` 重名冲突，不要直接改名合并：删除 Fun 常量与 `funChatReplyHeight` 桥接属性，保留 Normal 的 `chat_reply_height`（16pt）。`fun_chat_min_h` 可改中性名 `chat_avatar_min_h`，并删除 `funChatMinimumHeight` 桥接属性。
- 共享 `NEChatUIKitClient` 的 `fun_chat_photo` / `fun_chat_aiChat` 改公共 `photo` / `ai_icon_default`；`NormalUI` 图片 cell 的 `fun_default_image` 改 `default_image`。
- Demo 的 `registerCustomChatRouterForFunUI:` 与 `isFunUI` 变量改为中性名（如 `registerCustomChatRouter:` / `usesSkin`）；`NEStyleManager.isNormalStyle` 保留并固定返回 `YES`。
- 收敛后 `pod install --no-repo-update` + `xcodebuild` 可编译，`--phase after` 输出 0 unresolved，迁移项输出 `MOVED`。

## 不得删除

- 迁移后的 `SearchSessionBaseView.{h,m}` 是 Normal 搜索头部共享类型，必须保留；`NEBaseUIKitOC.h` 的 import 改为新文件名。
- `NEBaseTeamUIKit.xcassets/common/clear_btn.imageset` 内部文件虽叫 `fun_clear_btn@2x/3x.png`，仍是共用 asset，不随 Fun 目录整体删除。
- `map_reset_normal`、`NIMKitEmoticon.bundle` 内资源、`UIControlStateNormal` 与 `isNormalTeam` 与皮肤无关，保留。
- `setupInitWithFunUI:` 是公开初始化签名，保留签名（内部固定传 `NO`），不要猜改客户集成调用。
- 自适应外壳与 `NEAdaptiveContentInsets`/`NEAdaptiveDeviceGate` 的响应式能力、选中行恢复逻辑保留。
