require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = NEMapKitOC.name
  s.version          = NEMapKitOC.version
  s.summary          = 'Map module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEMapKitOC/Classes/**/*'

  s.dependency NEChatUIKitOC.name, NEChatUIKitOC.version

  YXConfig.oc_pod_target_xcconfig(s)
end
