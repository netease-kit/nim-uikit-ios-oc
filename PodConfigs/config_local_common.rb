require_relative "config_podspec.rb"

# ---------- NEBaseUIKitOC ----------
# 开源仓把内部的 NEBaseUIKitOC 以 NEBaseUIKitOC 名称提供源码，
# 避免与 CocoaPods 上已发布的二进制 NEBaseUIKitOC 冲突。
module NEBaseUIKitOC
  def self.name
    "NEBaseUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEBaseUIKitOC/NEBaseUIKitOC.podspec"
  end
end

# ---------- NEAdaptiveUIKitOC ----------
module NEAdaptiveUIKitOC
  def self.name
    "NEAdaptiveUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEAdaptiveUIKitOC/NEAdaptiveUIKitOC.podspec"
  end
end
