## Why

当前仓库已经有项目专属的 UI 迁移与重写方案，但还缺少一套真正可复用的 Swift UIKit → SwiftUI 迁移 skill。现有 skill 文档如果绑定具体工程名、模块名或 Demo 结构，就无法作为跨模块、跨项目的统一规范使用。

为规范迁移流程，需创建一个不依赖特定仓库结构、Demo 名称、模块命名的通用 skill，统一指导后续 Swift UIKit → SwiftUI 转换工作。

## What Changes

- **新增 skill**：`swift-to-swiftui`，作为 `.codemaker/skills/swift-to-swiftui.md` 存储。
- skill 涵盖：UIKit → SwiftUI 语法映射规则、页面/状态/导航的标准拆分方式、复杂 UIKit 组件的桥接规则、以及模块级迁移检查清单。
- skill 明确不承载项目专属的工程结构、模块命名、Demo 目录或接入方式。
- 后续每次迁移 Swift UIKit 文件时，均激活该 skill 以保证一致性。

## Capabilities

### New Capabilities
- `swift-to-swiftui-skill`: 定义 Swift UIKit 转 SwiftUI 的通用规范，包括 UI 映射、状态建模、导航迁移、Bridge 约束、文件拆分和检查标准。

### Modified Capabilities
<!-- 无 -->

## Impact

- 影响后续所有 Swift UIKit → SwiftUI 的迁移工作。
- 不要求修改已有底层业务模块的公开接口，仅规范其在 SwiftUI 页面中的接入方式。
- 项目专属的 Demo 方案、模块命名和工程目录需放在独立文档中，不再写入 skill。
