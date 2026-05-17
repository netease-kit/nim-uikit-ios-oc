## ADDED Requirements

### Requirement: Swift-to-SwiftUI skill 文件存在且结构完整
`.codemaker/skills/swift-to-swiftui.md` SHALL 存在，并包含以下主要 Section：适用范围、激活后的行为规范、UIKit → SwiftUI 语法速查表、模式映射、状态与并发规范、文件组织规范、转换检查清单、经验积累。

#### Scenario: skill 可被 use_skill 激活
- **WHEN** 调用 `use_skill("swift-to-swiftui")` 时
- **THEN** 系统返回完整的 skill 指令内容，助手按照 skill 规则执行迁移

### Requirement: 语法速查表覆盖核心 UIKit → SwiftUI 映射
skill SHALL 提供完整的 UIKit 页面、列表、导航、约束、交互和桥接能力的 SwiftUI 对照表，至少涵盖：`UIViewController`、`UIView`、`UITableView`、`UICollectionView`、`UIAlertController`、`UINavigationController push/present`、delegate/dataSource。

#### Scenario: 列表映射
- **WHEN** UIKit 页面使用 `UITableView` 展示任意数据列表
- **THEN** skill 给出 `List` 或 `ScrollView + LazyVStack` 的标准迁移方式

#### Scenario: 导航映射
- **WHEN** UIKit 页面通过 Router 或 `pushViewController` 跳转
- **THEN** skill 给出 `NavigationStack + 路由状态对象` 的标准迁移方式

### Requirement: 模式映射覆盖页面、路由和 Bridge
skill SHALL 对页面拆分、ViewModel 拆分、路由迁移、复杂 UIKit 组件桥接提供标准实现模板。

#### Scenario: 页面拆分
- **WHEN** Swift UIKit 页面迁移为 SwiftUI
- **THEN** skill 要求默认拆为 `XxxView`、`XxxViewModel`、必要的 `XxxBridgeView`

#### Scenario: UIKit Bridge
- **WHEN** 页面依赖复杂输入框、地图或图片浏览能力
- **THEN** skill 允许使用 `UIViewRepresentable` 或 `UIViewControllerRepresentable` 包装，而不是要求强行纯 SwiftUI

### Requirement: 状态与并发模式标准化
skill SHALL 规定页面主状态统一由 `ObservableObject` 输出，页面级 ViewModel 由 `@StateObject` 持有，UI 状态更新默认在主线程完成。

#### Scenario: 页面拥有 ViewModel
- **WHEN** SwiftUI 页面持有自己的状态对象
- **THEN** 应使用 `@StateObject` 而不是 `@ObservedObject`

#### Scenario: 异步加载
- **WHEN** 页面在首次进入时加载列表、详情或表单所需数据
- **THEN** skill 要求通过 `.task` 或显式异步入口触发，并由 ViewModel 更新 `@Published` 状态

### Requirement: 通用迁移边界明确
skill SHALL 明确其关注 UI 层迁移和状态组织，不绑定任何特定仓库模块命名，并默认复用已有业务逻辑层。

#### Scenario: UI 层迁移
- **WHEN** 迁移列表页、详情页、设置页或聊天页等 UIKit 页面
- **THEN** 方案聚焦页面、列表、导航、主题和交互层，不要求同步重写底层业务 Repo / Provider

### Requirement: 转换检查清单完整
skill SHALL 提供逐页面或逐模块的检查清单，确保导航、状态、交互、主题和性能未被遗漏。

#### Scenario: 高交互页面检查
- **WHEN** 完成聊天页、富输入页或实时协作页等高交互页面的 SwiftUI 迁移
- **THEN** 必须核对滚动、输入联动、底部面板、返回、空态和主题切换等行为是否完整

### Requirement: skill 不绑定项目专属结构
skill SHALL 不包含具体 Demo 名称、模块命名、目录路径、Pod 组织方式或工程结构。

#### Scenario: 项目专属信息隔离
- **WHEN** 项目需要定义自己的 Demo 工程、模块名或目录结构
- **THEN** 这些内容应放在独立项目方案文档中，而不是写入 skill

### Requirement: skill 可持续演进
skill SHALL 包含 `## 经验积累` Section，在每批迁移完成后 append 新发现的规则。

#### Scenario: 新规则追加
- **WHEN** 迁移过程中发现新的 UIKit → SwiftUI 规则或 Bridge 边界
- **THEN** 将规则以 `- **[规则名]**：说明` 格式追加到 `## 经验积累` Section
