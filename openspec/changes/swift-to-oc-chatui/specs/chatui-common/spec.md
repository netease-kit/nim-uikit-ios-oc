# chatui-common: Swift-to-OC Conversion Spec

Converts NEChatUIKit Common directory classes from Swift to Objective-C.

**Swift Source:** `xkit-ios/IMUIKit/NEChatUIKit/NEChatUIKit/Classes/Common/`
**OC Output:** `NIMUIKitDemo/IMUIKit/NEChatUIKitOC/NEChatUIKitOC/Classes/Common/`

---

## ADDED Requirements

### Requirement: Convert NEChatUIKitClient

Singleton client class that manages more-action panel data and custom cell registration for the chat UI.

**Swift file:** `Common/NEChatUIKitClient.swift`
**OC files:** `Common/NEChatUIKitClient.h`, `Common/NEChatUIKitClient.m`

#### Scenario: Singleton and default moreAction list
- **WHEN** `[NEChatUIKitClient instance]` is accessed
- **THEN** a shared singleton is returned
- **THEN** `moreAction` (`NSMutableArray<NEMoreItemModel *>`) is pre-populated in `init` with:
  - **photo** — image `fun_chat_photo`, title `chatLocalizable(@"chat_photo")`, type `.photo`
  - **takePicture** — image `chat_takePicture`, title `chatLocalizable(@"chat_takePicture")`, type `.takePicture`
  - **file** — image `chat_file`, title `chatLocalizable(@"chat_file")`, type `.file`
  - **rtc** (conditional) — only if `NERtcCallUIKit` service is registered; image `chat_rtc`, title `chatLocalizable(@"chat_rtc")`, type `.rtc`
  - **translate** (conditional) — only if `IMKitConfigCenter.shared.enableAIUser == YES`; image `chat_translation`, title `chatLocalizable(@"chat_translate")`, type `.translate`
  - **aiChat** (conditional) — only if `IMKitConfigCenter.shared.enableAIChatHelper == YES`; image `fun_chat_aiChat`, title `chatLocalizable(@"ai_chat_title")`, type `.aiChat`

#### Scenario: getMoreActionData
- **WHEN** `getMoreActionData:viewController:` is called with a `V2NIMConversationType` and `ChatViewController *`
- **THEN** it returns a filtered copy of `moreAction` where `.rtc` items are only included for P2P conversations
- **THEN** if `ChatUIConfig.shared.chatInputMenu` block is set, it is invoked with the view controller and mutable array

#### Scenario: regsiterCustomCell (note: original Swift has this typo)
- **WHEN** `regsiterCustomCell:` is called with `NSDictionary<NSString *, Class> *`
- **THEN** each key-value pair is stored in an internal `customRegisterDic` dictionary
- **THEN** each registration is logged via `NEALog`

#### Scenario: getRegisterCustomCell
- **WHEN** `getRegisterCustomCell` is called
- **THEN** the internal `customRegisterDic` dictionary is returned

#### Scenario: getImageSource
- **WHEN** `getImageSource:` is called with an image name string
- **THEN** it returns `[chatCoreLoader loadImage:imageName]`

#### Scenario: getLanguage
- **WHEN** `getLanguage:` is called with a localization key
- **THEN** it returns `[chatCoreLoader localizable:key]`

---

### Requirement: Convert ChatConstant

Global constants, utility functions, protocol, and notification name extensions used across the chat UI module.

**Swift file:** `Common/ChatConstant.swift`
**OC files:** `Common/ChatConstant.h`, `Common/ChatConstant.m`

#### Scenario: chatCoreLoader and chatLocalizable
- **WHEN** the module is loaded
- **THEN** a global `chatCoreLoader` (`CommonLoader<NEChatBaseViewController>`) is available
- **THEN** `NSString *chatLocalizable(NSString *key)` returns `[chatCoreLoader localizable:key]`

#### Scenario: JSON utility functions
- **WHEN** `getJSONStringFromDictionary:` is called with an `NSDictionary *`
- **THEN** it returns a JSON string, or `@""` if serialization fails
- **WHEN** `getDictionaryFromJSONString:` is called with an `NSString *`
- **THEN** it returns an `NSDictionary *` or `nil` if parsing fails

#### Scenario: ViewModelDelegate protocol
- **WHEN** `ViewModelDelegate` is declared
- **THEN** it conforms to `NSObject` with:
  - Required: `dataDidChange`, `dataDidError:(NSError *)error`
  - Optional: `dataNoMore`

#### Scenario: Screen dimension constants
- **WHEN** screen constants are referenced
- **THEN** the following are available as `extern` C constants or macros:
  - `kScreenWidth` — `UIScreen.mainScreen.bounds.size.width`
  - `kScreenHeight` — `UIScreen.mainScreen.bounds.size.height`
  - `kUISreenWidthScale` — `kScreenWidth / 375.0`
  - `kUISreenHeightScale` — `kScreenHeight / 667.0`
  - `kNavigationHeight` — `44.0`
  - `KStatusBarHeight` — `UIApplication.sharedApplication.statusBarFrame.size.height`
  - `ModuleName` — `@"NEChatUIKit"`

#### Scenario: File format support arrays
- **WHEN** file format constants are referenced
- **THEN** the following `NSArray<NSString *>` constants are available:
  - `file_audio_support` — `@[@"mp3", @"aac", @"wav", @"wma", @"flac"]`
  - `file_video_support` — `@[@"mp4", @"avi", @"wmv", @"mpeg", @"m4v", @"mov", @"asf", @"flv", @"f4v", @"rmvb", @"rm", @"3gp"]`
  - `file_img_support` — `@[@"jpg", @"jpeg", @"png", @"tiff", @"heic", @"gif"]`
  - `file_xls_support` — `@[@"xls", @"xlsx", @"csv"]`
  - `file_doc_support` — `@[@"doc", @"docx"]`
  - `file_ppt_support` — `@[@"ppt", @"pptx"]`
  - `file_txt_support` — `@[@"txt"]`
  - `file_zip_support` — `@[@"zip", @"tar", @"rar", @"7z"]`
  - `file_pdf_support` — `@[@"pdf", @"rtf"]`
  - `file_html_support` — `@[@"html"]`

#### Scenario: Antispam result code dictionary
- **WHEN** `antispamResultCodeDic` is referenced
- **THEN** an `NSDictionary<NSNumber *, NSString *>` maps error codes to localized descriptions:
  - `100` → `chatLocalizable(@"failed_message_reson_ornography")`
  - `200` → `chatLocalizable(@"failed_message_reson_advertising")`
  - `260` → `chatLocalizable(@"failed_message_reson_advertising_law")`
  - `300` → `chatLocalizable(@"failed_message_reson_violence_and_terrorism")`
  - `400` → `chatLocalizable(@"failed_message_reson_prohibited")`
  - `500` → `chatLocalizable(@"failed_message_reson_political_related")`
  - `600` → `chatLocalizable(@"failed_message_reson_abuse")`
  - `700` → `chatLocalizable(@"failed_message_reson_waterlogging")`
  - `900` → `chatLocalizable(@"failed_message_reson_others")`
  - `1000` → `chatLocalizable(@"failed_message_reson_value_related")`

#### Scenario: UI layout constants
- **WHEN** layout constants are referenced
- **THEN** the following `CGFloat` / `NSInteger` / `NSString` constants are available:
  - `kScreenInterval` — `20.0`
  - `NEMoreView_Section_Padding` — `24.0`
  - `NEMoreCell_ReuseId` — `@"NEMoreCell"`
  - `NEMoreCell_Image_Size` — `CGSizeMake(56.0, 56.0)`
  - `NEMoreCell_Title_Height` — `20.0`
  - `NEMoreView_Margin` — `16.0`
  - `NEMoreView_Column_Count` — `4`

#### Scenario: Color helper functions
- **WHEN** `HexRGB(rgbValue)` is called
- **THEN** it returns a `UIColor` with alpha 1.0 from the hex integer
- **WHEN** `HexRGBAlpha(rgbValue, alpha)` is called
- **THEN** it returns a `UIColor` with the specified alpha

#### Scenario: Named color constants
- **WHEN** color constants are referenced
- **THEN** the following are available:
  - `TextNormalColor` — `HexRGB(0x333333)`
  - `SubTextColor` — `HexRGB(0x666666)`
  - `PlaceholderTextColor` — `HexRGB(0xA6ADB6)`
  - `multiForwardLineColor` — `HexRGB(0xF0F1F5)`
  - `forwardLineColor` — `HexRGB(0xE1E6E8)`
  - `multiForwardborderColor` — `HexRGB(0xE4E9F2)`

#### Scenario: Font helper functions
- **WHEN** `TextFont(fontName, fontSize)` is called
- **THEN** it returns a `UIFont` with the given name and size (fallback to system font)
- **WHEN** `DefaultTextFont(fontSize)` is called
- **THEN** it returns `TextFont(@"PingFangSC-Regular", fontSize)`

#### Scenario: NENotificationName extensions
- **WHEN** notification names are referenced
- **THEN** the following `NSNotificationName` constants are available:
  - `NENotificationNameCreateServer` — `@"qchat.createServer"`
  - `NENotificationNameCreateChannel` — `@"qchat.createChannel"`
  - `NENotificationNameUpdateChannel` — `@"qchat.updateChannel"`
  - `NENotificationNameDeleteChannel` — `@"qchat.deleteChannel"`
  - `NENotificationNameLeaveTeamBySelf` — `@"team.leaveTeamBySelf"`
  - `NENotificationNamePopGroupChatVC` — `@"team.popGroupChatVC"`
  - `NENotificationNameLogout` — `@"qchat.logout"`

---

### Requirement: Convert ChatCellConstantValue

Layout constants for chat message cells.

**Swift file:** `Common/ChatCellConstantValue.swift`
**OC files:** `Common/ChatCellConstantValue.h`, `Common/ChatCellConstantValue.m`

#### Scenario: Cell layout constants
- **WHEN** cell layout constants are referenced
- **THEN** the following `CGFloat` / `CGSize` constants are available:
  - `chat_cell_margin` — `16.0` (distance from cell edge)
  - `chat_content_margin` — `8.0` (spacing between controls)
  - `chat_headWH` — `32.0` (avatar width/height)
  - `chat_timeCellH` — `22.0` (time cell fixed height)
  - `chat_pic_size` — `CGSizeMake(150, 200)` (max image dimensions)
  - `chat_file_size` — `CGSizeMake(254, 56)` (file cell dimensions)
  - `chat_min_h` — `40.0` (single-line bubble height)
  - `fun_chat_min_h` — `42.0` (single-line bubble height, Fun skin)
  - `chat_reply_height` — `16.0` (reply label height)
  - `fun_chat_reply_height` — `44.0` (reply label height, Fun skin)
  - `chat_content_maxW` — `kScreenWidth - 156` (max bubble width)
  - `chat_text_maxW` — `chat_content_maxW - 2 * chat_content_margin` (max text content width)
  - `chat_pin_height` — `16.0` (pin message extra height)
  - `chat_full_name_height` — `16.0` (group chat sender name label height)
  - `audio_max_width` — `kScreenWidth <= 325 ? 230 : 265.0` (voice message max width)
  - `ai_chat_view_height` — `234.0` (AI chat area height)

---

### Requirement: Convert NETranslateLanguageManager

Singleton manager holding translation language options.

**Swift file:** `Common/NETranslateLanguageManager.swift`
**OC files:** `Common/NETranslateLanguageManager.h`, `Common/NETranslateLanguageManager.m`

#### Scenario: Singleton
- **WHEN** `[NETranslateLanguageManager shared]` is accessed
- **THEN** a shared singleton is returned

#### Scenario: languageDatas
- **WHEN** `languageDatas` property is accessed
- **THEN** it returns `NSArray<NSString *>` with values: `@[@"英语", @"日语", @"韩语", @"俄语", @"法语", @"德语"]`

---

### Requirement: Convert NSBundleExtension

Category on `NSBundle` providing emoji bundle and resource lookup helpers.

**Swift file:** `Common/NSBundleExtension.swift`
**OC files:** `Common/NSBundle+NEChatEmoji.h`, `Common/NSBundle+NEChatEmoji.m`

#### Scenario: nim_defaultEmojiBundle
- **WHEN** `[NSBundle nim_defaultEmojiBundle]` is called
- **THEN** it returns a `NSBundle` loaded from `NIMKitEmoticon.bundle` within the bundle containing `NIMInputEmoticonManager`, or `nil` if not found

#### Scenario: nim_EmojiPlistFile
- **WHEN** `[NSBundle nim_EmojiPlistFile]` is called
- **THEN** it returns the path to `emoji_ios_cn.plist` inside the emoji bundle's `NIMKit_EmojiPath` directory, or `nil`

#### Scenario: nim_EmojiImage
- **WHEN** `[NSBundle nim_EmojiImageWithImageName:]` is called with an image name
- **THEN** it looks for `@3x` variant first (if screen scale is 3.0), then falls back to `@2x`
- **THEN** it returns the full path to the image file inside the emoji bundle, or `nil`
