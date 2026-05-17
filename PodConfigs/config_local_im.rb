require_relative "config_podspec.rb"

# ---------- NEChatKitOC ----------
module NEChatKitOC
  def self.name
    "NEChatKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.NOS
    "#{NEChatKitOC.name}/NOS"
  end

  def self.FCS
    "#{NEChatKitOC.name}/FCS"
  end

  def self.NOS_Special
    "#{NEChatKitOC.name}/NOS_Special"
  end

  def self.FCS_Special
    "#{NEChatKitOC.name}/FCS_Special"
  end

  def self.install(pod)
    pod.pod NEChatKitOC.name, NEChatKitOC.version
  end
end

# ---------- NEChatUIKitOC ----------
module NEChatUIKitOC
  def self.name
    "NEChatUIKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NEChatUIKitOC/NEChatUIKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NEChatUIKitOC.name, :path => NEChatUIKitOC.path
  end
end

# ---------- NEConversationUIKitOC ----------
module NEConversationUIKitOC
  def self.name
    "NEConversationUIKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NEConversationUIKitOC/NEConversationUIKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NEConversationUIKitOC.name, :path => NEConversationUIKitOC.path
  end
end

# ---------- NEContactUIKitOC ----------
module NEContactUIKitOC
  def self.name
    "NEContactUIKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NEContactUIKitOC/NEContactUIKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NEContactUIKitOC.name, :path => NEContactUIKitOC.path
  end
end

# ---------- NETeamUIKitOC ----------
module NETeamUIKitOC
  def self.name
    "NETeamUIKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NETeamUIKitOC/NETeamUIKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NETeamUIKitOC.name, :path => NETeamUIKitOC.path
  end
end

# ---------- NEMapKitOC ----------
module NEMapKitOC
  def self.name
    "NEMapKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NEMapKitOC/NEMapKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NEMapKitOC.name, :path => NEMapKitOC.path
  end
end

# ---------- NEAISearchKitOC ----------
module NEAISearchKitOC
  def self.name
    "NEAISearchKitOC"
  end

  def self.version
    YXConfig.imuikit_version
  end

  def self.path
    "IMUIKit/NEAISearchKitOC/NEAISearchKitOC.podspec"
  end

  def self.install(pod)
    pod.pod NEAISearchKitOC.name, :path => NEAISearchKitOC.path
  end
end
