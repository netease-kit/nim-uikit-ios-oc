module YXConfig
  def self.imuikit_version
    "10.9.30"
  end

  # Objective-C UIKit 组件独立版本号（与 NEChatKit 的版本解耦）。
  def self.oc_uikit_version
    "10.9.30"
  end

  # NEChatKit 与 OC UIKit 10.9.30 配套发布，同时提供 ObjC 侧需要的修复。
  def self.chatkit_version
    "10.9.76"
  end

  def self.nimsdk_version
    "10.11.5"
  end

  def self.calluikit_version
    "4.8.8"
  end

  def self.deployment_target
    "15.0"
  end

  def self.swift_version
    "5.0"
  end

  def self.homepage
    "http://netease.im"
  end

  def self.author
    "yunxin engineering department"
  end

  def self.pod_target_xcconfig(s)
    s.pod_target_xcconfig = {
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "APPLICATION_EXTENSION_API_ONLY" => "NO",
      "DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym",
      "CLANG_ENABLE_EXPLICIT_MODULES" => "NO"
    }
  end

  # OC 组件共用的 Pod 构建设置（与 Swift 组件的 pod_target_xcconfig 区分）。
  def self.oc_pod_target_xcconfig(s, extra = {})
    s.pod_target_xcconfig = {
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "APPLICATION_EXTENSION_API_ONLY" => "NO",
      "DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym",
      "CLANG_ENABLE_EXPLICIT_MODULES" => "NO",
      "DEFINES_MODULE" => "YES"
    }.merge(extra)
  end

  def self.license
    { :'type' => "Copyright", :'text' => " Copyright 2022 Netease " }
  end
end
