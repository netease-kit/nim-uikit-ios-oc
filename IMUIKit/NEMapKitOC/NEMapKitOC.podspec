require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_third.rb"
require_relative "../../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = 'NEMapKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'Map module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NEMapKitOC/Classes/**/*'

  s.dependency NEChatUIKitOC.name

  YXConfig.pod_target_xcconfig(s)
end
