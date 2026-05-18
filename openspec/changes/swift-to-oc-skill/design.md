## Context

xkit-ios Swift 工程包含 5 个模块（NECommonKit、NECoreKit、NECommonUIKit、NECoreIM2Kit、NEChatKit），每个模块均需转换为对等的 OC 模块。转换工作量大，需要统一规范避免遗漏和不一致。

当前状态：
- NECommonKit / NECoreKit：100% 完成
- NECoreIM2Kit：~60% 完成
- NEChatKit：~60% 完成（本轮大幅推进）
- NECommonUIKit：~10% 完成（最欠缺）

## Goals / Non-Goals

**Goals:**
- 建立可复用的 Swift→OC 转换 skill（`.codemaker/skills/swift-to-oc.md`）
- 覆盖语法映射、模式映射、并发安全、可空性标注等全部规则
- skill 在每次转换后持续迭代更新，沉淀新发现的规则

**Non-Goals:**
- 不重构 Swift 源码
- 不修改已完成的 OC 文件（除非发现 bug）
- 不创建单元测试（另行规划）

## Decisions

### D1：skill 存储位置
**决定**：放在 `.codemaker/skills/swift-to-oc.md`  
**理由**：CodeMaker 会自动加载 `.codemaker/skills/` 下的 skill，支持 `use_skill` 调用。

### D2：skill 结构
**决定**：分为 6 个 Section：
1. 语法速查表（Swift → OC 对照）
2. 模式映射（singleton/delegate/protocol/extension/enum/closure）
3. 并发安全模式（DispatchQueue barrier / NSHashTable / NSLock）
4. 可空性规范（NS_ASSUME_NONNULL / nullable / nonnull）
5. 文件组织规范（.h/.m 拆分、#pragma mark 分组）
6. 转换检查清单（逐文件核对步骤）

### D3：持续完善机制
**决定**：每完成一批文件转换后，将新发现的规则 append 到 skill 的 "经验积累" section  
**理由**：避免重复踩坑，形成活文档。

## Risks / Trade-offs

- [NIMSDK API 差异] → 部分 OC API 签名与 Swift 不完全对称，需人工核对 NIMSDK OC 头文件
- [skill 膨胀] → 定期整理合并相似规则，保持可读性
- [上下文截断] → 超大文件（如 ChatRepo 1161 行）分多轮转换，每轮聚焦特定功能块
