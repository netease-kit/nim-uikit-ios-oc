# ChatUI ViewModels — Swift-to-OC Conversion Spec

> Source: `NEChatUIKit/Classes/Chat/ViewModel/*.swift`

---

## ADDED Requirements

### Requirement: ChatViewModelDelegate Protocol

ChatViewModelDelegate is a protocol with required and optional callbacks for message lifecycle events, UI reload, top-message display, multi-select changes, and AI translation results.

#### Scenario: beforeSend interception (optional, two variants)
- **WHEN** the local client is about to send a message
- **THEN** the delegate method `beforeSend:` (sync) or `beforeSend:completion:` (async) is called, allowing the caller to modify or block the message by returning nil

#### Scenario: Sending / sendSuccess / onResendSuccess
- **WHEN** a message enters sending state
- **THEN** `sending:index:` is called with the message and its IndexPath
- **WHEN** the message succeeds or fails and retries succeed
- **THEN** `sendSuccess:index:` or `onResendSuccess:fromIndex:toIndexPath:` is called

#### Scenario: Receive messages
- **WHEN** new messages arrive for the current conversation
- **THEN** `onRecvMessages:indexs:` is called with the messages and their IndexPaths

#### Scenario: Load more / modify / delete / revoke callbacks
- **WHEN** historical messages finish loading, a message is modified, deleted, or revoked
- **THEN** the corresponding delegate callback (`onLoadMoreWithMessage:`, `onModefiedMessage:`, `onDeleteMessage:deleteIndexs:reloadIndex:`, `onRevokeMessage:atIndexs:`) is invoked

#### Scenario: P2P typing and online status
- **WHEN** the remote user starts/stops typing or their online status changes
- **THEN** `remoteUserEditing`, `remoteUserEndEditing`, or `remoteUserOnlineChanged` is called

#### Scenario: Top message display
- **WHEN** a message is pinned to top in a team chat
- **THEN** `setTopValue:name:content:url:isVideo:hideClose:` is called with the sender name, content summary, optional thumbnail URL, and close-button visibility

#### Scenario: Multi-select changes (optional)
- **WHEN** the user selects/deselects messages in multi-select mode
- **THEN** `selectedMessagesChanged:` is called with the current count

#### Scenario: Translation result (optional)
- **WHEN** an AI translation completes
- **THEN** `didTranslateResult:` is called with the translated text

---

### Requirement: ChatViewModel Base Class

ChatViewModel is an `@objcMembers open class` inheriting from NSObject. It manages a `messages: [MessageModel]` array, message client IDs, pagination anchors (`oldMsg` / `newMsg`), an `anchor` for history navigation, and repos (`chatRepo`, `contactRepo`, `conversationRepo`, `localConversationRepo`).

#### Scenario: Initialization with conversationId
- **WHEN** `init(conversationId:)` is called
- **THEN** `ChatRepo.conversationId` and `ChatRepo.sessionId` are set, listeners are added via `addListener()`, and the AI user list is fetched

#### Scenario: Initialization with conversationId and anchor
- **WHEN** `init(conversationId:anchor:)` is called with a non-nil anchor
- **THEN** `isHistoryChat` is set to true, and the anchor is stored for bidirectional loading

#### Scenario: clearUnreadCount
- **WHEN** `clearUnreadCount()` is called
- **THEN** unread count is cleared and the conversation is marked as read (using local or cloud repo based on `enableV2CloudConversation`)

#### Scenario: loadData with no anchor
- **WHEN** `loadData:` is called with `anchor == nil`
- **THEN** messages are cleared, `getHistoryMessage` is called with `.QUERY_DIRECTION_DESC`, and `loadMoreWithMessage` loads pins/receipts/reply/showNames

#### Scenario: loadData with anchor (bidirectional)
- **WHEN** `loadData:` is called with a non-nil anchor
- **THEN** messages are fetched in both DESC (older) and ASC (newer) directions around the anchor, combined, and the anchor index is returned

#### Scenario: getHistoryMessage pagination
- **WHEN** `getHistoryMessage(order:message:completion:)` is called
- **THEN** a `V2NIMMessageListOption` is created with `limit = messagPageNum (100)`, the anchor message, and direction; results update `oldMsg`/`newMsg` cursors, insert models, add time separators, and invoke the completion

#### Scenario: dropDownRemoteRefresh / pullRemoteRefresh
- **WHEN** the user pulls down or up
- **THEN** `getHistoryMessage` is called with DESC (older) or ASC (newer) direction respectively, with the appropriate cursor message

#### Scenario: loadMoreWithMessage enrichment
- **WHEN** `loadMoreWithMessage:` is called after fetching messages
- **THEN** message receipts are loaded, pinned messages are fetched, sender show-names and avatars are resolved, reply models are loaded, and `tableViewReload` is invoked on the main queue

#### Scenario: insertToMessages ordering
- **WHEN** a new MessageModel is inserted
- **THEN** it is placed in chronological order—appended if newest, otherwise inserted before the first message with a greater createTime

---

### Requirement: Send Message Methods

ChatViewModel provides typed send methods that create messages via `MessageUtils`, obtain AI-aware params via `getSendMessageParams`, and call `sendMessage`.

#### Scenario: sendTextMessage
- **WHEN** `sendTextMessage(text:conversationId:remoteExt:aiUserAccid:completion:)` is called with non-empty text
- **THEN** a text message is created, AI params are applied if the session is an AI user, and `sendMessage` is invoked

#### Scenario: sendRichTextMessage
- **WHEN** `sendRichTextMessage(message:title:body:aiUserAccid:completion:)` is called
- **THEN** the pre-built rich-text custom message is sent with AI params

#### Scenario: sendAudioMessage with deduplication
- **WHEN** `sendAudioMessage(filePath:conversationId:completion:)` is called
- **THEN** `ChatDeduplicationHelper` checks for duplicate audio paths before sending

#### Scenario: sendImageMessage / sendVideoMessage / sendLocationMessage / sendFileMessage / sendCustomMessage
- **WHEN** any typed send method is called
- **THEN** the corresponding `MessageUtils` factory method creates the message, and `sendMessage` sends it with appropriate params

#### Scenario: convertVideoToMP4
- **WHEN** the video is not already MP4
- **THEN** `AVAssetExportSession` converts it to MP4 before sending

---

### Requirement: Reply Messages

#### Scenario: replyMessageWithoutThread
- **WHEN** replying without thread
- **THEN** reply metadata is stored in `serverExtension` under `keyReplyMsgKey`, and the message is sent with AI reply params

#### Scenario: replyMessageWithThread
- **WHEN** replying with thread
- **THEN** `chatRepo.replyMessage` is called, which uses the SDK's built-in thread reply

---

### Requirement: Revoke Message

#### Scenario: revokeMessage
- **WHEN** `revokeMessage(message:completion:)` is called
- **THEN** revoke metadata (content, time, isRevoke flag) is stored in `serverExtension`, `chatRepo.revokeMessage` is called, and on success `revokeMessageUpdateUI` updates the model with `isRevoked = true` and optionally `isReedit = true` for text/richText messages

---

### Requirement: Delete Messages

#### Scenario: deleteMessage single
- **WHEN** `deleteMessage:` is called
- **THEN** `deletingMsgDic` set prevents duplicate deletes; local-only messages (no serverId) use `onlyDeleteLocal: true`; on success `deleteMessageUpdateUI` removes the model and updates reply references

#### Scenario: deleteMessages batch
- **WHEN** `deleteMessages(messages:completion:)` is called
- **THEN** messages are split into local and remote groups and deleted separately

---

### Requirement: Forward Messages

#### Scenario: forwardMessage (one-by-one)
- **WHEN** `forwardMessage` is called with `isMultiForward = false`
- **THEN** each selected message is forwarded individually to each target conversation, followed by an optional comment with 0.2s delay

#### Scenario: forwardMultiMessage (merge forward)
- **WHEN** `forwardMessage` is called with `isMultiForward = true`
- **THEN** a header+body file is built, uploaded, and a custom message of type `customMultiForwardType` containing the URL, MD5, depth, and abstracts is sent to each target conversation

---

### Requirement: Pin / Unpin / Top / Untop / Collect Messages

#### Scenario: addPinMessage / removePinMessage
- **WHEN** pin or unpin is called
- **THEN** `chatRepo.pinMessage` or `chatRepo.unpinMessage` is called, and the local model's `isPined`/`pinAccount`/`pinShowName` are updated

#### Scenario: topMessage / untopMessage (TeamChatViewModel)
- **WHEN** top/untop is invoked
- **THEN** team server extension is updated with the top-message dictionary (operation 0=add, 1=remove), with permission checks for advanced teams

#### Scenario: collectMessage
- **WHEN** `collectMessage` is called
- **THEN** the message is serialized, at-info is removed, and `chatRepo.addCollection` is called with type, data, and uniqueId

---

### Requirement: Message Operations List

#### Scenario: avalibleOperationsForMessage
- **WHEN** `avalibleOperationsForMessage:` is called for a message model
- **THEN** the available operations (copy, reply, forward, pin/removePin, delete, select, collection, top/untop, recall, earpiece/speaker, audioToText) are returned based on message type, sending state, and config flags (`enableCollectionMessage`, `enablePinMessage`, `enableTopMessage`)

---

### Requirement: AI Integration

#### Scenario: getSendMessageParams with AI user
- **WHEN** the session target or explicit `aiUserAccid` is an AI user
- **THEN** `V2NIMMessageAIConfigParams` is created with the AI accountId, stream flag, content, and optional context messages from `getAIMessages()`

#### Scenario: getAIMessages context
- **WHEN** sending to an AI user in direct chat
- **THEN** the last `aiMessagNum (30)` text/aiStreamText/richText messages are collected as `V2NIMAIModelCallMessage` with user/assistant roles

#### Scenario: translateLanguage
- **WHEN** `translateLanguage(sourceText:targetLanguage:completion:)` is called
- **THEN** a `V2NIMProxyAIModelCallParams` request is sent with the translation AI user, prompt variables, and a unique requestId; results arrive via `onProxyAIModelCall` listener

#### Scenario: stopAIStreamMessage / regenAIMessage
- **WHEN** stop or regen is called
- **THEN** the corresponding chatRepo method is called with the message and params

---

### Requirement: NEMessageListener Callbacks (ChatViewModel extension)

#### Scenario: onSendMessage state routing
- **WHEN** `onSendMessage:` fires
- **THEN** sending/failed/succeeded states are routed to `sendingMsg`, `sendMsgFailed`, or `sendMsgSuccess`

#### Scenario: onReceiveMessages
- **WHEN** messages are received for the current conversation
- **THEN** each message is converted to a model, time is added, audio is downloaded, replies are loaded, the model is inserted, and `onRecvMessages` delegate is called

#### Scenario: onReceiveMessagesModified
- **WHEN** a message is modified remotely
- **THEN** the corresponding model is reset and `onModefiedMessage` is called

#### Scenario: onMessageRevokeNotifications / onMessageDeletedNotifications
- **WHEN** revoke or delete notifications arrive
- **THEN** the corresponding UI update method is called, and top-message is cleared if affected

#### Scenario: onMessagePinNotification
- **WHEN** a pin notification arrives
- **THEN** the message model's pin state, account, and show-name are updated, and `onMessageStatusChange` is called

#### Scenario: onReceiveP2PMessageReadReceipts / onReceiveTeamMessageReadReceipts
- **WHEN** read receipts arrive
- **THEN** message models' readCount/unreadCount are updated and `onLoadMoreWithMessage` is called with affected IndexPaths

---

### Requirement: P2PChatViewModel

P2PChatViewModel extends ChatViewModel for P2P conversations with typing indicators, online status subscription, and P2P-specific read receipts.

#### Scenario: Typing indicator
- **WHEN** `sendInputTypingState()` / `sendInputTypingEndState()` is called
- **THEN** a custom notification with `{"typing": 1}` or `{"typing": 0}` is sent to the peer

#### Scenario: Receive typing notification
- **WHEN** `onReceiveCustomNotifications:` fires with a typing payload from the current peer
- **THEN** `delegate.remoteUserEditing()` or `delegate.remoteUserEndEditing()` is called

#### Scenario: Online status subscription
- **WHEN** `enableOnlineStatus` is true
- **THEN** the peer's online status is subscribed, and `onUserStatusChanged` updates the `online` property and calls `delegate.remoteUserOnlineChanged()`

#### Scenario: P2P read receipt
- **WHEN** `markRead` is called
- **THEN** only the latest non-self message with `readReceiptSent == false` is marked read via `chatRepo.markP2PMessageRead`

#### Scenario: getShowName override
- **WHEN** `getShowName:` is called
- **THEN** it checks `NEFriendUserCache` first, then falls back to `NEP2PChatUserCache`

---

### Requirement: TeamChatViewModelDelegate Protocol

TeamChatViewModelDelegate extends ChatViewModelDelegate with optional callbacks for team removed, team updated, and team member updated.

---

### Requirement: TeamChatViewModel

TeamChatViewModel extends ChatViewModel for team conversations with team info, member management, top-message, and team-specific read receipts.

#### Scenario: addListener
- **WHEN** the VM initializes
- **THEN** team listener and `NETeamUserManager` listener are added, and team data is loaded

#### Scenario: getShowName override
- **WHEN** `getShowName:` is called
- **THEN** it delegates to `NETeamUserManager.shared.getShowName` which resolves alias > team nick > nickname > ID

#### Scenario: loadTopMessage
- **WHEN** `loadTopMessage()` is called and `enableTopMessage` is true
- **THEN** team server extension is parsed for `keyTopMessage`, the message is fetched by refer, and `delegate.setTopValue` is called

#### Scenario: hasTopMessagePremission
- **WHEN** checking top-message permission
- **THEN** discussion groups always have permission; advanced groups require owner/manager role, or `allowAtAllValue` in server extension

#### Scenario: markReadInTeam
- **WHEN** `markRead` is called
- **THEN** messages with serverId, not self, with readReceiptEnabled, and not yet sent are batch-marked via `chatRepo.markTeamMessagesRead`

#### Scenario: getTeamMessageReceipts
- **WHEN** `getTeamMessageReceipts` is called
- **THEN** self-sent messages are chunked (50 per batch), receipts are fetched, and readCount/unreadCount are updated

#### Scenario: NETeamChatUserCacheListener callbacks
- **WHEN** team info or team member is updated in the cache
- **THEN** `onTeamInfoUpdate` reloads top message and notifies delegate; `onTeamMemberUpdate` updates message info and notifies delegate

---

### Requirement: CollectionMessageViewModel

CollectionMessageViewModel manages collected (favorited) messages with pagination, forwarding, and deletion.

#### Scenario: loadData pagination
- **WHEN** `loadData:` is called
- **THEN** `V2NIMCollectionOption` is built with the last collection as anchor, `pageSize = 100`, DESC direction, and collections are parsed into `CollectionMessageModel` array

#### Scenario: parseMessage deserialization
- **WHEN** collections are received
- **THEN** each collection's JSON data is deserialized to extract message, conversationName, avatar, and senderName

#### Scenario: forwardCollectionMessages
- **WHEN** forwarding a collected message
- **THEN** a forward message is created, at-marks are cleared, and it is sent to each target conversation with optional AI params

#### Scenario: removeCollection
- **WHEN** `removeCollection:` is called
- **THEN** `chatRepo.removeCollections` is called with the collection object

---

### Requirement: MultiForwardViewModel

MultiForwardViewModel displays the contents of a merged-forward message.

#### Scenario: loadData
- **WHEN** `loadData:` is called with a URL and file path
- **THEN** the file is downloaded if not present, then decoded line-by-line (skipping header), each line deserialized as a message and converted to a MessageModel

#### Scenario: MD5 verification
- **WHEN** `decodeMessage` is called
- **THEN** the file's MD5 is verified against the expected value; mismatch returns an error

#### Scenario: modelFromMessage override
- **WHEN** converting messages
- **THEN** audio and call messages are converted to text representations; sender nick and avatar are extracted from `serverExtension`

---

### Requirement: PinMessageViewModel

PinMessageViewModel manages the pinned-messages list for a conversation.

#### Scenario: getPinitems
- **WHEN** `getPinitems(conversationId:completion:)` is called
- **THEN** pinned message list is fetched, messages are retrieved by refers, models are built sorted by createTime DESC, and sender info is loaded

#### Scenario: removePinMessage
- **WHEN** `removePinMessage:` is called
- **THEN** `chatRepo.unpinMessage` is called

#### Scenario: NEChatListener for pin updates
- **WHEN** revoke/pin/delete notifications arrive
- **THEN** the items list is updated and delegate is notified to reload

#### Scenario: forwardMessages
- **WHEN** forwarding a pinned message
- **THEN** the message is forwarded to target conversations with optional AI params and comment

---

### Requirement: ReadViewModel

ReadViewModel displays read/unread details for a team message.

#### Scenario: getTeamMessageReceiptDetail
- **WHEN** `getTeamMessageReceiptDetail:teamId:completion:` is called
- **THEN** read receipt detail is fetched, user info is loaded via `NETeamUserManager`, and `readUsers`/`unReadUsers` arrays are populated with `NETeamMemberInfoModel`

---

### Requirement: SelectLanguageViewModel

SelectLanguageViewModel provides the data for the language selection UI.

#### Scenario: setupData
- **WHEN** `setupData:` is called
- **THEN** `NETranslateLanguageManager.shared.languageDatas` is iterated to create `NElanguageCellModel` items with language name and corner type (Fun skin uses rounded corners)

---

### Requirement: UserSettingViewModel

UserSettingViewModel manages the P2P chat settings page (pin, history, message remind, stick-top, AI pin).

#### Scenario: getUserSettingModel
- **WHEN** `getUserSettingModel:completion:` is called
- **THEN** user info is fetched via `contactRepo`, and `getSectionDatas` builds the cell models

#### Scenario: getSectionDatas cell construction
- **WHEN** `getSectionDatas()` is called
- **THEN** cells for pin-mark, history, message-remind (with mute mode switch), session stick-top (with conversation stickTop switch), and optional AI-user pin-top are built with switch change handlers

#### Scenario: Conversation listener
- **WHEN** the conversation changes (cloud or local)
- **THEN** `getSectionDatas` is called and the delegate is refreshed

---

### Requirement: TeamHistoryMessageViewModel

TeamHistoryMessageViewModel extends ChatViewModel for searching and displaying historical messages (text, media, files).

#### Scenario: searchHistoryMessages
- **WHEN** `searchHistoryMessages:firstSearch:completion:` is called
- **THEN** cloud or local search is performed based on `enableCloudMessageSearch`, results are paginated via `pageToken`, keyword highlighting is applied to text/richText models

#### Scenario: searchHistryMediaMessages
- **WHEN** media search is performed (image/video/file)
- **THEN** results are grouped into `MediaMessageModel` sections by date, sorted by time

#### Scenario: Override onReceiveMessages
- **WHEN** new messages are received in history search
- **THEN** they are ignored (no-op override)

---

### Requirement: TeamMemberSelectVM

TeamMemberSelectVM fetches team member data for the @-mention member selector.

#### Scenario: getTeamMembers
- **WHEN** `getTeamMembers:completion:` is called
- **THEN** cached team members are returned if available, otherwise `NETeamUserManager.shared.getAllTeamMembers` is called and the result is wrapped in `NETeamInfoModel`
