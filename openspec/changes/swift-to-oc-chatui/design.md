## Context

当前 NIMUIKitDemo 项目已完成以下 OC 模块的转换：
- NECoreKitOC（基础工具层）
- NECoreIM2KitOC（IM 核心层：IMKitClient、Provider、Listener）
- NEChatKitOC（业务逻辑层：Repo、Cache、Manager）
- NECommonKitOC（公共工具层）
- NECommonUIKitOC（公共 UI 层：BaseViewController、NEUserHeaderView、RedAngleLabel 等）
- NEConversationUIKitOC（会话列表 UI 层）

NEChatUIKit（Swift）是聊天 UI 的核心模块，包含消息展示、输入、表情、录音、转发、Pin、收藏、Markdown 渲染等完整功能。本次需要将其转换为 NEChatUIKitOC。

Swift 源码路径：`/Users/zhangshiwen/NetEase/GitLab/xkit-ios/IMUIKit/NEChatUIKit/NEChatUIKit/Classes/`
OC 输出路径：`/Users/zhangshiwen/NetEase/GitLab/NIM/NIMUIKitDemo/IMUIKit/NEChatUIKitOC/NEChatUIKitOC/Classes/`

## Goals / Non-Goals

**Goals:**
- 1:1 逻辑镜像转换 Swift → OC，保持所有业务逻辑路径完全一致
- 保持与 Swift 版相同的 MVVM-C 架构
- 所有 public/open API 保持一致的方法签名（OC 适配后的等价签名）
- 仅转换 Base 层通用代码，NormalUI/FunUI 皮肤层本批次不转换
- 转换后的模块能编译通过并与其他 OC 模块协同工作

**Non-Goals:**
- 不改变任何业务逻辑或 UI 交互流程
- 不优化或重构 Swift 原有的代码设计
- 不转换 NormalUI/FunUI 皮肤变体（后续单独批次）
- 不转换单元测试（如有）
- 不修改 Swift 基准仓库或 NIMLib；本设计只约束 NIMUIKitDemo 内 OC 同构实现
- 不新增 `NELocalConversationUIKitOC`；本地会话能力继续由 `NEConversationUIKitOC` + `NEChatKitOC` 承载，Swift `NELocalConversationUIKit` 后续按删除/合并处理
- 不转换 `NEQChatKit` / `NEQChatUIKit`，也不规划 `NEQChatKitOC` / `NEQChatUIKitOC`

## Decisions

### 1. 目录结构：镜像 Swift 目录布局
**决策**：OC 目录结构与 Swift 完全一一对应。
**理由**：便于后续维护对照，降低认知负担。
```
Classes/
├── Base/           → BaseView/ + BaseViewController/ + Service
├── Chat/
│   ├── Controller/
│   ├── Emoji/
│   ├── Helper/
│   ├── HistorySearch/
│   ├── Model/
│   ├── View/Cell/ + ChatView/
│   └── ViewModel/
├── ChatConfig/
├── ChatRouter/
├── Common/
├── Extension/      → OC Categories
├── Markdown/
└── Protocol/
```

### 2. Swift 语言特性 → OC 等价转换规则

| Swift 特性 | OC 转换方式 |
|---|---|
| `protocol` | `@protocol` |
| `extension Type` | `Type (CategoryName)` category |
| `enum` with raw value | `NS_ENUM(NSInteger, ...)` |
| `enum` with associated value | 独立类 + type 字段 |
| `struct` (value type) | `NSObject` 子类 (引用语义) |
| `class` inheritance | `@interface` + `@implementation` |
| `open class` | `@interface`（OC 默认可继承） |
| `let` / `var` | `@property (readonly)` / `@property` |
| `closure` | `block` typedef |
| `optional` | `nullable` 注解 |
| `guard let` | `if (!obj) return;` |
| `if let` | `if (obj)` |
| `weak self` in closure | `__weak typeof(self) weakSelf = self;` + `__strong` dance |
| `lazy var` | getter 懒加载模式 |
| `didSet` / `willSet` | 自定义 setter |
| `@objc` / `@objcMembers` | 默认可用（OC 原生） |
| `String` interpolation | `[NSString stringWithFormat:]` |
| `Array<T>` / `Dictionary<K,V>` | `NSArray<T>` / `NSDictionary<K,V>` |
| `Set<T>` | `NSSet<T>` |
| `try/catch` | `NSError **` 参数或 completion block |
| `async/await` | completion block |
| `NotificationCenter` | `NSNotificationCenter` |
| `DispatchQueue` | `dispatch_queue_t` + GCD |

### 3. 依赖映射
| Swift 依赖 | OC 等价 |
|---|---|
| `NEChatKit` | `NEChatKitOC` |
| `NECommonUIKit` | `NECommonUIKitOC` |
| `NECoreIM2Kit` | `NECoreIM2KitOC` |
| `NECoreKit` | `NECoreKitOC` |
| `NECommonKit` | `NECommonKitOC` |
| `NIMSDK` | `NIMSDK`（不变） |
| `SDWebImage` | `SDWebImage`（不变） |

### 4. 文件命名规则
- Swift 单文件包含多个类/扩展 → OC 拆分为每个类一对 .h/.m
- Extension 文件 → Category 文件命名：`ClassName+CategoryName.h/m`
- 类名保持不变（已使用 NE 前缀）

### 5. 转换顺序（依赖关系驱动）
```
Phase 1: Base + Common + Config + Protocol + Extension + Router
Phase 2: Models (22 个消息模型)
Phase 3: Helpers (8 个工具类)
Phase 4: Emoji (8 个表情组件)
Phase 5: ViewModels (10 个)
Phase 6: Views + Cells (60+ 视图和 Cell)
Phase 7: Controllers (10+ 控制器)
Phase 8: HistorySearch (12 个)
Phase 9: Markdown (26 个解析器)
Phase 10: Podspec + PodConfig + 集成验证
```

### 6. SDK 枚举格式
所有 V2NIM SDK 枚举使用 `V2NIM_UPPER_SNAKE_CASE` 格式（与前几个模块已验证的规则一致）。

### 7. Block 类型桥接
Provider 层返回 `V2NIMError` → Repo/ViewModel 层暴露 `NSError`，使用 `.nserror` 转换。

## Risks / Trade-offs

- **[风险] 300+ 文件转换量大，容易出现遗漏** → 每个 Phase 转换后执行编译验证，发现编译错误立即修复
- **[风险] Swift 泛型特性无法完美转换** → 使用 `id` 类型或协议约束作为替代
- **[风险] Swift 值类型语义与 OC 引用类型差异** → 在必要时添加 `copy` 语义的 property attribute
- **[风险] Swift extension 中的 stored property** → 使用 `objc_getAssociatedObject`/`objc_setAssociatedObject`
- **[风险] 资源/本地化 bundle 差异** → 对齐 Swift 的模块资源归属；本地消息、会话预览和 extension 写入前必须解析文案，禁止持久化本地化 key
- **[权衡] 仅转换 Base 层** → 减少工作量，但 NormalUI/FunUI 需后续单独转换才能完整使用
