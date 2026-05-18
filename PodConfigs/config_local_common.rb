require_relative "config_podspec.rb"

# ---------- NECommonUIKitOC ----------
module NECommonUIKitOC
  def self.name
    "NECommonUIKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "Common/NECommonUIKitOC/NECommonUIKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NECommonUIKitOC.name, :path => NECommonUIKitOC.path
  end
end

# ---------- NECommonUIKit ----------
module NECommonUIKit
  def self.name
    "NECommonUIKit"
  end

  def self.version
    "9.8.2"
  end
end
