# 配置内容详见：PodConfigs/config_podspec.rb
require_relative "PodConfigs/config_podspec.rb"

# Uncomment the next line to define a global platform for your project
platform :ios, YXConfig.deployment_target
source 'https://github.com/CocoaPods/Specs.git'

target 'app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
#  pod 'NIMSDK_LITE', '10.9.81'
  pod 'NEChatKit', YXConfig.imuikit_version
  # UI 组件
  pod 'NEChatUIKitOC', YXConfig.imuikit_version						# 会话（聊天）组件
  pod 'NEContactUIKitOC', YXConfig.imuikit_version				# 通讯录组件
  pod 'NEConversationUIKitOC', YXConfig.imuikit_version		# 会话列表组件
  pod 'NETeamUIKitOC', YXConfig.imuikit_version						 # 群相关设置组件
  
  # 扩展库 - 地理位置组件
  pod 'NEMapKitOC', YXConfig.imuikit_version
  
  # 扩展库 - AI 划词搜索
  pod 'NEAISearchKitOC', YXConfig.imuikit_version
  
  # 扩展库 - 呼叫组件
  pod 'NERtcSDK/RtcBasic'       # RTC 音视频基础组件
  pod 'NERtcSDK/Nenn'           # RTC 音视频神经网络组件（使用背景虚化功能需要集成）
  pod 'NERtcSDK/Segment'        # RTC 音视频背景分割组件（使用背景虚化功能需要集成）
  pod 'NERtcCallKit/NOS_Special', YXConfig.calluikit_version
  pod 'NERtcCallUIKit/NOS_Special', YXConfig.calluikit_version # (源码地址：https://github.com/netease-kit/NEVideoCall-1to1/tree/main/NLiteAVDemo-iOS-ObjC/CallKit)

  # 可选 - 图片选择库
  pod 'ZLPhotoBrowser'

  # 如果需要查看UI部分源码请注释掉以上在线依赖(不包含呼叫组件)，打开下面的本地依赖
#  pod 'NECommonUIKitOC', :path => 'Common/NECommonUIKitOC/NECommonUIKitOC.podspec'
#  pod 'NEChatUIKitOC', :path => 'IMUIKit/NEChatUIKitOC/NEChatUIKitOC.podspec'
#  pod 'NEContactUIKitOC', :path => 'IMUIKit/NEContactUIKitOC/NEContactUIKitOC.podspec'
#  pod 'NEConversationUIKitOC', :path => 'IMUIKit/NEConversationUIKitOC/NEConversationUIKitOC.podspec'
#  pod 'NETeamUIKitOC', :path => 'IMUIKit/NETeamUIKitOC/NETeamUIKitOC.podspec'
#  pod 'NEMapKitOC', :path => 'IMUIKit/NEMapKitOC/NEMapKitOC.podspec'
#  pod 'NEAISearchKitOC', :path => 'IMUIKit/NEAISearchKitOC/NEAISearchKitOC.podspec'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['CLANG_ENABLE_EXPLICIT_MODULES'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = YXConfig.deployment_target

      # Apple 芯片模拟器运行打开以下代码
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
