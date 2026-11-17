# 功能清单模板

每个登记功能使用一个 `features/<slug>.md`，并同步 `feature-registry.json`。清单必须包含：

## 边界

- 只允许 `NEChatUIKitOC/` 与 `app/`；闭源 `NEChatKit` 不扫描、不修改。
- 说明本功能是否属于外部组件（如 `NEAdaptiveUIKitOC/`），外部组件只允许可选接线。

## 整体删除

- 功能专属目录 / 文件 / 资源（`.xcassets` imageset、原始资源、专题图标）。
- 本地化 key（组件 `Assets/*.lproj/Localizable.strings` 与 Demo `app/*.lproj/Localizable.strings` 分别列出）。
- 若没有整文件删除项，明确写“没有”。

## 必须编辑的接线

按文件列出要删除的类、属性、方法、回调、约束、通知、路由分支与资源引用；写明保留项，避免把共享能力一起删掉。

## 交叉边界

列出与其他功能共享的 guard / 队列 / 布局逻辑，说明只删本功能分支。

## 验证

- `audit_inventory.py <slug> --phase after` 无残留。
- `git diff --check`；重新 `pod install --no-repo-update` 后构建 `NEChatUIKitOC` 与 `app`。
- NormalUI / FunUI 运行时检查项。
- 最终 diff 范围检查。

## JSON 登记

在 `references/feature-registry.json` 增加：

```json
{
  "<slug>": {
    "aliases": ["中文名", "英文名"],
    "owned_paths": ["功能专属路径"],
    "edit_paths": ["需要编辑的共享文件"],
    "residual": {
      "roots": ["NEChatUIKitOC", "app"],
      "patterns": ["精确残留正则（避免 Action/Normal 等通用词误报）"],
      "allowed_paths": []
    }
  }
}
```

新增后运行 `--phase before`，确认没有 `inventory gap`（残留文件未登记）。
