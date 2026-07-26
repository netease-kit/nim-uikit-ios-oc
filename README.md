# NIM UIKit iOS OC Demo

网易云信 IM UIKit Objective-C Demo 工程，目录结构对齐 Swift 版 GitHub Demo：

- `app/`：Demo App 源码与资源。
- `Common/`：Objective-C 公共 UI 组件源码。
- `IMUIKit/`：Objective-C IM UIKit 组件源码。
- `PodConfigs/`：Pod 依赖与组件版本配置。
- `app.xcodeproj` / `app.xcworkspace`：Demo App 工程与工作区。

## 使用方式

```sh
pod install
open app.xcworkspace
```

默认使用公开 CocoaPods 依赖和本地 OC UIKit 组件源码。模拟器构建会排除 `arm64`，以兼容当前依赖中的 x86_64 simulator 二进制切片。

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
