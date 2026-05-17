## Context

当前需要一套专门面向 Swift UIKit → SwiftUI 的迁移规范，并且这套规范需要足够通用，不能绑定具体仓库中的工程名、模块名、Demo 目录或业务组织方式。

本次不是直接实施某个项目的 SwiftUI 重写，而是先建立可复用的迁移 skill，作为后续页面、模块甚至其他仓库迁移的统一基线。

## Goals / Non-Goals

**Goals:**
- 建立可复用的 Swift UIKit → SwiftUI 迁移 skill（`.codemaker/skills/swift-to-swiftui.md`）
- 覆盖 UI 映射、状态建模、导航方案、Bridge 策略、文件组织和模块级检查清单
- 明确 skill 与项目专属方案的边界，避免仓库绑定信息污染 skill

**Non-Goals:**
- 不在本次变更中直接迁移现有页面到 SwiftUI
- 不重构底层 Swift 业务逻辑
- 不要求首版方案把所有复杂 UIKit 组件改成纯 SwiftUI
- 不定义任何特定项目的 Demo 名称、工程结构、模块命名或 Pod 组织方式

## Decisions

### D1：skill 存储位置
**决定**：放在 `.codemaker/skills/swift-to-swiftui.md`  
**理由**：与现有 `swift-to-oc` skill 保持一致，便于统一加载和使用。

### D2：目标粒度
**决定**：以模块级方案为主，而不是页面级实施清单  
**理由**：当前需要先建立统一规范，模块级结构更适合作为长期迁移框架。

### D3：默认迁移边界
**决定**：skill 默认只描述 UI 层到 SwiftUI 的迁移，业务层默认复用  
**理由**：SwiftUI 的核心收益在 UI 壳层与状态组织；底层业务模块强行同步重写收益低、风险高。

### D4：导航方案
**决定**：默认使用 `NavigationStack + 路由状态对象`  
**理由**：直接复制 UIKit Router 容易把旧导航模型带入 SwiftUI，破坏声明式结构。

### D5：复杂 UIKit 能力处理方式
**决定**：允许 `UIViewRepresentable` / `UIViewControllerRepresentable` 作为 Bridge  
**理由**：聊天输入、地图、图片浏览、复杂富文本等能力很难一步到位纯 SwiftUI，桥接是可控兜底方案。

### D6：状态规范
**决定**：页面状态统一使用 `ObservableObject`，页面主状态由 `@StateObject` 持有  
**理由**：便于规范数据流、降低 SwiftUI 页面失控重绘和状态分裂风险。

### D7：列表默认选型
**决定**：普通长列表默认 `ScrollView + LazyVStack`，特殊场景再使用 `List`  
**理由**：这更接近现有 UIKit 列表的布局控制能力，对聊天、会话、通讯录等页面更可控。

### D8：skill 与项目方案分离
**决定**：skill 仅保留可复用迁移规则；具体 Demo 名称、模块命名、目录结构和工程接入方式必须放到独立项目方案文档中  
**理由**：这些内容高度依赖具体仓库，写进 skill 会削弱其复用价值。

## Risks / Trade-offs

- [UIKit 生命周期与 SwiftUI 生命周期不对称] → 需要用 `.task` / `onAppear` / `onDisappear` 明确接管副作用，避免逻辑丢失
- [Router 迁移不彻底] → 如果机械保留旧 Router，SwiftUI 页面容易退化为“声明式外壳 + UIKit 内核”
- [Bridge 滥用] → 若大量页面整体包进 representable，会失去 SwiftUI 迁移的真正价值
- [高频消息页面性能风险] → 聊天页若状态拆分不当，会触发过度刷新和滚动异常
- [主题系统割裂] → 如果仍依赖 UIKit appearance 作主路径，SwiftUI 双皮肤会难以收敛
