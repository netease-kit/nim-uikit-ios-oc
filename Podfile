# 配置内容详见：PodConfigs/config_podspec.rb
require_relative "PodConfigs/config_podspec.rb"

platform :ios, YXConfig.deployment_target
source 'https://github.com/CocoaPods/Specs.git'
# 云信 Specs 镜像：需要从云信源解析 OC UIKit 组件时，取消注释并保留官方源
# source 'https://gitee.com/netease-im/Specs.git'

target 'IMUIKitOCExample' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # UI 组件（远端二进制依赖，与下方本地源码依赖二选一）
#  pod 'NEBaseUIKitOC', YXConfig.imuikit_version           # 公共 UI 基础组件
#  pod 'NEAdaptiveUIKitOC', YXConfig.imuikit_version       # 自适应呈现组件（折叠屏双栏）
#  pod 'NEChatUIKitOC', YXConfig.imuikit_version           # 会话（聊天）组件
#  pod 'NEContactUIKitOC', YXConfig.imuikit_version        # 通讯录组件
#  pod 'NEConversationUIKitOC', YXConfig.imuikit_version   # 会话列表组件
#  pod 'NETeamUIKitOC', YXConfig.imuikit_version           # 群相关设置组件
#  pod 'NEAISearchKitOC', YXConfig.imuikit_version         # AI 划词搜索组件

  # 扩展库 - 呼叫组件
  pod 'NERtcSDK/RtcBasic'             # RTC 音视频基础组件
  pod 'NERtcSDK/Nenn'                 # RTC 音视频神经网络组件（使用背景虚化功能需要集成）
  pod 'NERtcSDK/Segment'              # RTC 音视频背景分割组件（使用背景虚化功能需要集成）
  pod 'NERtcCallKit/NOS_Special', YXConfig.calluikit_version
  pod 'NERtcCallUIKit/NOS_Special', YXConfig.calluikit_version # (源码地址：https://github.com/netease-kit/NEVideoCall-1to1/tree/main/NLiteAVDemo-iOS-ObjC/CallKit)

  # 可选 - 图片选择库
  pod 'ZLPhotoBrowser', '4.7.4'

  # 如果需要查看 UI 组件源码，保留以下本地依赖；使用远端二进制时注释掉
  pod 'NEBaseUIKitOC', :path => 'NEBaseUIKitOC/NEBaseUIKitOC.podspec'
  pod 'NEAdaptiveUIKitOC', :path => 'NEAdaptiveUIKitOC/NEAdaptiveUIKitOC.podspec'
  pod 'NEChatUIKitOC', :path => 'NEChatUIKitOC/NEChatUIKitOC.podspec'
  pod 'NEContactUIKitOC', :path => 'NEContactUIKitOC/NEContactUIKitOC.podspec'
  pod 'NEConversationUIKitOC', :path => 'NEConversationUIKitOC/NEConversationUIKitOC.podspec'
  pod 'NETeamUIKitOC', :path => 'NETeamUIKitOC/NETeamUIKitOC.podspec'
  pod 'NEAISearchKitOC', :path => 'NEAISearchKitOC/NEAISearchKitOC.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['CLANG_ENABLE_EXPLICIT_MODULES'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = YXConfig.deployment_target
    end
  end
end
