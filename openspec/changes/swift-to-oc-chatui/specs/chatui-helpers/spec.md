# ChatUI Helpers — Swift-to-OC Conversion Spec

> Source: `NEChatUIKit/Classes/Chat/Helper/*.swift`

---

## ADDED Requirements

### Requirement: ChatMessageHelper

ChatMessageHelper is an `@objcMembers public class` with all static/class methods providing message model construction, UI cell registration, content extraction, reply/revoke handling, at-mention parsing, file utilities, and user cache lookups.

#### Scenario: getSizeWithMaxSize image sizing
- **WHEN** `getSizeWithMaxSize:size:miniWH:` is called with a max size, original image size, and minimum dimension
- **THEN** the image is scaled proportionally (wider images scale by width, taller images scale by height), clamped to the minimum dimension, and the resulting CGSize is returned

#### Scenario: getSessionName
- **WHEN** `getSessionName(conversationId:showAlias:)` is called
- **THEN** for P2P conversations, user info is fetched from cache and `showName` is returned; for team conversations, the team name from `NETeamUserManager` is returned

#### Scenario: getChatCellRegisterDic
- **WHEN** `getChatCellRegisterDic(isFun:)` is called
- **THEN** a dictionary mapping `MessageType.rawValue` strings to UITableViewCell subclasses is returned, selecting Normal or Fun skin variants for text, aiStreamText, rtcCallRecord, audio, image, revoke, video, file, location, time/tip, multiForward, and richText types

#### Scenario: getPinCellRegisterDic / getCollectionCellRegisterDic
- **WHEN** the pin or collection cell register dictionaries are requested
- **THEN** similar dictionaries are returned mapping message types to `NEBasePinMessageCell` or `NEBaseCollectionMessageCell` subclasses

#### Scenario: modelFromMessage (sync)
- **WHEN** `modelFromMessage(message:)` is called
- **THEN** the message type is matched to create the appropriate MessageModel subclass:
  - `.MESSAGE_TYPE_VIDEO` → `MessageVideoModel`
  - `.MESSAGE_TYPE_TEXT` → `MessageAIStreamModel` (if AI response or robot) or `MessageTextModel`
  - `.MESSAGE_TYPE_IMAGE` → `MessageImageModel`
  - `.MESSAGE_TYPE_AUDIO` → `MessageAudioModel`
  - `.MESSAGE_TYPE_NOTIFICATION`, `.MESSAGE_TYPE_TIP` → `MessageTipsModel`
  - `.MESSAGE_TYPE_FILE` → `MessageFileModel`
  - `.MESSAGE_TYPE_LOCATION` → `MessageLocationModel`
  - `.MESSAGE_TYPE_CALL` → `MessageCallRecordModel`
  - `.MESSAGE_TYPE_CUSTOM` → `MessageCustomModel` (multiForward), `MessageRichTextModel` (richText), registered custom type, or fallthrough to unknown
  - Default → `MessageTextModel` with `msg_unknown` text and `unkonwMessage = true`

#### Scenario: modelFromMessage (async with completion)
- **WHEN** `modelFromMessage(message:completion:)` is called
- **THEN** same logic as sync, but notification messages first load target user info via `NETeamUserManager` before calling the completion

#### Scenario: contentOfMessage
- **WHEN** `contentOfMessage:` is called
- **THEN** a localized display string is returned based on message type (text content, `[图片]`, `[语音]`, `[视频]`, `[文件]`, `[位置]`, call type, rich-text content, `[聊天记录]`, `[自定义]`, or `[未知]`)

#### Scenario: getAIErrorMessage mapping
- **WHEN** `getAIErrorMsage:` is called with an error code
- **THEN** the code is mapped to a localized error string (parameter error, rate limit, user not exist, user banned, no friend, antispam hit, team member errors, AI account errors)

#### Scenario: clearForwardAtMark
- **WHEN** `clearForwardAtMark:` is called on a forwarded message
- **THEN** `yxAtMsg` and `keyReplyMsgKey` are removed from the message's `serverExtension`

#### Scenario: buildHeader / buildBody for merge-forward
- **WHEN** `buildHeader(messageCount:)` is called
- **THEN** a JSON string with version, terminal (2=iOS), and message_count is returned
- **WHEN** `buildBody(messages:completion:)` is called
- **THEN** each message is serialized (with at/reply cleared, nick/avatar injected), joined by newlines, and abstracts (first 3 messages' senderNick+content) are collected

#### Scenario: getMessageServerExtension
- **WHEN** `getMessageServerExtension(message:)` is called
- **THEN** the message's `serverExtension` JSON string is parsed into a `[String: Any]` dictionary

#### Scenario: isRevokeMessage
- **WHEN** `isRevokeMessage(message:)` is called
- **THEN** the server extension is checked for `revokeLocalMessage == true`

#### Scenario: getRevokeMessageContent
- **WHEN** `getRevokeMessageContent(model:)` is called for a text or richText message
- **THEN** the revoke time and content are extracted from server extension for re-edit support

#### Scenario: createReplyDic / createMessageRefer / getReplyDictionary
- **WHEN** reply metadata is needed
- **THEN** `createReplyDic` builds a dictionary from a V2NIMMessageRefer with idClient, scene, from, receiverId, to, idServer, time
- **THEN** `createMessageRefer` creates a V2NIMMessageRefer from that dictionary
- **THEN** `getReplyDictionary` extracts the reply dictionary from `serverExtension[keyReplyMsgKey]`

#### Scenario: isAISender
- **WHEN** `isAISender:` is called
- **THEN** returns true if the message's `aiConfig.aiStatus == .MESSAGE_AI_STATUS_RESPONSE`

#### Scenario: getSenderId
- **WHEN** `getSenderId:` is called
- **THEN** for AI response messages (`enableAIUser && aiStatus == RESPONSE`), the AI accountId is returned; otherwise the message's senderId

#### Scenario: isSelf
- **WHEN** `isSelf(message:)` is called
- **THEN** compares `getSenderId(message)` with `IMKitClient.instance.account()`

#### Scenario: getUserFromCache
- **WHEN** `getUserFromCache:` is called with an accountId
- **THEN** it checks in order: `NEAIUserManager` → `NEFriendUserCache` → `NEP2PChatUserCache` → `NETeamUserManager.getUserInfo`, returning the first non-nil result

#### Scenario: addTimeMessage
- **WHEN** `addTimeMessage:lastModel:` is called
- **THEN** if the time gap between the current and last message exceeds 5 minutes, a formatted time string is set on the model's `timeContent`

#### Scenario: loadAtInMessage
- **WHEN** `loadAtInMessage:attributeStr:` is called
- **THEN** at-mention segments from `serverExtension[yxAtMsg]` are parsed, emoji offsets are calculated, and the corresponding ranges in the attributed string are highlighted with `ne_normalTheme` color

#### Scenario: loadKeywordInMessage
- **WHEN** `loadKeywordInMessage:attributeStr:keyword:themeColor:` is called
- **THEN** the keyword is searched via regex, emoji offsets are applied, and matching ranges are highlighted with the theme color

#### Scenario: getFileChecksum
- **WHEN** `getFileChecksum(fileURL:)` is called
- **THEN** the file is read in 1024-byte chunks, MD5 is computed via CommonCrypto, and the hex string is returned

#### Scenario: createFilePath
- **WHEN** `createFilePath:` is called
- **THEN** a local file path is constructed under `imkitDir` with subdirectory based on message type (audio/image/video/file) and filename from messageClientId + extension

#### Scenario: getUrls for image browser
- **WHEN** `getUrls:messages:` is called
- **THEN** all image message URLs (or local paths) are collected and the current message's index is returned

---

### Requirement: MessageUtils

MessageUtils is an `@objcMembers open class` providing static factory methods for creating V2NIMMessage objects.

#### Scenario: textMessage(text:remoteExt:)
- **WHEN** called with text and optional remote extension
- **THEN** `V2NIMMessageCreator.createTextMessage` is called; if remoteExt is non-nil, it is serialized to `serverExtension`

#### Scenario: textMessage(text:)
- **WHEN** called with text only
- **THEN** `V2NIMMessageCreator.createTextMessage` is called

#### Scenario: forwardMessage(message:)
- **WHEN** called with a source message
- **THEN** `V2NIMMessageCreator.createForwardMessage` is called

#### Scenario: imageMessage(path:name:sceneName:width:height:)
- **WHEN** called with image parameters
- **THEN** `V2NIMMessageCreator.createImageMessage` is called with the default scene name if nil

#### Scenario: audioMessage(filePath:name:sceneName:duration:)
- **WHEN** called with audio parameters
- **THEN** `V2NIMMessageCreator.createAudioMessage` is called

#### Scenario: videoMessage(filePath:name:sceneName:width:height:duration:)
- **WHEN** called with video parameters
- **THEN** `V2NIMMessageCreator.createVideoMessage` is called

#### Scenario: locationMessage(lat:lng:address:)
- **WHEN** called with location parameters
- **THEN** `V2NIMMessageCreator.createLocationMessage` is called

#### Scenario: fileMessage(filePath:displayName:sceneName:)
- **WHEN** called with file parameters
- **THEN** `V2NIMMessageCreator.createFileMessage` is called

#### Scenario: customMessage(text:rawAttachment:)
- **WHEN** called with text and raw attachment JSON
- **THEN** `V2NIMMessageCreator.createCustomMessage` is called

#### Scenario: tipMessage(text:)
- **WHEN** called with tip text
- **THEN** `V2NIMMessageCreator.createTipsMessage` is called

---

### Requirement: NETeamUserManager

NETeamUserManager is an `@objcMembers public class` singleton managing team member cache, non-friend user info cache, and team info for the current team chat. It implements `NETeamListener`, `NEContactListener`, and `NEIMKitClientListener`.

#### Scenario: Singleton with listeners
- **WHEN** `NETeamUserManager.shared` is accessed
- **THEN** it registers as login, team, and contact listener

#### Scenario: addListener / removeListener
- **WHEN** a `NETeamChatUserCacheListener` is added or removed
- **THEN** it is managed via a `MultiDelegate` container with weak references

#### Scenario: loadData(teamId:)
- **WHEN** `loadData:` is called
- **THEN** all previous cache is cleared, team info is fetched, own team member info is fetched, and all team members are loaded in background with 2000-per-page pagination

#### Scenario: updateTeamInfo / updateTeamMemberInfo / updateUserInfo
- **WHEN** team info, member info, or user info is updated
- **THEN** the cache is updated and all listeners are notified via `onTeamInfoUpdate` or `onTeamMemberUpdate`

#### Scenario: getTeamInfo / getTeamMemberInfo / getUserInfo
- **WHEN** cache accessors are called
- **THEN** the cached V2NIMTeam, V2NIMTeamMember, or NEUserWithFriend is returned

#### Scenario: isCurrentMember / isOwner
- **WHEN** membership or ownership is checked
- **THEN** the team member cache or team's ownerAccountId is consulted

#### Scenario: getAllTeamMembers / getAllTeamMemberModels
- **WHEN** all members are requested and `haveLoadAllMembers` is true
- **THEN** the full member list is returned; `getAllTeamMemberModels` builds `NETeamMemberInfoModel` objects with friend cache snapshot for performance

#### Scenario: getShowName (team context)
- **WHEN** `getShowName:showAlias:` is called
- **THEN** resolution order is: AI user name → non-friend cache → friend cache → team member nick → friend alias; the first non-empty value wins

#### Scenario: getTeamMembers batch load
- **WHEN** `getTeamMembers:notify:completion:` is called
- **THEN** missing user info is fetched from cloud (chunked at 150), missing team member info is fetched by IDs, and completion is called on main queue

#### Scenario: getAllTeamMemberWithMaxLimit recursive pagination
- **WHEN** `getAllTeamMemberWithMaxLimit` is called
- **THEN** team members are fetched with limit=2000, and if not finished, the method recurses with the next token

#### Scenario: NETeamListener callbacks
- **WHEN** team info, member join, member info update, member leave, or member kick events fire
- **THEN** the cache is updated/removed and listeners are notified

#### Scenario: NEContactListener callbacks
- **WHEN** friend info changes (add/delete/update)
- **THEN** if the friend is deleted and is a team member, info is moved to userInfoCache; otherwise the cache is updated

#### Scenario: removeAllTeamInfo
- **WHEN** called
- **THEN** tid, currentTeam, userInfoCache, teamMemberCache, and haveLoadAllMembers are all reset

---

### Requirement: NETeamChatUserCacheListener Protocol

NETeamChatUserCacheListener extends NETeamListener with optional callbacks for team info update and team member update (by accountId).

#### Scenario: onTeamInfoUpdate
- **WHEN** team info changes
- **THEN** `onTeamInfoUpdate:` is called with the teamId

#### Scenario: onTeamMemberUpdate
- **WHEN** a team member's info changes
- **THEN** `onTeamMemberUpdate:` is called with the accountId

---

### Requirement: NEP2PChatUserCache

NEP2PChatUserCache is a singleton managing non-friend user info for P2P chat contexts. It implements `NEContactListener`.

#### Scenario: Singleton with contact listener
- **WHEN** `NEP2PChatUserCache.shared` is accessed
- **THEN** it registers as a contact listener

#### Scenario: addListener / removeListener
- **WHEN** a `NEP2PChatUserCacheListener` is added or removed
- **THEN** it is managed via `MultiDelegate` with weak references

#### Scenario: updateUserInfo (V2NIMUser)
- **WHEN** `updateUserInfo:` is called with a V2NIMUser
- **THEN** the user's entry in `noUserCache` is updated and listeners are notified via `onUserInfoUpdate:`

#### Scenario: updateUserInfo (NEUserWithFriend)
- **WHEN** `updateUserInfo:` is called with a NEUserWithFriend
- **THEN** the entry is replaced in `noUserCache` (no notification)

#### Scenario: getUserInfo / removeUserInfo / removeAllUserInfo
- **WHEN** cache accessors or removal methods are called
- **THEN** the `noUserCache` dictionary is accessed or modified accordingly

#### Scenario: getShowName
- **WHEN** `getShowName:showAlias:` is called
- **THEN** the cached user's `showName` is returned, falling back to the userId string

#### Scenario: onUserProfileChanged (NEContactListener)
- **WHEN** user profiles change
- **THEN** if the user exists in `noUserCache`, their info is updated

---

### Requirement: NEP2PChatUserCacheListener Protocol

A protocol with one optional method for non-friend P2P user info cache updates.

#### Scenario: onUserInfoUpdate
- **WHEN** a non-friend user's info is updated
- **THEN** `onUserInfoUpdate:` is called with the accountId

---

### Requirement: ChatDeduplicationHelper

ChatDeduplicationHelper is a singleton preventing duplicate message sends, blacklist tips, audio sends, and revoke saves.

#### Scenario: Singleton with login listener
- **WHEN** `ChatDeduplicationHelper.instance` is accessed
- **THEN** it registers as `NEIMKitClientListener` and clears caches on logout/kick

#### Scenario: isMessageSended
- **WHEN** `isMessageSended(messageId:)` is called
- **THEN** returns true if the messageId is already in `sendingMessageIds` set; otherwise inserts it; the set is cleared when it exceeds `limit (100)`

#### Scenario: isBlackTipSended
- **WHEN** `isBlackTipSended(messageId:)` is called
- **THEN** returns true if the messageId is in `blackListMessageIds`; otherwise inserts it

#### Scenario: removeBlackTipSendedId
- **WHEN** `removeBlackTipSendedId(messageId:)` is called
- **THEN** the messageId is removed from `blackListMessageIds`

#### Scenario: isRecordAudioSended
- **WHEN** `isRecordAudioSended(path:)` is called
- **THEN** returns true if the path is in `recordAudioMessagePaths`; set is cleared at limit

#### Scenario: isRevokeMessageSaved
- **WHEN** `isRevokeMessageSaved(messageId:)` is called
- **THEN** returns true if already saved; otherwise inserts it; set clears at limit

#### Scenario: clearCache on logout/kick
- **WHEN** `onLoginStatus(.logout)` or `onKickedOffline` fires
- **THEN** all deduplication sets are cleared

---

### Requirement: NotificationMessageUtils

NotificationMessageUtils is an `@objcMembers open class` providing static methods for formatting team notification messages into display text.

#### Scenario: textForNotification
- **WHEN** `textForNotification(message:)` is called with a notification message
- **THEN** if it has a V2NIMMessageNotificationAttachment, `textForTeamNotificationMessage` is called; otherwise sender name + text is returned

#### Scenario: isDiscussSeniorTeamNoti
- **WHEN** `isDiscussSeniorTeamNoti(message:)` is called
- **THEN** returns true if the message attachment is V2NIMMessageNotificationAttachment

#### Scenario: isTeamLeaveOrDismiss
- **WHEN** `isTeamLeaveOrDismiss(message:)` is called
- **THEN** returns a tuple `(isLeave, isDismiss)` based on the notification type

#### Scenario: textForTeamNotificationMessage
- **WHEN** called with a team notification
- **THEN** the notification type is matched to produce localized text for: invite, dismiss, kick, update team info, leave, apply pass, owner transfer, add/remove manager, invite accept, ban member

#### Scenario: textOfUpdateTeam
- **WHEN** the notification type is `TEAM_UPDATE_TINFO`
- **THEN** specific updated fields are checked in order: name, intro, announcement, avatar, joinMode, agreeMode, inviteMode, updateInfoMode, chatBannedMode, serverExtension (at-all permission, top-message permission, top-message operation), updateExtensionMode

#### Scenario: fromName / toName / teamName / teamType
- **WHEN** these helper methods are called
- **THEN** `fromName` returns "You" for self or quoted display name; `toName` returns an array of quoted names; `teamName` returns the team type string; `teamType` returns `.advanceTeam` or `.discussTeam`

---

### Requirement: ReplyMessageUtil

ReplyMessageUtil provides a static method for formatting reply preview text.

#### Scenario: textForReplyModel
- **WHEN** `textForReplyModel(model:)` is called with a MessageContentModel
- **THEN** the sender's fullName is prepended with ": ", followed by the message text (for text/aiStreamText, checking rich-text content first) or the content-of-message display string for other types

---

### Requirement: NEAudioSessionManager

NEAudioSessionManager is a singleton managing audio session routing and proximity monitoring for speaker/receiver switching.

#### Scenario: Singleton initialization
- **WHEN** `NEAudioSessionManager.shared` is accessed
- **THEN** the audio session is configured with `.playAndRecord` category and `.voiceChat` mode

#### Scenario: switchToSpeaker
- **WHEN** `switchToSpeaker()` is called
- **THEN** the audio route is set to `.speaker` and proximity monitoring starts

#### Scenario: switchToReceiver
- **WHEN** `switchToReceiver()` is called
- **THEN** the audio route is set to `.none` (receiver) and proximity monitoring stops

#### Scenario: Proximity monitoring
- **WHEN** the device proximity state changes while speaker is active
- **THEN** `handleProximityChange` switches to receiver when the user puts the phone to their ear, and back to speaker when they move it away

#### Scenario: configureAudioSession
- **WHEN** `configureAudioSession()` is called
- **THEN** `AVAudioSession.sharedInstance()` is set to `.playAndRecord` category with `.voiceChat` mode and activated

#### Scenario: setAudioRoute
- **WHEN** `setAudioRoute(to:)` is called with a port override
- **THEN** the audio session is reconfigured and the output port is overridden
