require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = NEConversationUIKitOC.name
  s.version          = NEConversationUIKitOC.version
  s.summary          = 'Conversation UI module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEConversationUIKitOC/Classes/**/*'
  s.resource     = 'NEConversationUIKitOC/Assets/**/*'

  s.dependency NEChatKit.name, NEChatKit.version
  s.dependency NEBaseUIKitOC.name, NEBaseUIKitOC.version
  s.dependency 'MJRefresh', '3.7.5'
  s.dependency 'SDWebImage', '5.20.1'
  s.dependency 'NIMSDK_LITE', YXConfig.nimsdk_version

  YXConfig.oc_pod_target_xcconfig(s)
end
