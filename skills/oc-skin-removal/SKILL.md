---
name: oc-skin-removal
description: 按维护清单从 Objective-C 版 IMUIKit 的 UI 组件和示例 App 中完整移除 NormalUI（飞书/通用风格）或 FunUI（微信/娱乐风格）皮肤，包括专属源码、资源、路由、注册分支、Demo 外观入口和样式选择页，并给出保留皮肤的验证步骤。用户明确要求移除 OC 版某一套皮肤时使用；不适用于移除功能、Swift/SwiftUI 端或闭源 NEChatKit。
---

# OC Skin Removal

本 skill 随 OC 开源源码发布。用户只需说“移除 OC 版飞书/NormalUI 皮肤”或“移除 OC 版微信/FunUI 皮肤”，无需提供路径。删除的是**点名皮肤**，保留另一套皮肤的业务与 UI 能力。路径均相对 OC 开源仓库根目录；唯一业务范围是仓库根的 `NEChatUIKitOC/` 等组件目录、`NEBaseUIKitOC/`、`IMUIKitOCExample/`，只有登记过的样式选择页引用才修改 `IMUIKitOCExample.xcodeproj/`。不扫描、不修改闭源 `NEChatKit`、Swift/SwiftUI 工程或客户自己的 App。

OC 与 Swift 版结构的关键差异：

- 基础组件在 `NEBaseUIKitOC/`，其余组件在 `<Module>OC/`；Demo 是 `IMUIKitOCExample/`。
- 只有聊天、通讯录、群组三个组件有 `Classes/NormalUI|FunUI/` 目录；会话组件的皮肤类定义在共享文件（`NEConversationViewController.h/m`、`NEConversationListCell.h/m`），皮肤资源则在 `Assets/Normal|FunConversationUIKit.xcassets`。
- 基础皮肤资源是同一个 `NECommonUI.xcassets` 下的 `NormalUI/`、`FunUI/` 命名空间，不是独立 catalog。
- 皮肤选择通过 `setupInit:` 的 `isFun` 参数下发：各服务 `registerRouter:` 走 `registerFun` 或普通 `register`。Demo 的 `NEStyleManager.isNormalStyle` 会被组件层用 `NSClassFromString` 反射读取，是跨边界契约，不能直接删。

## 使用

1. 确定用户点名的皮肤：飞书/通用/NormalUI -> `normal`；微信/娱乐/FunUI -> `fun`。未点名时**先询问选哪套**，不可默认删除。读取对应 [NormalUI 清单](references/normal.md) 或 [FunUI 清单](references/fun.md)，以及 [结构化清单](references/skin-inventory.json)。无需做全仓二次发现。若仓库存在 `RULES.md`、模块 README 或更具体的 `AGENTS.md`，先遵循它们；缺失不阻塞。
2. 从本 skill 所在仓库定位源码根，检查 `git status --short`，有重叠改动逐段保留。先运行
   `python3 skills/oc-skin-removal/scripts/audit_inventory.py <skin> --verify-inventory`，确认没有
   `STALE`（已删除/漂移的路径）和 `OVERLAP`（共享路径落在皮肤专属目录内）；有问题先修清单，再运行
   `--phase before`。技能尚未复制进目标仓库时可加 `--repo /path/to/nim-uikit-ios-oc`。输出只读：专属目录、登记的共享迁移、工程引用和共享候选都会按清单列出，不需要再做全仓关键词扫描。若 `before` 报 `MISSING` 或 `MOVE ... missing`，先判定是版本漂移还是已部分移除，不能凭关键词扩大范围。
3. 按清单处理：先改保留皮肤的入口、路由注册、共享视图和颜色，再删除目标皮肤的专属路径与 Demo 类/资源；移除 Demo 工程对已删除文件的引用。使用 `apply_patch` 编辑；删除前逐一确认清单路径，保留无关工作树修改。共享 API（例如 `setupInitWithFunUI:`、`isFun` 参数）只有在仍有存活调用者或明确外部兼容要求时才保留，否则收敛掉。
4. 再运行审计脚本 `--phase after`，必须没有存活的专属路径、未完成的共享迁移、工程残留引用或未登记的共享候选；清单中明确保留的契约会显示为 `KEEP`，不应删除。检查 `git diff --check`。目标 checkout 结构或代码若漂移，针对**报告的具体路径**修正，并在同次改动更新清单文件，不能退化成客户每次全仓扫描。
5. 源码删除后重新 `pod install --no-repo-update`，因为 podspec 的 `Classes/**/*`、`Assets/**/*` 通配符会在生成的 Pods 工程中缓存旧文件。构建所有受影响组件 target 和 `IMUIKitOCExample`：
   `xcodebuild -workspace IMUIKitOCExample.xcworkspace -list` 与 `xcrun simctl list devices available` 获取真实 scheme/模拟器，例如
   `xcodebuild -workspace IMUIKitOCExample.xcworkspace -scheme IMUIKitOCExample -configuration Debug -destination 'platform=iOS Simulator,id=<实际UDID>' -derivedDataPath <独立构建目录> CODE_SIGNING_ALLOWED=NO build`。
   不能以只编译单个 `.m` 或 `clang -fsyntax-only` 描述成完整 App 可运行。
6. 在模拟器或设备启动**保留皮肤**，覆盖启动和登录后路由、云端/本地会话、联系人、单群聊、消息收发、搜索结果、标记/收藏、群设置、样式入口消失；检查图片/音频/富文本/回复等不同消息以及皮肤资源实际显示。没有登录凭证、依赖或设备时明确列出未验证项目；只有编译通过并实际启动/互动之后才能声称“正常编译、运行”。不要提交/推送，除非另有明确要求。

## 验证矩阵（10.9.30 模拟器实测）

- `normal`：真实删除 NormalUI 后 `xcodebuild` 通过，真实树 `--phase after` 为 0 unresolved（仅 `KEEP` 契约行），启动正常；FunUI 视觉不变。
- `fun`：真实删除 FunUI（含 `SearchSessionBaseView` 迁移）后 `xcodebuild` 通过，真实树 `--phase after` 为 0 unresolved，迁移输出 `MOVED`，启动正常。
- 两次实测的收敛要点已写入 `references/normal.md` / `references/fun.md` 的“实测收敛记录”。
- 运行时限制：模拟器数据容器在重装时丢失登录态，FunUI 移除后的列表/聊天页未能重新截图；构建、审计与启动均已验证。

## 共享替换与代码编辑

- 共享文件不能引用任一皮肤目录里的颜色或图片。删除皮肤后，把共享引用替换为 `NEBaseUIKitOC/NEBaseUIKitOC/Classes/Extensions/UIColor+NEUIKitDefault.h` 中的 `ne_default*` 公共色（值不允许变化）：`ne_normalTheme`/`normalContactThemeColor` → `ne_defaultPrimaryColor`，`normalChatReplyViewBg` → `ne_defaultReplyBackgroundColor`，`normalChatNavigationDivideBg`/`normalContactNavigationDivideBg` → `ne_defaultNavigationDividerColor`，`funChatLineBorderColor`/`funContactLineBorderColor` → `ne_defaultLineColor`。
- 图片替换：共享默认按钮引用的 `fun_chat_photo` / `fun_chat_aiChat` 改为公共 `NEBaseChatUIKit.xcassets/Chat/photo.imageset` 和保留皮肤的 `AIChat/ai_icon_default.imageset`（结合 UI 效果确认）；没有可用图时把必需图片迁到公共目录并改为中性名称。
- 禁止用 sed/正则批量改写 OC 的 `if (isNormalStyle) { A } else { B }`：控制流里常嵌 if/else，正则容易误删。逐处 `apply_patch`，改完检查括号、空分支和悬空 `#import`。
- 删除目录后，`#import "NormalXxx.h"`/`#import "FunXxx.h"` 必须一并清理；共享文件里只保留存活皮肤的 import。
- `NEBaseUIKitOC/NEBaseUIKitOC/Classes/CommonView/FunSearchView.h/m` 中的 `SearchSessionBaseView` 是 NormalUI 搜索头部仍使用的共享类型：移除 FunUI 时迁移到同目录 `SearchSessionBaseView.h/m`，并更新 `NEBaseUIKitOC.h`、`NEBaseConversationSearchController.m`、`NEConversationViewController.m` 与 `ConversationSearchController.h` 的 import；`FunSearchView`、`FunSearchSessionHeaderView` 随 FunUI 一起删除。
- `NEConversationViewController.h/m` 同时实现 `NormalConversationController` 与 `FunConversationController`；`NEConversationListCell.h/m` 同时实现 Normal/Fun/StickTop 变体。只删除目标皮肤的类、分支和资源引用，保留另一套与共享基类。
- 聊天、标记、收藏三张 cell 注册表在 `ChatMessageHelper.h/m`（`getChatCellRegisterDic:` / `getPinCellRegisterDic:` / `getCollectionCellRegisterDic:` 及 `...WithIsFun:`）。删除皮肤后注册表只保留存活类型；兼容入参 `isFun` 时忽略并返回存活类型。

## 编译陷阱（实测）

- 删除源码/资源后必须重跑 `pod install --no-repo-update`，否则 `Build input file cannot be found` 或 `actool` 仍打包已删资源。
- `NEChatUIKitOC.podspec` 的 `exclude_files` 登记了 `NEChatUIKitOC/Classes/NormalUI/NormalChatRouter.m`（真实编译的是 `Classes/Compat/NormalChatRouter.m`）。移除 NormalUI 时两处都要删，并删除这条 `exclude_files`，否则 podspec 指向不存在的文件。
- 会话组件没有 `Classes/NormalUI|FunUI` 目录，别把 `NEBase*Controller`、`NEBase*Cell` 当成皮肤专属基类删除。
- 删完必须真正编译保留皮肤对应的组件 target 和 `IMUIKitOCExample`；`clang -fsyntax-only` 不能替代。批量替换三元表达式后必须编译验证，容易吞掉行尾 `)`、`,`。

## 交付标准

客户拿到的最终代码里不应留下目标皮肤的任何形态，包括恒真/恒假的样式分支、空 override、空判断和仅剩转发的皮肤参数。唯一例外是组件层反射读取的 `NEStyleManager.isNormalStyle`：保留方法本身并把返回值固定为存活皮肤，删除被移除皮肤的 setter、样式选择页和本地化 key，不保留“固定返回旧皮肤”的选择入口。

## 清单维护

新增 UI 页面、Demo 入口或皮肤资源时，同一变更维护 `references/skin-inventory.json` 及对应皮肤说明；维护者可做一次范围发现，终端客户执行移除时只跑定向审计。若删除皮肤目录会暴露共享类型，登记 `shared_migrations`；若公开符号必须保留，登记 `accepted_candidates`，让审计明确输出 `KEEP`；若 Demo 工程有显式文件引用，登记 `project_cleanup`。脚本只审计登记的路径和行，不做全仓扫描，也不会自动删除文件。`before` 遇到预期路径缺失要查明是版本漂移或已部分移除；`after` 的候选行需结合上下文判断，不可凭关键词盲删。闭源 `NEChatKit` 永不纳入清单。
