require_relative "config_podspec.rb"

# ---------- NIMSDK ----------
module NIMSDK
  def self.name
    "NIMSDK_LITE"
  end

  def self.version
    YXConfig.nimsdk_version
  end

  def self.FCS
    "#{NIMSDK.name}/FCS"
  end

  def self.FTS
    "#{NIMSDK.name}/FTS"
  end

  def self.QChat
    "#{NIMSDK.name}/QChat"
  end
end

# ---------- NERtcSDK ----------
module NERtcSDK
  def self.name
    "NERtcSDK"
  end

  def self.version
    "5.9.15"
  end

  def self.RtcBasic
    "#{NERtcSDK.name}/RtcBasic"
  end
end

# ---------- MJRefresh ----------
module MJRefresh
  def self.name
    "MJRefresh"
  end

  def self.version
    "3.7.5"
  end

  def self.install(pod)
    pod.pod MJRefresh.name, MJRefresh.version
  end
end

# ---------- Masonry ----------
module Masonry
  def self.name
    "Masonry"
  end

  def self.version
    "1.1.0"
  end
end

# ---------- SDWebImage ----------
module SDWebImage
  def self.name
    "SDWebImage"
  end

  def self.version
    "5.20.1"
  end

  def self.install(pod)
    pod.pod SDWebImage.name, SDWebImage.version
  end
end

# ---------- lottie-ios (OC 2.x) ----------
module LottieOC
  def self.name
    "lottie-ios"
  end

  def self.version
    "2.5.3"
  end

  def self.install(pod)
    pod.pod LottieOC.name, LottieOC.version
  end
end

# ---------- MBProgressHUD ----------
module MBProgressHUD
  def self.name
    "MBProgressHUD"
  end

  def self.version
    "1.2.0"
  end

  def self.install(pod)
    pod.pod MBProgressHUD.name, MBProgressHUD.version
  end
end

# ---------- IQKeyboardManager ----------
module IQKeyboardManager
  def self.name
    "IQKeyboardManager"
  end

  def self.version
    "7.0.3"
  end

  def self.install(pod)
    pod.pod IQKeyboardManager.name, IQKeyboardManager.version
  end
end

# ---------- YXAlog ----------
module YXAlog
  def self.name
    "YXAlog"
  end

  def self.version
    "1.0.11"
  end

  def self.install(pod)
    pod.pod YXAlog.name, YXAlog.version
  end
end
