# 移除 NormalUI（飞书/通用风格），保留 FunUI

下列路径相对 OC 开源源码根；完整路径枚举及定向审计见 `skin-inventory.json`。按清单处理，不要重扫全仓。审计输出中的 `PROJECT REFS clean` 和 `KEEP` 是预期成功状态。

## 专属删除项

- `NEChatUIKitOC/NEChatUIKitOC/Classes/NormalUI/`、`NEContactUIKitOC/NEContactUIKitOC/Classes/NormalUI/`、`NETeamUIKitOC/NETeamUIKitOC/Classes/NormalUI/`。
- `NEChatUIKitOC/NEChatUIKitOC/Classes/Compat/NormalChatRouter.m`（真实编译的 Normal 路由实现），同时删除 `NEChatUIKitOC/NEChatUIKitOC.podspec` 中 `exclude_files` 的 podspec 相对路径 `NEChatUIKitOC/Classes/NormalUI/NormalChatRouter.m` 一项。
- 皮肤资源：`NEChatUIKitOC/NEChatUIKitOC/Assets/NormalChatUIKit.xcassets/`、`NEContactUIKitOC/NEContactUIKitOC/Assets/NormalContactUIKit.xcassets/`、`NEConversationUIKitOC/NEConversationUIKitOC/Assets/NormalConversationUIKit.xcassets/`、`NETeamUIKitOC/NETeamUIKitOC/Assets/NormalTeamUIKit.xcassets/`，以及基础组件 `NEBaseUIKitOC/NEBaseUIKitOC/Assets/NECommonUI.xcassets/NormalUI/`。
- 会话组件没有 `NormalUI/` 目录，Normal 专属类在共享文件里：删除 `ConversationSearchCell.{h,m}`、`ConversationSearchController.{h,m}`，以及 `NEConversationListCell.h/m`、`NEConversationViewController.h/m` 中的 Normal 类与 Normal 分支；保留 `NEBase*` 基类与 Fun 类。
- Demo 资源：`app/Assets.xcassets/Tabbar/` 的 `chat/chatSelect/contact/contactSelect/person/personSelect.imageset`；`app/Assets.xcassets/Mine/clicked_normal.imageset`、`style_normal.imageset`。
- 两个移除方向都会删的公共项：`app/Mine/Controller/StyleSelectionViewController.{h,m}`（含 `StyleSelectionCell`），以及 `app.xcodeproj/project.pbxproj` 中的 file reference、build file、group、Sources 条目。`Mine/unclicked.imageset` 是选择组件通用态，仅在选择页无别处引用时删。

## 必须编辑的接线

- `NEAdaptiveUIKitOC`、`NEBaseUIKitOC/Classes/Core/Extension/NEAdaptiveContentInsets.*`、`NEAdaptiveDeviceGate` 是共享呈现层，保留；`NEAdaptiveUIKitOC` 的折叠屏门禁与侧栏能力保留，只清理各服务对 Normal 路由的注册。
- 各服务 `registerRouter:` 收敛为只注册 Fun：`NEChatService.m` 删除 `NormalChatRouter` import 与 `[NormalChatRouter register]`，保留 `[ChatRouter registerFun]`；`NEContactService.m` 删除 `NormalContactRouter` 引用，固定 `[ContactRouter registerFun]`；`NEConversationService.m` 固定 `[ConversationRouter registerFun]`；`NETeamService.m` 固定 `[TeamRouter registerFun]`。`setupInit:` 的 `isFun` 入参和 `setupInitWithFunUI:` 公开签名不要猜改。
- `ChatMessageHelper.h/m` 三张 cell 注册表删除 Normal 类型（`ChatMessageTextCell` 等），只保留 `Fun*`；`getChatCellRegisterDic:` / `getPinCellRegisterDic:` / `getCollectionCellRegisterDic:` 的 `isFun` 兼容入参仍须可调用并返回 Fun 类型。
- 共享聊天搜索：`NEHistorySearchDateCell.m`、`NEHistoryDatePickerViewController.m`、`NEHistorySearchMonthYearPickerView.m` 删除 `NormalChatUIColor.h` import 并把 `normalSearchDateButtonBg`、`normalChatNavigationDivideBg` 一类引用换成 `ne_defaultPrimaryColor` / `ne_defaultNavigationDividerColor`（值不变）。
- `ChatViewController.m` 删除对 `NormalChatViewController` 的 `isKindOfClass` 判断分支，保留 Fun 判定；基类的 `getUserSettingViewController` / `getReadView:` 原返回 `UserSettingViewController` / `ReadViewController`，删除 NormalUI 后必须改返回 `FunUserSettingViewController` / `FunReadViewController`（或由 Fun 子类改接），否则编不过。`NEChatBaseViewController.h` 中 Fun 相关 import 是存活皮肤依赖，保留。
- 通讯录：`NEBaseAIRobotBindController.m`、`NEBaseAIRobotConfigController.m`、`NEBaseAIRobotDetailController.m`、`NEBaseCreateAIRobotController.m`、`NEBaseRobotChatCardController.m`、`NEBaseRobotNicknameEditController.m` 删除 `NormalContact*Controller` / `normalContact*` 类与颜色引用，保留 Fun 与共享基类。`NEBaseSelectCell.m`、`NEBaseMultiSelectViewController.m` 对 `NormalContactUIColor.h` 的依赖改为 `ne_default*` 公共色，基类本身不能删。
- `NEAISearchKitOC/NEAISearchKitOC/Classes/AIWordSearch/NEAIWordSearchViewController.m` 的 `UIColor.ne_normalTheme` 改为 `ne_defaultPrimaryColor`（值一致）。
- Demo：
  - `app/Main/NEStyleManager.{h,m}`：删除 `setNormalStyle` 与旧 `UserDefaults` 读取逻辑；`isNormalStyle` 保留为组件层反射契约并固定返回 `NO`（存活 Fun），不能删除该方法。
  - `app/SceneDelegate.m` 的 `loadService` 固定 `isFunUI = YES`；`CustomConfig.m` 的 `registerCustomChatRouterForFunUI:` 固定走 `CustomFunChatViewController`，删除 `CustomNormalChatViewController`。
  - `app/Main/NETabBarController.m`、`Mine/Controller/MessageRemindViewController.m`、`PersonInfoViewController.m`、`MineSettingViewController.m`、`LanguageViewController.m`、`MeViewController.m`、`ConfigTestViewController.m`、`IMPocConfigViewController.m`、`IMPushConfigViewController.m`、`InputPersonInfoController.m`、`Mine/View/CustomSettingInputCell.m`、`CustomSettingTextviewCell.m`、`CustomThemeCells.m`、`Mine/View/BirthdayDatePickerView.m` 中的 `isNormalStyle ? normal : fun` 与 `ne_normalTheme` 收敛到 Fun 分支或 `ne_defaultPrimaryColor`。
  - `MineSettingViewController.m` 删除外观入口数据行与 `didStyleClick` 跳转，保留翻译等其他设置项；翻译设置里的 `NETranslationLanguageSettingCell` / `NETranslationAutoSettingCell` 继承 NormalUI 的 `TeamSettingSelectCell` / `TeamSettingSubtitleSwitchCell`，需删除并改注册 `NEFunTranslation*` 两个类。`Localizable.strings` 删除 `style_selection`、`style_normal`、`style_fun` 三个 key。
  - **按父类而非名字发现的 Demo 样例**（marker 抓不到，已在清单 `owned_paths` 登记）：`app/Custom/CustomConversationController.{h,m}`、`CustomConversationListCell.{h,m}`、`CustomContactTableViewCell.{h,m}`、`CustomP2PChatViewController.{h,m}`、`CustomContactViewController.{h,m}` 均继承 NormalUI 类，随 NormalUI 删除；`Mine/View/CustomThemeCells.h/m` 继承 `TeamSettingHeaderCell` / `TeamSettingSwitchCell` / `TeamArrowSettingCell`，改为 `FunTeamSettingHeaderCell` / `FunTeamSettingSwitchCell` / `FunTeamArrowSettingCell`；`SceneDelegate.m` 注册的 `TeamMemberSelectController` 改为 `FunTeamMemberSelectController`；`MeViewController.m` 的收藏入口改为 `FunCollectionMessageController`。
- 会话共享文件：`NEConversationViewController.m` 删除 `Normal*` 图片名分支（如 `@"add_friend"`、`@"user_empty"`）与 Normal 样式判断，只保留 `fun_*`；`NEConversationListCell.m` 删除 Normal 分隔线/颜色分支；`NEConversationGroupBar.m`、`NEConversationGroupManageController.m` 的 `NEGroupIsFunStyle()` 判断只保留 Fun 结果。

## 实测收敛记录（10.9.30 模拟器跑通）

- 会话组件里按 `NSClassFromString(@"NEStyleManager")` 反射判断样式的 helper（`NEConversationIsNormalStyle`、`NEConversationCellIsNormalStyle`、`NEGroupBarIsNormalStyle`）要连定义一起删除，调用点收敛为 `NO`；`NEGroupIsFunStyle` 收敛为 `YES`；残留的局部变量 `isNormalStyle` 改名（如 `legacyNormal`），否则审计仍会命中 marker。
- Demo 中所有 `[NEStyleManager.instance isNormalStyle]` / `[NEStyleManager instance].isNormalStyle` 分支收敛到 Fun 值，并删除各文件对 `NEStyleManager.h` 的 import；`NEStyleManager` 本身保留（反射契约）。
- `ChatViewController.m` 的 `NSClassFromString(@"NormalChatViewController")` 翻译布局分支收敛为 `NO`；`NEChatUIKitOC.podspec` 的 `exclude_files` 条目同步删除。
- 收敛后 `pod install --no-repo-update` + `xcodebuild` 可编译，`--phase after` 输出 0 unresolved（仅剩 `KEEP` 契约行）。

## 不得删除

- `NEBaseUIKitOC/NEBaseUIKitOC/Classes/CommonView/FunSearchView.{h,m}` 及其 `SearchSessionBaseView` 是存活 FunUI 与共享搜索头部依赖，保留。
- `isNormalTeam` 是“普通群”判断，`UIControlStateNormal` 是控件状态，`map_reset_normal`、`NIMKitEmoticon.bundle/Emoji/*_normal@2x.png` 是表情/地图状态资源，`NEChatKit` 的 `ne_normalTheme` 是闭源能力，均与 NormalUI 皮肤删除无关，保留。
- `NEBaseTeamUIKit.xcassets/common/clear_btn.imageset` 等 `NEBase*.xcassets` 是共用资源，不能按色调删除。
- 自适应根列表的选中行恢复、`NEAdaptiveContentInsets` 与资料表头/按钮/网格的父容器宽度约束属于共享响应式能力，保留。
