require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_local_common.rb"

Pod::Spec.new do |s|
  s.name             = NEAdaptiveUIKitOC.name
  s.version          = NEAdaptiveUIKitOC.version
  s.summary          = 'NIM UIKit foldable / adaptive shell (Objective-C).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEAdaptiveUIKitOC/Classes/**/*.{h,m}'
  # 内部实现头文件（rail 页面解析、动作转发工具）不对外暴露。
  s.private_header_files = [
    'NEAdaptiveUIKitOC/Classes/NEAdaptiveRailPageNavigation.h',
    'NEAdaptiveUIKitOC/Classes/NEAdaptiveRailActionSupport.h',
    'NEAdaptiveUIKitOC/Classes/NEAdaptiveUIKitOCInternals.h'
  ]

  YXConfig.oc_pod_target_xcconfig(s)
end
