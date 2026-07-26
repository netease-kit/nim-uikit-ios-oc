require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_local_common.rb"
require_relative "../../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = 'NEAISearchKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'AI Search module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NEAISearchKitOC/Classes/**/*'
  s.resource     = 'NEAISearchKitOC/Assets/**/*'

  s.dependency NEChatKit.name, NEChatKit.version
  s.dependency NECommonUIKitOC.name
  s.dependency 'NIMSDK_LITE', YXConfig.nimsdk_version

  YXConfig.pod_target_xcconfig(s)
end
