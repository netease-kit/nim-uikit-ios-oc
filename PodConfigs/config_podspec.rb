module YXConfig
  def self.imuikit_version
    "10.9.21"
  end

  def self.nimsdk_version
    "10.9.81"
  end

  def self.calluikit_version
    "4.3.0"
  end

  def self.deployment_target
    "13.0"
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
      "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "",
      "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
      "APPLICATION_EXTENSION_API_ONLY" => "NO",
      "DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym",
      "CLANG_ENABLE_EXPLICIT_MODULES" => "NO"
    }
  end

  def self.license
    { :'type' => "Copyright", :'text' => " Copyright 2022 Netease " }
  end
end
