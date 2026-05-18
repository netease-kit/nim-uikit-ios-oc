## 1. 创建 swift-to-oc skill 文件

- [ ] 1.1 创建 `.codemaker/skills/swift-to-oc.md`，包含完整的六个 Section
- [ ] 1.2 填写语法速查表（Swift → OC 对照）
- [ ] 1.3 填写模式映射（singleton/delegate/protocol/extension/enum/closure/MultiDelegate）
- [ ] 1.4 填写并发安全模式（barrier/NSHashTable/NSLock）
- [ ] 1.5 填写可空性规范（NS_ASSUME_NONNULL/nullable）
- [ ] 1.6 填写文件组织规范（.h/.m 拆分、#pragma mark）
- [ ] 1.7 填写转换检查清单（9 步核对）
- [ ] 1.8 创建 `## 经验积累` Section（初始为空）

## 2. NEChatKitOC — Repo 层转换

- [ ] 2.1 转换 `ConversationRepo.swift` → `ConversationRepo.h/m`
- [ ] 2.2 转换 `LocalConversationRepo.swift` → `LocalConversationRepo.h/m`
- [ ] 2.3 转换 `ContactRepo.swift` → `ContactRepo.h/m`
- [ ] 2.4 转换 `TeamRepo.swift` → `TeamRepo.h/m`（前 500 行）
- [ ] 2.5 转换 `TeamRepo.swift` → `TeamRepo.h/m`（后半部分）
- [ ] 2.6 转换 `ChatRepo.swift` → `ChatRepo.h/m`（消息发送/撤回/Pin，前 400 行）
- [ ] 2.7 转换 `ChatRepo.swift` → `ChatRepo.h/m`（消息查询/已读，400-800 行）
- [ ] 2.8 转换 `ChatRepo.swift` → `ChatRepo.h/m`（事件监听/其余，800-1161 行）

## 3. NEChatKitOC — Common 层剩余转换

- [ ] 3.1 转换 `NEAIUserManager.swift` → `NEAIUserManager.h/m`
- [ ] 3.2 转换 `NEAIRobotManager.swift` → `NEAIRobotManager.h/m`
- [ ] 3.3 转换 `NEAIUserPinManager.swift` → `NEAIUserPinManager.h/m`
- [ ] 3.4 转换 `NEFriendUserCache.swift` → `NEFriendUserCache.h/m`
- [ ] 3.5 转换 `NESubscribeManager.swift` → `NESubscribeManager.h/m`

## 4. 更新 skill 经验积累

- [ ] 4.1 追加 Repo 层转换中发现的新规则到 skill 的 `## 经验积累`
- [ ] 4.2 追加 Common 层转换中发现的新规则

## 5. NECommonUIKitOC — 补齐缺失文件（共约 90 个）

- [ ] 5.1 扫描 Swift 源码中 NECommonUIKit 所有文件清单
- [ ] 5.2 批量转换 Category 类文件（UIView/UIColor/UIImage 等扩展）
- [ ] 5.3 批量转换 UI 组件类（NELabel/NEButton/NEBaseViewController 等）
- [ ] 5.4 更新 skill 经验积累
