# chatui-base: Swift-to-OC Conversion Spec

Converts NEChatUIKit Base directory classes from Swift to Objective-C.

**Swift Source:** `xkit-ios/IMUIKit/NEChatUIKit/NEChatUIKit/Classes/Base/`
**OC Output:** `NIMUIKitDemo/IMUIKit/NEChatUIKitOC/NEChatUIKitOC/Classes/Base/`

---

## ADDED Requirements

### Requirement: Convert NEChatBaseCell

UITableViewCell subclass used as the base cell for all chat message cells.

**Swift file:** `Base/BaseView/NEChatBaseCell.swift`
**OC files:** `Base/BaseView/NEChatBaseCell.h`, `Base/BaseView/NEChatBaseCell.m`

#### Scenario: Class declaration and initializers
- **WHEN** the OC class `NEChatBaseCell` is declared
- **THEN** it inherits from `UITableViewCell` with `initWithStyle:reuseIdentifier:` setting `selectionStyle` to `UITableViewCellSelectionStyleNone`, and `initWithCoder:` calling super

#### Scenario: uploadProgress method
- **WHEN** `uploadProgress:` is called with a `NSUInteger` progress value
- **THEN** the base implementation is a no-op (subclasses override)

#### Scenario: setModel methods
- **WHEN** `setModel:` is called with a `MessageContentModel *` parameter
- **THEN** the base implementation is a no-op (subclasses override)
- **WHEN** `setModel:isSend:` is called with a `MessageContentModel *` and a `BOOL`
- **THEN** the base implementation is a no-op (subclasses override, `isSend` defaults to `NO`)

---

### Requirement: Convert NEChatBaseViewController

UIViewController subclass with custom navigation bar, used as the base view controller for all chat screens.

**Swift file:** `Base/BaseViewController/NEChatBaseViewController.swift`
**OC files:** `Base/BaseViewController/NEChatBaseViewController.h`, `Base/BaseViewController/NEChatBaseViewController.m`

#### Scenario: Properties
- **WHEN** the OC class `NEChatBaseViewController` is declared
- **THEN** it inherits from `UIViewController <UIGestureRecognizerDelegate>` and exposes:
  - `topConstant` (`CGFloat`, default `0`) — setting it updates `navigationViewHeightAnchor.constant`
  - `navigationViewHeightAnchor` (`NSLayoutConstraint *`, nullable)
  - `navigationView` (`ChatNavigationView *`)
  - `emptyView` (`NEEmptyDataView *`, lazy, hidden by default)

#### Scenario: Title override
- **WHEN** `title` is set on the view controller
- **THEN** both `super.title` and `navigationView.navTitle.text` are updated

#### Scenario: viewWillAppear
- **WHEN** the view will appear
- **THEN** if `ChatUIConfig.shared.messageProperties.showTitleBar` is `NO`, the navigation bar is hidden and `navigationView` is removed
- **THEN** if `useSystemNav` config parameter is `YES`, the system navigation bar is shown, `navigationView` is removed, and `setupBackUI` is called
- **THEN** otherwise the system navigation bar is hidden (custom nav used)

#### Scenario: viewDidLoad
- **WHEN** the view loads
- **THEN** background color is set to clear
- **THEN** `topConstant` is set to `NEConstant.navigationAndStatusHeight`
- **THEN** if not using system nav, `navigationView` is added with Auto Layout constraints (left, right, top pinned to view; height = `topConstant`), and back/more button targets are set

#### Scenario: Navigation helpers
- **WHEN** `setupBackUI` is called
- **THEN** a back bar button item with `CommonUIConfig.shared.backArrowImage` is set as `navigationItem.leftBarButtonItem`
- **WHEN** `backEvent` is called
- **THEN** the view controller is popped from the navigation stack
- **WHEN** `toSetting` is called
- **THEN** the base implementation is a no-op

#### Scenario: Left swipe dismiss gesture
- **WHEN** `addLeftSwipeDismissGesture` is called
- **THEN** a `UIScreenEdgePanGestureRecognizer` on the left edge is added
- **WHEN** the gesture ends
- **THEN** the navigation controller is dismissed

---

### Requirement: Convert NEChatLoaderService

Singleton service that triggers module initialization on load.

**Swift file:** `Base/NEChatLoaderService.swift`
**OC files:** `Base/NEChatLoaderService.h`, `Base/NEChatLoaderService.m`

#### Scenario: Singleton
- **WHEN** `[NEChatLoaderService shared]` is accessed
- **THEN** a shared singleton instance is returned

#### Scenario: setupInit
- **WHEN** `setupInit` is called
- **THEN** `NEChatService.shared` is registered via `ChatKitClient.shared.registerInit:`
- **THEN** bury data points with identifier `@"ChatUIKit"` via `ChatKitClient.shared.buryDataPoints:`

---

### Requirement: Convert NEChatService

Singleton service implementing `ChatServiceDelegate` and `NEChatEmojProtocol`, responsible for router registration, image codec setup, and emoji attribute string generation.

**Swift file:** `Base/NEChatService.swift`
**OC files:** `Base/NEChatService.h`, `Base/NEChatService.m`

#### Scenario: Singleton
- **WHEN** `[NEChatService shared]` is accessed
- **THEN** a shared singleton instance is returned

#### Scenario: setupInit
- **WHEN** `setupInit:` is called with an optional params dictionary
- **THEN** it delegates to `registerRouter:`

#### Scenario: registerRouter
- **WHEN** `registerRouter:` is called
- **THEN** if `param[@"isFun"]` is `YES`, `ChatRouter.registerFun` is called; otherwise `ChatRouter.register`
- **THEN** `NIMKitFileLocationHelper` static appkey and userId are set from NIMSDK/IMKitClient
- **THEN** `SDImageWebPCoder` and `SDImageSVGKCoder` are added to `SDImageCodersManager`
- **THEN** `self` is added as emoj delegate via `NEChatKitClient.instance.addEmojDelegate:`

#### Scenario: getEmojAttributeString
- **WHEN** `getEmojAttributeString:font:color:` is called with content string, font size, and color
- **THEN** it returns an `NSAttributedString` generated by `NEEmotionTool.getAttWithStr:font:color:`

---

### Requirement: Convert ChatInputViewDelegate Protocol

Protocol defining delegate methods for the chat input view.

**Swift file:** `Protocol/ChatInputViewDelegate.swift`
**OC files:** `Protocol/ChatInputViewDelegate.h`

#### Scenario: Protocol declaration
- **WHEN** `ChatInputViewDelegate` is declared in OC
- **THEN** it conforms to `NSObject` and declares the following required methods:
  - `sendText:(NSString *)text attribute:(NSAttributedString *)attribute`
  - `willSelectItem:(UIButton *)button index:(NSInteger)index`
  - `didSelectMoreCell:(NEInputMoreCell *)cell`
  - `textChanged:(NSString *)text` — returns `BOOL`
  - `textDelete:(NSRange)range text:(NSString *)text` — returns `BOOL`
  - `startRecord`
  - `moveOutView`
  - `moveInView`
  - `endRecord:(BOOL)insideView`
  - `textFieldDidChange:(NSString *)text`
  - `textFieldDidEndEditing:(NSString *)text`
  - `textFieldDidBeginEditing:(NSString *)text`
  - `titleTextDidClearEmpty`
  - `textViewDidChange`

---

### Requirement: Convert ChatUIConfig and related types

Singleton configuration class for Chat UI customization, plus the `NEChatAvatarType` enum and `MessageProperties` class.

**Swift file:** `ChatConfig/ChatUIConfig.swift`
**OC files:** `ChatConfig/ChatUIConfig.h`, `ChatConfig/ChatUIConfig.m`

#### Scenario: NEChatAvatarType enum
- **WHEN** `NEChatAvatarType` is declared
- **THEN** it is an `NS_ENUM(NSInteger, ...)` with values `NEChatAvatarTypeRectangle = 1` and `NEChatAvatarTypeCycle`

#### Scenario: ChatUIConfig singleton and block properties
- **WHEN** `[ChatUIConfig shared]` is accessed
- **THEN** a shared singleton is returned with these block/closure properties (all nullable):
  - `messageItemClick` — `void(^)(NEChatBaseViewController *, UITableViewCell *, MessageContentModel *)`
  - `chatInputBar` — `void(^)(ChatViewController *, NSMutableArray<UIButton *> *)`
  - `chatInputPhotoClick` — `void(^)(UIViewController *, NEMediaType, NSInteger, void(^)(NSArray<NEResultModel *> *, BOOL))`
  - `chatInputMenu` — `void(^)(ChatViewController *, NSMutableArray<NEMoreItemModel *> *)`
  - `chatPopMenu` — `void(^)(ChatViewController *, NSMutableArray<OperationItem *> *, MessageContentModel *)`
  - `popMenuClick` — `void(^)(ChatViewController *, OperationItem *)`
  - `customController` — `void(^)(ChatViewController *)`
  - `aiChatViewController` — `void(^)(AIChatViewController *)`
  - `aiChatDataLoader` — `void(^)(NSArray<V2NIMMessage *> *, void(^)(NSArray<AIChatCellModel *> *, NSError *))`
  - `aiChatDidClick` — `void(^)(AIChatViewController *, NSArray<V2NIMMessage *> *)`
  - `aiChatReloadClick` — `void(^)(AIChatViewController *, NSArray<V2NIMMessage *> *)`

#### Scenario: ChatUIConfig scalar properties
- **WHEN** `ChatUIConfig` scalar properties are accessed
- **THEN** they have these defaults:
  - `fileSizeLimit` (`double`, default `200`)
  - `imageThumbSize` (`NSInteger`, default `350`)
  - `maxReadingNum` (`NSInteger`, default `200`)
  - `revokeEditTimeGap` (`NSInteger`, default `2`)

#### Scenario: setRevokeTimeGap / getReeditTimeGap
- **WHEN** `setRevokeTimeGap:` is called with a time in minutes
- **THEN** the value is clamped to `[2, 10080]`
- **WHEN** `getReeditTimeGap` is called
- **THEN** the clamped `revokeTimeGap` value is returned

#### Scenario: MessageProperties class
- **WHEN** `MessageProperties` is declared
- **THEN** it exposes the following properties with defaults:
  - `avatarCornerRadius` (`CGFloat`, `0`)
  - `avatarType` (`NEChatAvatarType`, `.rectangle`)
  - `signalBgColor` (`UIColor`, `ne_yellowBackgroundColor`)
  - `timeTextColor` / `timeTextSize` (`UIColor` / `CGFloat 14`)
  - `selfMessageTextSize` / `receiveMessageTextSize` (`CGFloat 16` each)
  - `selfMessageTextColor` / `receiveMessageTextColor` (`UIColor`, `ne_darkText`)
  - `inputTextColor` / `inputPlaceholderTextColor` (`UIColor`)
  - `selfMessageBgColor` / `receiveMessageBgColor` (`UIColor`, `.clear`)
  - `selfMessageBgImage` / `receiveMessageBgImage` (`UIImage *`, nullable)
  - `backgroundImageCapInsets` (`UIEdgeInsets`, `{35,25,10,25}`)
  - `userNickColor` (`UIColor`, `.white`) / `userNickTextSize` (`CGFloat 12`)
  - `pinMessageTextSize` (`CGFloat 14`)
  - `showP2PMessageStatus` / `showTeamMessageStatus` / `showTeamMessageNick` / `showTitleBar` / `showTitleBarRightIcon` (all `BOOL`, default `YES`)
  - `titleBarRightRes` (`UIImage *`, nullable)
  - `titleBarRightClick` (`void(^)(ChatViewController *)`, nullable)
  - `chatTableViewBackgroundColor` (`UIColor *`, nullable)
  - `chatViewBackgroundSolid` (`BOOL`, default `NO`)

#### Scenario: messageProperties property on ChatUIConfig
- **WHEN** `ChatUIConfig.shared.messageProperties` is accessed
- **THEN** a `MessageProperties` instance is returned (initialized by default)
