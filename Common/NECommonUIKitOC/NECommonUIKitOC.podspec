require_relative "../../PodConfigs/config_podspec.rb"
require_relative "../../PodConfigs/config_third.rb"
require_relative "../../PodConfigs/config_local_common.rb"
require_relative "../../PodConfigs/config_local_im.rb"

Pod::Spec.new do |s|
  s.name             = 'NECommonUIKitOC'
  s.version          = YXConfig.imuikit_version
  s.summary          = 'NIM UIKit common UI base components (Objective-C).'
  s.homepage         = YXConfig.homepage
  s.license          = YXConfig.license
  s.author           = YXConfig.author
  s.ios.deployment_target = YXConfig.deployment_target

  s.source       = { :git => '', :tag => s.version.to_s }
  s.source_files = 'NECommonUIKitOC/Classes/**/*.{h,m}'
  s.exclude_files = [
    'NECommonUIKitOC/Classes/Core/Extension/Constant.h',
    'NECommonUIKitOC/Classes/Base/BaseViewController/NEBaseTableViewController.h',
    'NECommonUIKitOC/Classes/Base/BaseViewController/NEBaseViewController.h',
    'NECommonUIKitOC/Classes/CommonView/NEEmptyDataView.h',
    'NECommonUIKitOC/Classes/CommonViewController/NENavigationController.h',
  ]
  s.public_header_files = Dir['NECommonUIKitOC/Classes/**/*.h'].reject do |path|
    path.include?('/Vender/KeyboardManager/Categories/') ||
    path.end_with?('/Classes/Core/Extension/Constant.h') ||
    path.end_with?('/Classes/Base/BaseViewController/NEBaseTableViewController.h') ||
    path.end_with?('/Classes/Base/BaseViewController/NEBaseViewController.h') ||
    path.end_with?('/Classes/CommonView/NEEmptyDataView.h') ||
    path.end_with?('/Classes/CommonViewController/NENavigationController.h')
  end
  s.resource     = 'NECommonUIKitOC/Assets/**/*'

  s.dependency NEChatKitOC.name
  s.dependency SDWebImage.name, SDWebImage.version
  s.dependency LottieOC.name, LottieOC.version

  s.frameworks = 'UIKit', 'Foundation'

  YXConfig.pod_target_xcconfig(s)
end
