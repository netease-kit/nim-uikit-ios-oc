require_relative "../PodConfigs/config_podspec.rb"
require_relative "../PodConfigs/config_third.rb"
require_relative "../PodConfigs/config_local_common.rb"
require_relative "../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = NEBaseUIKitOC.name
  s.version          = NEBaseUIKitOC.version
  s.summary          = 'NIM UIKit common UI base components (Objective-C).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => "https://github.com/netease-kit/" }
  s.source_files = 'NEBaseUIKitOC/Classes/**/*.{h,m}'
  s.exclude_files = [
    'NEBaseUIKitOC/Classes/Core/Extension/Constant.h',
    'NEBaseUIKitOC/Classes/Base/BaseViewController/NEBaseTableViewController.h',
    'NEBaseUIKitOC/Classes/Base/BaseViewController/NEBaseViewController.h',
    'NEBaseUIKitOC/Classes/CommonView/NEEmptyDataView.h',
    'NEBaseUIKitOC/Classes/CommonViewController/NENavigationController.h',
  ]
  s.private_header_files = 'NEBaseUIKitOC/Classes/Vender/KeyboardManager/Categories/**/*.h'

  s.resource     = 'NEBaseUIKitOC/Assets/**/*'

  s.dependency NEChatKit.name, NEChatKit.version
  s.dependency SDWebImage.name, SDWebImage.version
  s.dependency LottieOC.name, LottieOC.version

  YXConfig.oc_pod_target_xcconfig(s, "HEADER_SEARCH_PATHS" => '$(inherited) "${PODS_TARGET_SRCROOT}/NEBaseUIKitOC/Classes/Vender/Toast"')
end
