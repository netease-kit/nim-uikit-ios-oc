require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_third.rb"
require_relative "../../PodConfigs/config_local_common.rb"
require_relative "../../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = 'NEConversationUIKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Conversation UI module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NEConversationUIKitOC/Classes/**/*'
  s.resource     = 'NEConversationUIKitOC/Assets/**/*'

  s.dependency NEChatKitOC.name
  s.dependency NECommonUIKitOC.name
  s.dependency MJRefresh.name
  s.dependency SDWebImage.name
  s.dependency NIMSDK.name, NIMSDK.version

  YXConfig.pod_target_xcconfig(s)
end
