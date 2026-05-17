## ADDED Requirements

### Requirement: Swift-to-OC skill 文件存在且结构完整
`.codemaker/skills/swift-to-oc.md` SHALL 存在，并包含以下六个主要 Section：语法速查表、模式映射、并发安全、可空性规范、文件组织规范、转换检查清单。

#### Scenario: skill 可被 use_skill 激活
- **WHEN** 调用 `use_skill("swift-to-oc")` 时
- **THEN** 系统返回完整的 skill 指令内容，助手按照 skill 规则执行转换

### Requirement: 语法速查表覆盖核心 Swift→OC 映射
skill SHALL 提供完整的 Swift 语法到 OC 语法的对照表，至少涵盖：变量/常量、可选值、闭包/Block、枚举、扩展/Category、泛型、错误处理。

#### Scenario: 可选值映射
- **WHEN** Swift 源码中出现 `String?` 时
- **THEN** OC 转换结果使用 `nullable NSString *` 并配合 `NS_ASSUME_NONNULL_BEGIN/END`

#### Scenario: 闭包映射为 Block
- **WHEN** Swift 源码中出现 `((Error?) -> Void)?` 时
- **THEN** OC 转换结果使用 `nullable void (^)(NSError *_Nullable)` typedef 或内联 Block

### Requirement: 模式映射覆盖常见设计模式
skill SHALL 对 Singleton、Delegate、Protocol、Extension→Category、MultiDelegate→NSHashTable 提供标准 OC 实现模板。

#### Scenario: Singleton 转换
- **WHEN** Swift 中出现 `static let shared = Xxx()` 时
- **THEN** OC 使用 `dispatch_once_t` + `+ (instancetype)shared` 实现

#### Scenario: MultiDelegate 转换
- **WHEN** Swift 中出现 `MultiDelegate<T>` 时
- **THEN** OC 使用 `NSHashTable<id<T>> *` + `dispatch_queue_t` (concurrent + barrier) 实现线程安全

### Requirement: 并发安全模式标准化
skill SHALL 规定所有涉及多线程读写的集合（数组、字典、HashTable）必须使用 barrier 写/sync 读模式。

#### Scenario: 并发读写保护
- **WHEN** Swift 中使用 `DispatchQueue(label:, attributes: .concurrent)` + `.async(flags: .barrier)` 时
- **THEN** OC 使用等价的 `dispatch_barrier_async` 写，`dispatch_sync` 读

### Requirement: 可空性标注规范
skill SHALL 要求所有 `.h` 文件在 `NS_ASSUME_NONNULL_BEGIN/END` 内声明，仅对真正可空的参数/返回值显式标 `nullable`。

#### Scenario: 返回值可空
- **WHEN** Swift 方法返回 `String?` 时
- **THEN** OC 方法声明为 `- (nullable NSString *)xxx`

### Requirement: 转换检查清单完整
skill SHALL 提供逐文件转换的 9 步检查清单，确保不遗漏任何细节。

#### Scenario: 检查清单全部通过
- **WHEN** 完成一个 Swift 文件的 OC 转换时
- **THEN** 必须逐一核对清单：文件头版权、import、类声明、属性、方法、私有扩展、#pragma mark、NS_ASSUME_NONNULL、文件名对应关系

### Requirement: skill 可持续演进
skill SHALL 包含 `## 经验积累` Section，在每批转换完成后 append 新发现的规则。

#### Scenario: 新规则追加
- **WHEN** 转换过程中发现新的映射规则或踩坑点时
- **THEN** 将规则以 `- **[规则名]**：说明` 格式追加到 `## 经验积累` Section
