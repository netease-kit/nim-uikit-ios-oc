require_relative "config_podspec.rb"

# ---------- NEChatKit ----------
# NEChatKit 是闭源二进制依赖，始终从远端 Pod 源解析（与 OC UIKit 10.9.31 配套）。
module NEChatKit
  def self.name
    "NEChatKit"
  end

  def self.version
    YXConfig.chatkit_version
  end
end

# ---------- NEChatUIKitOC ----------
module NEChatUIKitOC
  def self.name
    "NEChatUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEChatUIKitOC/NEChatUIKitOC.podspec"
  end
end

# ---------- NEConversationUIKitOC ----------
module NEConversationUIKitOC
  def self.name
    "NEConversationUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEConversationUIKitOC/NEConversationUIKitOC.podspec"
  end
end

# ---------- NEContactUIKitOC ----------
module NEContactUIKitOC
  def self.name
    "NEContactUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEContactUIKitOC/NEContactUIKitOC.podspec"
  end
end

# ---------- NETeamUIKitOC ----------
module NETeamUIKitOC
  def self.name
    "NETeamUIKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NETeamUIKitOC/NETeamUIKitOC.podspec"
  end
end

# ---------- NEMapKitOC ----------
module NEMapKitOC
  def self.name
    "NEMapKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEMapKitOC/NEMapKitOC.podspec"
  end
end

# ---------- NEAISearchKitOC ----------
module NEAISearchKitOC
  def self.name
    "NEAISearchKitOC"
  end

  def self.version
    YXConfig.oc_uikit_version
  end

  def self.path
    "NEAISearchKitOC/NEAISearchKitOC.podspec"
  end
end
