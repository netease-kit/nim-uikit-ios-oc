require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_local_common.rb"
require_relative "../../PodConfigs/config_local_im.rb"
require_relative "../../PodConfigs/config_third.rb"

Pod::Spec.new do |s|
  s.name             = 'NETeamUIKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Team UI module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NETeamUIKitOC/Classes/**/*'
  s.resource     = 'NETeamUIKitOC/Assets/**/*'

  s.dependency NEChatUIKitOC.name
  s.dependency NEChatKitOC.name
  s.dependency NECommonUIKitOC.name
  s.dependency NIMSDK.name, NIMSDK.version

  YXConfig.pod_target_xcconfig(s)
end
