## 1. 创建 swift-to-swiftui skill 文件

- [x] 1.1 创建 `.codemaker/skills/swift-to-swiftui.md`
- [x] 1.2 填写 UIKit → SwiftUI 语法速查表
- [x] 1.3 填写页面/导航/列表/Bridge 的模式映射
- [x] 1.4 填写状态与并发规范（`ObservableObject` / `StateObject` / `Binding` / `MainActor`）
- [x] 1.5 填写文件组织规范（View / ViewModel / Bridge / RowView 拆分）
- [x] 1.6 填写逐页面 / 逐模块都可适用的迁移检查清单
- [x] 1.7 创建 `## 经验积累` Section（初始含默认规则）
- [x] 1.8 去除仓库专属信息（Demo 名称、目录、模块命名、Pod 组织）

## 2. 建立通用迁移策略

- [x] 2.1 定义通用列表页的 SwiftUI 迁移策略
- [x] 2.2 定义通用表单/设置页的 SwiftUI 迁移策略
- [x] 2.3 定义详情页和导航流的 SwiftUI 迁移策略
- [x] 2.4 定义高交互页面的 SwiftUI 迁移策略
- [x] 2.5 定义多主题/多皮肤页面的 SwiftUI 迁移策略

## 3. 明确 UIKit Bridge 边界

- [x] 3.1 定义允许保留 UIKit 包装的场景（输入框、地图、图片浏览、复杂富文本）
- [x] 3.2 定义 Bridge 文件的职责边界
- [x] 3.3 定义旧 Router 与 SwiftUI 路由状态的衔接方式

## 4. 更新 skill 经验积累

- [x] 4.1 追加模块级迁移中发现的新规则
- [x] 4.2 追加高交互页面（尤其聊天页）迁移中的新规则
