# ChatUI Models — Swift-to-OC Conversion Spec

Source: `NEChatUIKit/Classes/Chat/Model/`

---

## ADDED Requirements

### Requirement: MessageType Enum
The `MessageType` enum (defined in NEChatKit `MessageModel.swift`) defines the type of a chat message. It is an `@objc` `Int`-backed enum used throughout the model hierarchy.

Values: `text = 1`, `image`, `audio`, `video`, `location`, `notification`, `file`, `tip`, `robot`, `rtcCallRecord`, `custom`, `time`, `revoke`, `multiForward`, `richText`, `aiStreamText`.

#### Scenario: MessageType conversion
- **WHEN** the OC version of `MessageType` is created
- **THEN** it SHALL be an `NS_ENUM(NSInteger, MessageType)` with all 16 values matching the Swift definition

---

### Requirement: MessageModel Protocol
The `MessageModel` protocol (defined in NEChatKit) is an `@objc` protocol inheriting from `NSObjectProtocol`. It defines the common interface for all message models.

**Properties (all read-write):**
- `message: V2NIMMessage?`
- `type: MessageType`
- `customType: Int`
- `contentSize: CGSize` — bubble area size
- `offset: CGFloat`
- `height: CGFloat`
- `shortName: String?` — last 2 chars of name
- `fullName: String?` — full display name
- `avatar: String?`
- `isPined: Bool`
- `pinAccount: String?`
- `pinShowName: String?`
- `isReply: Bool`
- `replyedModel: MessageModel?` — the message being replied to
- `replyText: String?`
- `isRevoked: Bool`
- `isReedit: Bool`
- `revokeTime: TimeInterval`
- `readCount: Int`
- `unreadCount: Int`
- `showSelect: Bool`
- `isSelected: Bool`
- `inMultiForward: Bool`
- `timeContent: String?`
- `unkonwMessage: Bool`

**Methods:**
- `cellHeight() -> CGFloat`
- `init(message: V2NIMMessage?)`

#### Scenario: MessageModel protocol conversion
- **WHEN** the OC version of `MessageModel` is created
- **THEN** it SHALL be an `@protocol MessageModel <NSObject>` with all 22 properties and 2 methods matching the Swift protocol

---

### Requirement: MessageContentModel
`MessageContentModel` is an `@objcMembers open class` inheriting from `NSObject` and conforming to `MessageModel`. It is the **base class** for all concrete message models.

**Properties:**
- `type: MessageType` — default `.custom`
- `customType: Int` — default `0`
- `message: V2NIMMessage?`
- `cell: NEChatBaseCell?` — `weak` reference to the cell displaying this message
- `offset: CGFloat` — default `0`
- `textWidth: CGFloat` — default `0`
- `contentSize: CGSize` — default `(32.0, chat_min_h)`
- `height: CGFloat` — default `48`
- `selectRange: NSRange?` — range for word-selection
- `showSelect: Bool` — default `false`
- `isSelected: Bool` — default `false`
- `isSelectAll: Bool` — default `false`
- `unkonwMessage: Bool` — default `false`
- `inMultiForward: Bool` — default `false`; `didSet` adjusts `fullNameHeight` and `height`
- `avatar: String?`
- `shortName: String?`
- `fullName: String?`
- `fullNameHeight: CGFloat` — default `0`
- `readCount: Int` — default `0`
- `unreadCount: Int` — default `0`
- `isReply: Bool` — default `false`
- `replyText: String?`
- `replyedModel: MessageModel?` — `didSet` sets `isReply=true` and computes `replyText`
- `isReedit: Bool` — default `false`
- `timeOut: Bool` — default `false`
- `revokeTime: TimeInterval` — default `0`
- `isRevoked: Bool` — default `false`; `didSet` recalculates `type`, `contentSize`, and `height`
- `pinAccount: String?`
- `pinShowName: String?`
- `isPined: Bool` — default `false`
- `timeContent: String?` — `didSet` adds `chat_timeCellH` to height
- `messageTextFont: UIFont` — based on self/receive text size from `ChatUIConfig`
- `messageTextColor: UIColor` — based on self/receive text color from `ChatUIConfig`
- `messageMaxSize: CGSize` — `let`, `(chat_content_maxW, CGFloat.greatestFiniteMagnitude)`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets font/color based on sender, sets `fullNameHeight` for team messages

**Methods:**
- `open func cellHeight() -> CGFloat` — returns `height + offset`
- `open func selectText() -> String?` — returns `nil` (overridden by subclasses)
- `open func resetMessage(_ message: V2NIMMessage?)` — updates `self.message`

#### Scenario: MessageContentModel conversion
- **WHEN** the OC version of `MessageContentModel` is created
- **THEN** it SHALL have all 33 properties, the required initializer, and 3 methods matching the Swift version
- **AND** `isRevoked` setter SHALL recalculate type/contentSize/height
- **AND** `inMultiForward` setter SHALL adjust fullNameHeight and height
- **AND** `replyedModel` setter SHALL set isReply and compute replyText
- **AND** `timeContent` setter SHALL add chat_timeCellH to height

---

### Requirement: MessageTextModel
`MessageTextModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents text messages.

**Properties:**
- `messageText: String?`
- `attributeStr: NSMutableAttributedString?`
- `textHeight: CGFloat` — default `0`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .text`, `messageText = message?.text`, calls `resetMessage`

**Methods:**
- `override func resetMessage(_ message: V2NIMMessage?)` — parses emoji with `NEEmotionTool.getAttWithStr`, applies `@` highlighting, calls `resetHeight()`
- `func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize` — computes text size with `getRealTextViewSize`
- `func resetHeight(_ attributeStr: NSAttributedString? = nil)` — computes `textHeight`, `textWidth`, `contentSize`, `height`
- `func resetWH(_ height: CGFloat, _ width: CGFloat = chat_content_maxW)` — manually sets text dimensions
- `override func selectText() -> String?` — returns selected text using `NEEmotionTool.getTextWithAtt` for emoji replacement

#### Scenario: MessageTextModel conversion
- **WHEN** the OC version of `MessageTextModel` is created
- **THEN** it SHALL have 3 properties and 5 methods (including overrides) matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: MessageImageModel
`MessageImageModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents image messages.

**Properties:**
- `urlString: String?` — resolved from local path or remote URL (with optional thumb)

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .image`, extracts `V2NIMMessageImageAttachment`, computes `contentSize` via `ChatMessageHelper.getSizeWithMaxSize`

#### Scenario: MessageImageModel conversion
- **WHEN** the OC version of `MessageImageModel` is created
- **THEN** it SHALL have 1 property (`urlString`) and the initializer matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: DownloadState Enum
`DownloadState` is an `@objc` `Int`-backed enum with values: `Success = 1`, `Downalod` (note: original typo preserved).

#### Scenario: DownloadState conversion
- **WHEN** the OC version of `DownloadState` is created
- **THEN** it SHALL be an `NS_ENUM(NSInteger, DownloadState)` with values `DownloadStateSuccess = 1` and `DownloadStateDownalod`

---

### Requirement: MessageVideoModel
`MessageVideoModel` is an `@objcMembers open class` that extends `MessageImageModel`. It represents video messages.

**Properties:**
- `state: DownloadState` — default `.Success`
- `progress: UInt` — default `0`
- `historyVideoCell: NEHistorySearchVideoCell?` — `weak`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .video`, extracts `V2NIMMessageVideoAttachment`, computes `contentSize`

**Methods:**
- `open func setModelProgress(_ progress: UInt)` — updates `state` based on progress (100 = Success), notifies `cell` and `historyVideoCell`

#### Scenario: MessageVideoModel conversion
- **WHEN** the OC version of `MessageVideoModel` is created
- **THEN** it SHALL have 3 properties, the initializer, and 1 method matching the Swift version
- **AND** it SHALL inherit from `MessageImageModel`

---

### Requirement: MessageAudioModel
`MessageAudioModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents audio messages.

**Properties:**
- `duration: Int` — default `0`, computed from `V2NIMMessageAudioAttachment.duration` (ms→s rounded)
- `audioWidth: Double` — default `0`, computed as `min(duration * 8 + 96, audio_max_width)`
- `isPlaying: Bool` — default `false`
- `text: String?` — voice-to-text result

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .audio`, extracts attachment, computes `audioWidth` and `contentSize`

#### Scenario: MessageAudioModel conversion
- **WHEN** the OC version of `MessageAudioModel` is created
- **THEN** it SHALL have 4 properties and the initializer matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: MessageFileModel
`MessageFileModel` is an `@objcMembers open class` that extends `MessageVideoModel`. It represents file messages.

**Properties:**
- `displayName: String?`
- `path: String?`
- `fileLength: Int64?`
- `size: Float` — default `0`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .file`, extracts `V2NIMMessageFileAttachment`, sets `contentSize = chat_file_size`

#### Scenario: MessageFileModel conversion
- **WHEN** the OC version of `MessageFileModel` is created
- **THEN** it SHALL have 4 properties and the initializer matching the Swift version
- **AND** it SHALL inherit from `MessageVideoModel`

---

### Requirement: MessageLocationModel
`MessageLocationModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents location messages.

**Properties:**
- `lat: Double?`
- `lng: Double?`
- `title: String?`
- `subTitle: String?`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .location`, extracts `V2NIMMessageLocationAttachment`, sets `contentSize = (242, 140)`

#### Scenario: MessageLocationModel conversion
- **WHEN** the OC version of `MessageLocationModel` is created
- **THEN** it SHALL have 4 properties and the initializer matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: MessageCustomModel
`MessageCustomModel` is an `@objc open class` that extends `MessageContentModel`. It represents custom messages.

**Initializers:**
- `required init(message: V2NIMMessage?)` — sets `type = .custom`
- `init(message: V2NIMMessage?, customType: Int, contentHeight: Int)` — sets `type = .custom`, `customType`, computes `contentSize` and `height`, checks `NECustomUtils.heightOfCustomMessage`

#### Scenario: MessageCustomModel conversion
- **WHEN** the OC version of `MessageCustomModel` is created
- **THEN** it SHALL have 2 initializers matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: MessageTipsModel
`MessageTipsModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents tip and notification messages.

**Properties:**
- `text: String?`

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .tip`, calls `resetMessage`

**Methods:**
- `override func resetMessage(_ message: V2NIMMessage?)` — determines if notification or tip type, extracts text, computes `textWidth`, `contentSize`, `height`

#### Scenario: MessageTipsModel conversion
- **WHEN** the OC version of `MessageTipsModel` is created
- **THEN** it SHALL have 1 property, the initializer, and 1 override method matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`

---

### Requirement: MessageRichTextModel
`MessageRichTextModel` is an `@objcMembers open class` that extends `MessageTextModel`. It represents rich text messages with a title and body.

**Properties:**
- `titleText: String?`
- `titleAttributeStr: NSMutableAttributedString?`
- `titleTextHeight: CGFloat` — default `0`

**Initializer:**
- `required init(message: V2NIMMessage?)` — extracts `title` and `body` from custom data, sets `type = .richText`, `customType = customRichTextType`, computes `titleAttributeStr` and dimensions

**Methods:**
- `override func selectText() -> String?` — returns selected text from either title or body attributed string

#### Scenario: MessageRichTextModel conversion
- **WHEN** the OC version of `MessageRichTextModel` is created
- **THEN** it SHALL have 3 properties, the initializer, and 1 override method matching the Swift version
- **AND** it SHALL inherit from `MessageTextModel`

---

### Requirement: MessageCallRecordModel
`MessageCallRecordModel` is an `@objcMembers open class` that extends `MessageContentModel`. It represents RTC call record messages.

**Properties:**
- `attributeStr: NSMutableAttributedString?` — constructed from `V2NIMMessageCallAttachment` (call type, status, duration, icons)

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .rtcCallRecord`, parses `V2NIMMessageCallAttachment` for call type (audio=1 / video), call status (1=complete, 2=canceled, 3=rejected, 4=timeout, 5=busy), constructs attributed string with icon, computes `contentSize`

#### Scenario: MessageCallRecordModel conversion
- **WHEN** the OC version of `MessageCallRecordModel` is created
- **THEN** it SHALL have 1 property and the initializer matching the Swift version
- **AND** it SHALL inherit from `MessageContentModel`
- **AND** it SHALL handle all 5 call statuses

---

### Requirement: MessageAIStreamModel
`MessageAIStreamModel` is an `@objcMembers open class` that extends `MessageTextModel`. It represents AI streaming text messages rendered with Markdown.

**Initializer:**
- `required init(message: V2NIMMessage?)` — sets `type = .aiStreamText`, calls `resetMessage`

**Methods:**
- `override func resetMessage(_ message: V2NIMMessage?)` — handles aborted stream (replaces empty text with "server busy"), uses `NEMarkdownParser` for Markdown rendering, sets `attributeStr`, calls `resetHeight()`, resets `offset = 0`
- `override func getTextSize(_ attributeStr: NSAttributedString?) -> CGSize` — uses `getRealTextViewSize`

#### Scenario: MessageAIStreamModel conversion
- **WHEN** the OC version of `MessageAIStreamModel` is created
- **THEN** it SHALL have the initializer and 2 override methods matching the Swift version
- **AND** it SHALL inherit from `MessageTextModel`
- **AND** it SHALL use Markdown parsing for content rendering

---

### Requirement: MessageAtInfoModel
`MessageAtInfoModel` is an `@objcMembers open class` inheriting from `NSObject`. It represents the position range of an `@mention` in a message.

**Properties:**
- `start: Int` — default `0`
- `end: Int` — default `0`
- `broken: Bool` — default `false`

#### Scenario: MessageAtInfoModel conversion
- **WHEN** the OC version of `MessageAtInfoModel` is created
- **THEN** it SHALL have 3 properties matching the Swift version

---

### Requirement: MessageAtCacheModel
`MessageAtCacheModel` is an `@objcMembers open class` inheriting from `NSObject`. It caches `@mention` information for a user.

**Properties:**
- `atModel: MessageAtInfoModel` — required, non-optional
- `accid: String` — required, non-optional
- `text: String?`

**Initializer:**
- `init(atModel: MessageAtInfoModel, accid: String)`

#### Scenario: MessageAtCacheModel conversion
- **WHEN** the OC version of `MessageAtCacheModel` is created
- **THEN** it SHALL have 3 properties and the initializer matching the Swift version

---

### Requirement: NEMoreActionType Enum
`NEMoreActionType` is an `@objc` `NSInteger`-backed enum defining action types for the "more" panel in chat input.

Values: `takePicture = 1`, `location`, `rtc`, `game`, `file`, `remind`, `photo`, `translate`, `aiChat`, `other = 100`.

#### Scenario: NEMoreActionType conversion
- **WHEN** the OC version of `NEMoreActionType` is created
- **THEN** it SHALL be an `NS_ENUM(NSInteger, NEMoreActionType)` with all 10 values matching the Swift definition

---

### Requirement: NEMoreItemModel
`NEMoreItemModel` is an `@objc @objcMembers open class` inheriting from `NSObject`. It represents a single item in the "more" action panel.

**Properties:**
- `image: UIImage?` — icon
- `title: String?` — display name
- `type: NEMoreActionType?` — action type
- `action: ((ChatViewController, NEMoreItemModel?) -> Void)?` — callback closure
- `customImage: UIImage?` — custom icon

#### Scenario: NEMoreItemModel conversion
- **WHEN** the OC version of `NEMoreItemModel` is created
- **THEN** it SHALL have 5 properties matching the Swift version
- **AND** the `action` property SHALL be converted to a block type `void(^)(ChatViewController *, NEMoreItemModel *)`

---

### Requirement: NEPinMessageModel
`NEPinMessageModel` is an `@objcMembers open class` inheriting from `NSObject`. It wraps a pinned message with its chat model and pin metadata.

**Properties:**
- `chatmodel: MessageModel` — default `MessageTextModel(message: nil)`
- `message: V2NIMMessage` — non-optional
- `item: V2NIMMessagePin` — non-optional
- `conversationId: String?`
- `repo: ChatRepo` — default `ChatRepo.shared`
- `pinFileModel: PinMessageFileModel?`

**Initializer:**
- `init(message: V2NIMMessage, item: V2NIMMessagePin)` — builds `chatmodel` from message, creates `pinFileModel` for file type

**Methods:**
- `func modelFromMessage(message: V2NIMMessage) -> MessageModel` — uses `ChatMessageHelper.modelFromMessage`, sets `fullName` and `shortName`
- `open func cellHeight(pinContentMaxW: CGFloat) -> CGFloat` — computes display height with text line limits (text: 3 lines, rich text title: 1 line, body: 2 lines)

#### Scenario: NEPinMessageModel conversion
- **WHEN** the OC version of `NEPinMessageModel` is created
- **THEN** it SHALL have 6 properties, the initializer, and 2 methods matching the Swift version

---

### Requirement: PinMessageFileModel
`PinMessageFileModel` is an `@objcMembers open class` inheriting from `NSObject`. It tracks download state for a pinned file message.

**Properties:**
- `progress: UInt` — default `0`
- `size: Float` — default `0`
- `state: DownloadState` — default `.Success`
- `cell: NEBasePinMessageFileCell?` — `weak`

#### Scenario: PinMessageFileModel conversion
- **WHEN** the OC version of `PinMessageFileModel` is created
- **THEN** it SHALL have 4 properties matching the Swift version

---

### Requirement: CollectionFileModel
`CollectionFileModel` is an `@objcMembers open class` inheriting from `NSObject`. It tracks download state for a collected file message.

**Properties:**
- `progress: UInt` — default `0`
- `size: Float` — default `0`
- `state: DownloadState` — default `.Success`
- `cell: NEBaseCollectionMessageFileCell?` — `weak`

#### Scenario: CollectionFileModel conversion
- **WHEN** the OC version of `CollectionFileModel` is created
- **THEN** it SHALL have 4 properties matching the Swift version

---

### Requirement: CollectionMessageModel
`CollectionMessageModel` is an `@objcMembers open class` inheriting from `NSObject`. It represents a collected (favorited) message.

**Properties:**
- `message: V2NIMMessage?` — `didSet` creates `chatmodel` via `ChatMessageHelper.modelFromMessage` and `fileModel` for file type
- `conversationName: String?`
- `senderName: String?`
- `avatar: String?`
- `chatmodel: MessageModel` — default `MessageTextModel(message: nil)`
- `fileModel: CollectionFileModel?`
- `collection: V2NIMCollection?`

**Methods:**
- `open func cellHeight(contenttMaxW: CGFloat) -> CGFloat` — computes height with text line limits (text: 3 lines, rich text title: 1 line, body: 2 lines), adds 124 base height

#### Scenario: CollectionMessageModel conversion
- **WHEN** the OC version of `CollectionMessageModel` is created
- **THEN** it SHALL have 7 properties and 1 method matching the Swift version
- **AND** the `message` setter SHALL auto-create `chatmodel` and `fileModel`

---

### Requirement: UserSettingType Enum
`UserSettingType` is a `public enum` with `Int` raw values: `SwitchType = 1`, `SelectType = 2`.

#### Scenario: UserSettingType conversion
- **WHEN** the OC version of `UserSettingType` is created
- **THEN** it SHALL be an `NS_ENUM(NSInteger, UserSettingType)` with values matching the Swift definition

---

### Requirement: UserSettingCellModel
`UserSettingCellModel` is an `@objcMembers open class` inheriting from `NSObject`. It represents a cell in user settings UI.

**Type aliases (converted to blocks in OC):**
- `SwitchChangeCompletion = (Bool) -> Void`
- `CellClick = () -> Void`

**Properties:**
- `cellName: String?`
- `subTitle: String?`
- `swichChange: SwitchChangeCompletion?` — switch toggle callback
- `rowHeight: CGFloat` — default `49`
- `cornerType: CornerType` — default `.none`
- `cellClick: CellClick?` — cell tap callback
- `switchOpen: Bool` — default `false`
- `type: Int` — default `UserSettingType.SwitchType.rawValue`

#### Scenario: UserSettingCellModel conversion
- **WHEN** the OC version of `UserSettingCellModel` is created
- **THEN** it SHALL have 8 properties matching the Swift version
- **AND** closure types SHALL be converted to OC block types

---

### Requirement: OperationItem Extensions
`OperationItemExtension.swift` provides static factory methods on `OperationItem` for creating long-press menu items and search section items.

**Long-press menu factory methods (13 methods):**
- `earpieceItem()`, `speakerItem()`, `copyItem()`, `replayItem()`, `forwardItem()`, `pinItem()`, `removePinItem()`, `selectItem()`, `collectionItem()`, `topItem()`, `untopItem()`, `deleteItem()`, `recallItem()`, `audioToTextItem()`

**Search section factory methods (5 methods):**
- `searchTeamMemberItem()`, `searchImageItem()`, `searchVideoItem()`, `searchDateItem()`, `searchFileItem()`

Each factory method creates an `OperationItem`, sets `text`, `imageName`, and `type`.

#### Scenario: OperationItem extensions conversion
- **WHEN** the OC version of these factory methods is created
- **THEN** it SHALL implement all 19 factory methods as class methods (or a category) on the OC `OperationItem` class
- **AND** each method SHALL set `text`, `imageName`, and `type` matching the Swift implementation

---

## Summary

| # | Requirement | Type | Properties | Methods/Init |
|---|------------|------|-----------|-------------|
| 1 | MessageType Enum | Enum | 16 values | — |
| 2 | MessageModel Protocol | Protocol | 22 properties | 2 methods |
| 3 | MessageContentModel | Class (base) | 33 properties | 3 methods |
| 4 | MessageTextModel | Class → MessageContentModel | 3 properties | 5 methods |
| 5 | MessageImageModel | Class → MessageContentModel | 1 property | 1 init |
| 6 | DownloadState Enum | Enum | 2 values | — |
| 7 | MessageVideoModel | Class → MessageImageModel | 3 properties | 1 method + init |
| 8 | MessageAudioModel | Class → MessageContentModel | 4 properties | 1 init |
| 9 | MessageFileModel | Class → MessageVideoModel | 4 properties | 1 init |
| 10 | MessageLocationModel | Class → MessageContentModel | 4 properties | 1 init |
| 11 | MessageCustomModel | Class → MessageContentModel | — | 2 inits |
| 12 | MessageTipsModel | Class → MessageContentModel | 1 property | 1 override + init |
| 13 | MessageRichTextModel | Class → MessageTextModel | 3 properties | 1 override + init |
| 14 | MessageCallRecordModel | Class → MessageContentModel | 1 property | 1 init |
| 15 | MessageAIStreamModel | Class → MessageTextModel | — | 2 overrides + init |
| 16 | MessageAtInfoModel | Class → NSObject | 3 properties | — |
| 17 | MessageAtCacheModel | Class → NSObject | 3 properties | 1 init |
| 18 | NEMoreActionType Enum | Enum | 10 values | — |
| 19 | NEMoreItemModel | Class → NSObject | 5 properties | — |
| 20 | NEPinMessageModel | Class → NSObject | 6 properties | 2 methods + init |
| 21 | PinMessageFileModel | Class → NSObject | 4 properties | — |
| 22 | CollectionFileModel | Class → NSObject | 4 properties | — |
| 23 | CollectionMessageModel | Class → NSObject | 7 properties | 1 method |
| 24 | UserSettingType Enum | Enum | 2 values | — |
| 25 | UserSettingCellModel | Class → NSObject | 8 properties | — |
| 26 | OperationItem Extensions | Category | — | 19 factory methods |

**Total: 26 requirements**
