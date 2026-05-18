## Why

项目需要将 xkit-ios 中所有 Swift 模块（NECommonKit、NECoreKit、NECommonUIKit、NECoreIM2Kit、NEChatKit）逐一转换为 Objective-C，以满足 OC 工程（NIMUIKitDemo）的使用需求。当前 OC 工程中大量文件缺失或为空壳，必须逐文件、逐行对齐实现。为规范转换流程，需创建一个可复用的 skill，指导后续所有 Swift → OC 转换工作。

## What Changes

- **新增 skill**：`swift-to-oc`，作为 `.codemaker/skills/swift-to-oc.md` 存储。
- skill 涵盖：Swift → OC 语法映射规则、模块转换检查清单、转换质量标准、以及在转换过程中如何持续完善 skill 本身。
- 后续每次转换 Swift 文件时，均激活该 skill 以保证一致性。

## Capabilities

### New Capabilities
- `swift-to-oc-skill`: 定义 Swift 转 OC 的完整规范——包括类型映射、并发模式、设计模式（singleton/delegate/protocol）、以及模块级文件对比清单格式。

### Modified Capabilities
<!-- 无 -->

## Impact

- 影响所有 `IMUIKit/NEChatKitOC/`、`IMUIKit/NECoreIM2KitOC/`、`NECommonUIKitOC/` 下的新建 OC 文件。
- 不影响已有 Swift 源码，不修改任何 Swift 文件。
- 为团队后续维护提供统一规范文档。
