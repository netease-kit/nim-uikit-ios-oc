网易云信即时通讯界面组件（简称 IM UIKit）是基于 [NIM SDK（网易云信 IM SDK）](https://doc.yunxin.163.com/messaging2/concept/DI0Nzc2NzA?platform=client) 开发的一款即时通讯 UI 组件库，包括聊天、会话、圈组、搜索、通讯录、群管理等组件。通过 IM UIKit，您可快速集成包含 UI 界面的即时通讯应用。

本仓库是 IM UIKit 的 **Objective-C 版**开源工程，包含全部 OC UI 组件源码、Demo 工程与配套 Skills。

## 适用客群

IM UIKit 简化了基于 NIM SDK 的应用开发过程，适合需要快速集成和定制即时通讯功能的开发者和企业客户。它不仅能助您快速实现 UI 功能，也支持调用 NIM SDK 相应的接口实现即时通讯业务逻辑和数据处理。因此，您在使用 IM UIKit 时仅需关注自身业务或个性化扩展。

<img alt="image.png" src="https://yx-web-nosdn.netease.im/common/ca3caa267f692e518d391f07e805aac9/image.png" style="width:65%;border: 0px solid #BFBFBF;">

## 主要功能

IM UIKit 主要分为会话、群组、联系人等几个 UI 子组件，每个 UI 组件负责展示不同的内容。更多详情，请参考 [功能概览](https://doc.yunxin.163.com/messaging-uikit/concept/zMzMDQ2MTg?platform=client) 和 [UI 组件介绍](https://doc.yunxin.163.com/messaging-uikit/concept/TI3NTgyNDA?platform=client)。

<img alt="image.png" src="https://yx-web-nosdn.netease.im/common/2deec52ef5a09b7f279844945613e8cc/image.png" style="width:65%;border: 0px solid #BFBFBF;">

## 功能优势

### 组件解耦

IM UIKit 不同组件可相互独立运行使用。您可按需选择组件，将其快速集成到您的应用，实现相应的 UI 功能，减少无用依赖。

### 简洁易用

IM UIKit 的业务逻辑层与 UI 层相互独立。在 UI 层，您仅需关注视图展示和事件处理。IM UIKit 清晰的数据流转处理，让 UI 层代码更简洁易懂。

### 自定义能力

IM UIKit 支持在各 UI 组件的初始化过程中配置自定义 UI。同时提供 Controller 和 View 的能力封装，助您快速将 UI 功能添加到您的应用中。

### 业务逻辑处理

IM UIKit 业务逻辑层提供完善的业务逻辑处理能力。您无需关心 SDK 层不同接口间的复杂处理逻辑，业务逻辑层一个接口帮您搞定所有。

## 工作原理

IM UIKit 采用 MVVM（Model–View–ViewModel）架构模型，实现 UI 展示与业务逻辑开发的相互独立。

<img alt="IMuikitDataFlow_iOS.png" src="https://yx-web-nosdn.netease.im/common/4526057a8ef3f59f6c65c56c42991de9/IMuikitDataFlow_iOS.png" style="width:60%;border: 1px solid #BFBFBF;">

流程 | 说明
---- | ----
1 | IM UIKit 展示层的 UIViewController/View 向响应层的 ViewModel 发送请求。
2 | ViewModel 将请求经由业务逻辑层转发至 NIM SDK（网易云信 IM SDK）。
3 | NIM SDK 接收请求后触发回调，回调数据经由业务逻辑层和响应层发送至 UIViewController/View。
4 | UIViewController/View 将回调数据发送至 UITableViewDelegate 和 UITableViewDataSource。后两者根据需在界面上展示的不同实体的 identifier，判定具体的 UI 样式。例如，SDK 返回的回调数据为消息数据时，UITableViewDelegate 和 UITableViewDataSource 可通过消息数据中包含的代表消息类型的 Identifier，将消息在 UI 上展示为对应类型的样式。

## 组件架构

<img alt="app_structure_iOS.png" src="https://yx-web-nosdn.netease.im/common/455980c6d4cdf15bff3cd9e4666d84d4/app_structure_iOS.png" style="width:60%;border: 1px solid #BFBFBF;">

上图中：

- UIKit UI 层的 `NEChatUIKitOC`、`NEContactUIKitOC`、`NEConversationUIKitOC` 和 `NETeamUIKitOC`，对应上述工作原理图中的 UIViewController/View。
- 基础 UI 组件 `NEBaseUIKitOC`、自适应呈现组件 `NEAdaptiveUIKitOC`、AI 划词搜索组件 `NEAISearchKitOC`；`NEMapKitOC` 为地图占位组件，默认不在 Demo 中集成。
- 闭源 `NEChatKit` 对应上述工作原理图中的 Repository，`NECoreKit` 层对应 Provider。

## 工程结构

- `IMUIKitOCExample/`：Demo App 源码与资源。
- `NEBaseUIKitOC/`：Objective-C 公共 UI 基础组件源码。
- `NEAdaptiveUIKitOC/`、`NEChatUIKitOC/`、`NEContactUIKitOC/`、`NEConversationUIKitOC/`、`NETeamUIKitOC/`、`NEAISearchKitOC/`：Objective-C IM UIKit 组件源码与 podspec。
- `NEMapKitOC/`：地图占位组件源码，默认不在 Demo 中集成。
- `PodConfigs/`：Pod 依赖与组件版本配置（含 `config_third.rb` 第三方版本）。
- `skills/`：随源码发布的移除类 Skills（`oc-skin-removal`、`oc-feature-removal`）。
- `IMUIKitOCExample.xcodeproj` / `IMUIKitOCExample.xcworkspace`：Demo App 工程与工作区。

## 使用方式

```sh
pod install
open IMUIKitOCExample.xcworkspace
```

默认使用本地 OC UIKit 组件源码。也可以通过 Podfile 注释切换为远端二进制依赖（官方 CocoaPods 上的 `10.9.31`）。

`Podfile` 中预留了云信 Specs 镜像；需要从云信源解析 OC UIKit 组件时，取消对应 `source` 行的注释（保留官方源以解析呼叫等仅发布在官方源的依赖），然后重新执行 `pod install`。

## 本地凭据

公开仓库不包含 AppKey、账号、Token、推送证书名或测试环境服务地址。首次运行前创建本地配置文件：

```sh
cp IMUIKitOCExample/Main/AppKey.private.h.example IMUIKitOCExample/Main/AppKey.private.h
```

在 `AppKey.private.h` 中填写自己项目的凭据。该文件已被 Git 忽略，不应提交。私有化环境请在应用的私有化配置页面填写自己的服务端配置。

## 移除类 Skills

- `skills/oc-skin-removal`：按维护清单移除 NormalUI（飞书风格）或 FunUI（微信风格）整套皮肤。
- `skills/oc-feature-removal`：按维护清单移除已登记功能（表情评论、最早未读、自适应外壳可选接线）。

每个 Skill 自带只读审计脚本，例如：

```sh
python3 skills/oc-skin-removal/scripts/audit_inventory.py --list
python3 skills/oc-skin-removal/scripts/audit_inventory.py normal --verify-inventory
python3 skills/oc-feature-removal/scripts/audit_inventory.py --list
```

## 验证

```sh
xcodebuild -workspace IMUIKitOCExample.xcworkspace -scheme IMUIKitOCExample -sdk iphonesimulator -configuration Debug build
```

## 相关文档

- IM UIKit 的功能清单，请参考 [IM UIKit 功能概览](https://doc.yunxin.163.com/messaging-uikit/concept/zMzMDQ2MTg)。
- IM UIKit 的集成流程，请参考 [集成开发文档](https://doc.yunxin.163.com/messaging-uikit/guide/DU4NzAzNzQ?platform=android)。
- IM UIKit 已支持音视频通话，具体实现流程请参考 [实现音视频通话功能](https://doc.yunxin.163.com/messaging-uikit/guide/zIzMTgxNDk?platform=iOS)。
