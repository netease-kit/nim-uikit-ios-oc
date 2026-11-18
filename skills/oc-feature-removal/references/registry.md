# Feature 登记表

用户点名“移除……功能/去掉……功能/删除……功能”时，只加载命中的那一份清单；未命中不要自动套用。

| 需求 | 别名 | 清单 |
| --- | --- | --- |
| 表情评论 | 表情评论 / Emoji Reaction / Reaction / 快捷表情评论 | [features/emoji-reaction.md](features/emoji-reaction.md) |
| 跳转最早未读 | 跳转最早未读 / 上次阅读位置 / Last Read / Earliest Unread | [features/earliest-unread.md](features/earliest-unread.md) |
| 自适应外壳 | 自适应外壳 / 折叠屏外壳 / Duo UI / Foldable Shell | [features/adaptive-shell.md](features/adaptive-shell.md)（仅可选接线，`NEAdaptiveUIKitOC/` 为外部组件边界） |

结构化审计数据见 `feature-registry.json`：

```bash
python3 skills/oc-feature-removal/scripts/audit_inventory.py --list
python3 skills/oc-feature-removal/scripts/audit_inventory.py <feature> --phase before
# skill 尚未放入目标仓库时：追加 --repo /absolute/path/to/nim-uikit-ios-oc
```
