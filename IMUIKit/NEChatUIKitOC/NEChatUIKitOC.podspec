require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_local_common.rb"
require_relative "../../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = 'NEChatUIKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Chat UI module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source           = { :git => '', :tag => s.version.to_s }
  s.source_files     = 'NEChatUIKitOC/Classes/**/*'
  s.resource         = 'NEChatUIKitOC/Assets/**/*'
  s.exclude_files    = [
    'NEChatUIKitOC/Classes/**/*.rootbak',
    'NEChatUIKitOC/Classes/NormalUI/NormalChatRouter.m',
    'NEChatUIKitOC/Classes/Common/NSBundleExtension.h',
  ]
  s.public_header_files = Dir['NEChatUIKitOC/Classes/**/*.h'].reject do |path|
    path.end_with?('/Classes/Common/NSBundleExtension.h')
  end

  s.dependency NEChatKit.name, NEChatKit.version
  s.dependency NECommonUIKitOC.name
  s.dependency 'MJRefresh'
  s.dependency 'SDWebImage'
  s.dependency 'NIMSDK_LITE', YXConfig.nimsdk_version

  YXConfig.pod_target_xcconfig(s)
end
