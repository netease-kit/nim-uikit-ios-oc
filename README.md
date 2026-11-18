# NIM UIKit iOS OC Demo

网易云信 IM UIKit Objective-C Demo 工程，目录结构对齐 Swift 版 GitHub Demo：

- `app/`：Demo App 源码与资源。
- `NEBaseUIKitOC/`：Objective-C 公共 UI 基础组件源码。
- `NEAdaptiveUIKitOC/`、`NEChatUIKitOC/`、`NEContactUIKitOC/`、`NEConversationUIKitOC/`、`NETeamUIKitOC/`、`NEAISearchKitOC/`：Objective-C IM UIKit 组件源码与 podspec。
- `NEMapKitOC/`：地图占位组件源码，默认不在 Demo 中集成。
- `PodConfigs/`：Pod 依赖与组件版本配置。
- `app.xcodeproj` / `app.xcworkspace`：Demo App 工程与工作区。

## 使用方式

```sh
pod install
open app.xcworkspace
```

默认使用本地 OC UIKit 组件源码。也可以通过 Podfile 注释切换为远端二进制依赖（官方 CocoaPods 上的 `10.9.30`）。

`Podfile` 中预留了云信 Specs 镜像；需要从云信源解析 OC UIKit 组件时，取消对应 `source` 行的注释（保留官方源以解析呼叫等仅发布在官方源的依赖），然后重新执行 `pod install`。

## 本地凭据

公开仓库不包含 AppKey、账号、Token、推送证书名或测试环境服务地址。首次运行前创建本地配置文件：

```sh
cp app/Main/AppKey.private.h.example app/Main/AppKey.private.h
```

在 `AppKey.private.h` 中填写自己项目的凭据。该文件已被 Git 忽略，不应提交。私有化环境请在应用的私有化配置页面填写自己的服务端配置。

## 验证

```sh
xcodebuild -workspace app.xcworkspace -scheme app -sdk iphonesimulator -configuration Debug build
```
