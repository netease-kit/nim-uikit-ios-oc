require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = NEChatUIKitOC.name
  s.version          = NEChatUIKitOC.version
  s.summary          = 'Chat UI module (OC version).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source           = { :git => "https://github.com/netease-kit/" }
  s.source_files     = 'NEChatUIKitOC/Classes/**/*'
  s.resource         = 'NEChatUIKitOC/Assets/**/*'
  s.exclude_files    = [
    'NEChatUIKitOC/Classes/**/*.rootbak',
    'NEChatUIKitOC/Classes/NormalUI/NormalChatRouter.m',
    'NEChatUIKitOC/Classes/Common/NSBundleExtension.h',
  ]
  s.dependency NEChatKit.name, NEChatKit.version
  s.dependency NEBaseUIKitOC.name, NEBaseUIKitOC.version
  s.dependency 'MJRefresh', '3.7.5'
  s.dependency 'SDWebImage', '5.20.1'
  s.dependency 'SDWebImageWebPCoder'
  s.dependency 'SDWebImageSVGKitPlugin'
  s.dependency 'NIMSDK_LITE', YXConfig.nimsdk_version

  YXConfig.oc_pod_target_xcconfig(s)
end
