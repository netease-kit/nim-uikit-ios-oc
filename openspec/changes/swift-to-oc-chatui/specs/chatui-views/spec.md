# ChatUI Views — Swift-to-OC Conversion Spec

> Source: `NEChatUIKit/Classes/Chat/View/ChatView/`

---

## ADDED Requirements

### Requirement: NEBaseChatInputView OC Conversion

Convert `NEBaseChatInputView` (open class, UIView subclass) and its associated enums/protocols to Objective-C.

#### Scenario: Enum ChatMenuType
- **WHEN** the input view needs to track the current menu panel type
- **THEN** provide `typedef NS_ENUM(NSInteger, ChatMenuType)` with values `ChatMenuTypeText = 0`, `ChatMenuTypeAudio`, `ChatMenuTypeEmoji`, `ChatMenuTypeImage`, `ChatMenuTypeAddMore`

#### Scenario: Enum ChatInputMode
- **WHEN** the input view needs to track multi-line vs normal mode
- **THEN** provide `typedef NS_ENUM(NSInteger, ChatInputMode)` with values `ChatInputModeNormal`, `ChatInputModeMultipleSend`, `ChatInputModeMultipleReturn`

#### Scenario: Protocol ChatInputMultilineDelegate
- **WHEN** multiline expand/collapse or AI chat events occur
- **THEN** provide `@protocol ChatInputMultilineDelegate <NSObject>` declaring:
  - `- (void)expandButtonDidClick`
  - `- (void)didHideMultipleButtonClick`
  - `- (void)aiChatButtonDidClick:(AIChatViewController *)vc open:(BOOL)open`
  - `- (void)aiChatMessageDidClick:(NSString *)text`

#### Scenario: NEBaseChatInputView class declaration
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseChatInputView : UIView <ChatRecordViewDelegate, InputEmoticonContainerViewDelegate, UITextViewDelegate, NEMoreViewDelegate, UITextFieldDelegate>`
- **THEN** expose public properties: `multipleLineDelegate` (weak), `delegate` (weak, ChatInputViewDelegate), `currentType` (ChatMenuType), `currentButton` (UIButton nullable), `menuHeight`, `contentHeight`, `atRangeCache`, `nickAccidList`, `nickAccidDic`, `chatInpuMode`, `conversationType`, `textLimit`, `textView` (NETextView), `expandButton` (ExpandButton nullable), `aiChatButton` (ExpandButton nullable), `stackView` (UIStackView), `contentSubView`, `greyView`, `recordView`, `textInput`, `multipleLineView`, `titleField`, `multipleLineExpandButton`, `multipleSendButton`, `emojiView`, `chatAddMoreView`, `aiChatViewController`, `multipleLineViewHeight` (NSLayoutConstraint nullable)

#### Scenario: NEBaseChatInputView key methods
- **WHEN** subclasses or controllers interact with the input view
- **THEN** expose overridable methods:
  - `- (instancetype)initWithConversationType:(V2NIMConversationType)type`
  - `- (void)commonUI`
  - `- (void)addRecordView` / `- (void)addEmojiView` / `- (void)addMoreActionView`
  - `- (void)sendText`
  - `- (void)buttonEvent:(UIButton *)button`
  - `- (void)lineBreakAction`
  - `- (void)selectedEmoticon:(NSString *)emoticonID emotCatalogID:(NSString *)catalogID description:(NSString *)desc`
  - `- (void)didPressSend:(UIButton *)sender`
  - `- (void)stopRecordAnimation`
  - `- (nullable NSString *)getRemoteExtension:(NSAttributedString *)attri` / `getAtRemoteExtension:`
  - `- (void)clearAtCache`
  - `- (void)didClickExpandButton` / `- (void)didClickAIChatButton`
  - `- (void)showAIChatView` / `- (void)hideAIChatView`
  - `- (void)setLayerContents:(BOOL)open`
  - `- (void)restoreNormalInputStyle` / `- (void)changeToMultipleLineStyle`
  - `- (void)setMuteInputStyle` / `- (void)setUnMuteInputStyle`
  - `- (void)setupMultipleLineView`

---

### Requirement: ChatRecordView OC Conversion

Convert `ChatRecordView` (open class, UIView subclass) and its delegate protocol.

#### Scenario: Protocol ChatRecordViewDelegate
- **WHEN** recording gesture events occur
- **THEN** provide `@protocol ChatRecordViewDelegate <NSObject>` with methods:
  - `- (void)startRecord`
  - `- (void)moveOutView`
  - `- (void)moveInView`
  - `- (void)endRecordInsideView:(BOOL)insideView`

#### Scenario: ChatRecordView class
- **WHEN** the view is instantiated
- **THEN** declare `@interface ChatRecordView : UIView <UIGestureRecognizerDelegate>` with:
  - Property `delegate` (weak, ChatRecordViewDelegate)
  - Internal subviews: `recordImageView` (UIImageView), `topTipLabel` (UILabel), `tipLabel` (UILabel)
  - Methods: `- (void)stopRecordAnimation`, `- (void)startRecord`, `- (void)endRecordWithRecognizer:(UILongPressGestureRecognizer *)recognizer`

---

### Requirement: ReplyView OC Conversion

Convert `ReplyView` (open class, UIView subclass).

#### Scenario: ReplyView class
- **WHEN** a reply-to-message bar is shown above the input area
- **THEN** declare `@interface ReplyView : UIView` with:
  - `closeButton` (UIButton)
  - `line` (UIView)
  - `textLabel` (UILabel)

---

### Requirement: TopMessageView OC Conversion

Convert `TopMessageView` and its delegate.

#### Scenario: Protocol TopMessageViewDelegate
- **WHEN** user interacts with the top-pinned message bar
- **THEN** provide `@protocol TopMessageViewDelegate <NSObject>`:
  - `- (void)didClickCloseButton`
  - `- (void)didTapTopMessageView`

#### Scenario: TopMessageView class
- **WHEN** the view is instantiated
- **THEN** declare `@interface TopMessageView : UIView` with properties:
  - `delegate` (weak), `topImageView`, `thumbImageView`, `playIcon`, `topContentLabel`, `closeButton`
- **THEN** expose methods:
  - `- (void)setTopContentWithName:(NSString *)name content:(NSString *)content url:(NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose`
  - `- (void)updateTopName:(NSString *)name`

---

### Requirement: MessageOperationView OC Conversion

Convert `MessageOperationView` (UIView, UICollectionView-based popup).

#### Scenario: Protocol MessageOperationViewDelegate
- **WHEN** user taps an operation item
- **THEN** provide `@protocol MessageOperationViewDelegate <NSObject>`:
  - `- (void)didSelectedItem:(OperationItem *)item`

#### Scenario: MessageOperationView class
- **WHEN** a long-press menu is shown
- **THEN** declare `@interface MessageOperationView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>` with:
  - `delegate` (weak), `items` (NSArray<OperationItem *>), `collcetionView` (UICollectionView)
  - UICollectionViewDataSource/Delegate methods as overridable

---

### Requirement: NEAITranslateView OC Conversion

Convert `NEAITranslateView` and associated `TranslateState` enum.

#### Scenario: Enum TranslateState
- **WHEN** tracking translation lifecycle
- **THEN** provide `typedef NS_ENUM(NSInteger, TranslateState)` with `TranslateStateIdle`, `TranslateStateTranslating`, `TranslateStateUse`

#### Scenario: Protocol NETranslateViewDelegate
- **WHEN** translation events occur
- **THEN** provide `@protocol NETranslateViewDelegate <NSObject>`:
  - Required: `- (void)didSwitchLanguageClick:(NSString *)currentLanguage`, `- (void)didCloseClick:(NEAITranslateView *)view`
  - Optional: `- (void)didChangeViewHeight:(NEAITranslateView *)view changeHeight:(CGFloat)height`, `- (void)didStartClick`, `- (void)didUseTranslate:(NSString *)content`

#### Scenario: NEAITranslateView class
- **WHEN** the view is instantiated
- **THEN** declare `@interface NEAITranslateView : UIView <NEGrowingTextViewDelegate>` with:
  - Properties: `delegate`, `chatInputText`, `currentLanguage`, `translateState`, `shortLanguageLabel`, `shortLanguageBgView`, `switchLanguageButton`, `closeButton`, `closeImageView`, `separatorLine`, `statusLabel`, `loadingImageView`, `showTranslateContentText`, `loadingAnimationView`, `startButton`
  - Methods: `- (void)setupTranslateLanguageUI`, `- (CGFloat)getCurrentHeight`, `- (void)setTranslateContent:(NSString *)content`, `- (void)changeToIdleState:(BOOL)isClearText`, `- (void)changeToTranslatingState`, `- (void)changeToUseState`

---

### Requirement: NEChatTextView OC Conversion

Convert `NEChatTextView` (UITextView subclass that disables scroll indicators and text actions).

#### Scenario: NEChatTextView class
- **WHEN** a read-only chat text view is needed
- **THEN** declare `@interface NEChatTextView : UITextView`
- **THEN** override `layoutSubviews`, `addSubview:`, `canPerformAction:withSender:` (returns NO), `shouldChangeTextInRange:replacementText:` (returns NO)

---

### Requirement: ChatNavigationView OC Conversion

Convert `ChatNavigationView` (NENavigationView subclass with earpiece indicator).

#### Scenario: ChatNavigationView class
- **WHEN** the chat navigation bar is displayed
- **THEN** declare `@interface ChatNavigationView : NENavigationView` with:
  - `earImageView` (UIImageView, hidden by default)
  - `- (void)setupUI` (override)
  - `- (void)setHandsetMode:(BOOL)ear`

---

### Requirement: NEMutilSelectBottomView OC Conversion

Convert `NEMutilSelectBottomView` and its delegate.

#### Scenario: Protocol NEMutilSelectBottomViewDelegate
- **WHEN** user taps multi-select action buttons
- **THEN** provide `@protocol NEMutilSelectBottomViewDelegate <NSObject>`:
  - `- (void)didClickSingleForwardButton`
  - `- (void)didClickMultiForwardButton`
  - `- (void)didClickDeleteButton`

#### Scenario: NEMutilSelectBottomView class
- **WHEN** multi-select mode is active
- **THEN** declare `@interface NEMutilSelectBottomView : UIView` with:
  - `delegate` (weak), `buttonTopAnchor` (NSLayoutConstraint nullable)
  - `singleForwardButton`, `multiForwardButton`, `deleteButton` (UIButton)
  - `singleForwardLabel`, `multiForwardLabel`, `deleteLabel` (UILabel)
  - `- (void)setupSubview` (overridable)
  - `- (void)setEnable:(BOOL)enable` / `- (void)setLabelColor:(UIColor *)color`

---

### Requirement: CirleProgressView OC Conversion

Convert `CirleProgressView` (read/unread circle progress indicator).

#### Scenario: CirleProgressView class
- **WHEN** showing read receipt progress (0~1 float)
- **THEN** declare `@interface CirleProgressView : UIView` with:
  - `progress` (float, 0~1, triggers redraw)
  - `borderLayer`, `sectorLayer` (CAShapeLayer)
  - `- (void)drawCircleWithProgress:(float)progress`

---

### Requirement: ChatActivityIndicatorView OC Conversion

Convert `ChatActivityIndicatorView` and `ChatSendMessageStatus` enum.

#### Scenario: Enum ChatSendMessageStatus
- **WHEN** displaying message send state
- **THEN** provide `typedef NS_ENUM(NSInteger, ChatSendMessageStatus)` with `ChatSendMessageStatusSuccessed = 0`, `ChatSendMessageStatusSending`, `ChatSendMessageStatusFailed`, `ChatSendMessageStatusSendingFailed`

#### Scenario: ChatActivityIndicatorView class
- **WHEN** cell shows sending/failed state
- **THEN** declare `@interface ChatActivityIndicatorView : UIView` with:
  - `messageStatus` (ChatSendMessageStatus, triggers UI update)
  - `failButton` (UIButton)

---

### Requirement: ChatBrokenNetworkView OC Conversion

Convert `ChatBrokenNetworkView` (network error banner).

#### Scenario: ChatBrokenNetworkView class
- **WHEN** network is disconnected
- **THEN** declare `@interface ChatBrokenNetworkView : UIView` with:
  - `contentLabel` (UILabel, displays "network_error" localized text)

---

### Requirement: NEBaseChatNewMessageView OC Conversion

Convert `NEBaseChatNewMessageView` (jump-to-new-message floating button).

#### Scenario: NEBaseChatNewMessageView class
- **WHEN** new messages arrive while user is scrolled up
- **THEN** declare `@interface NEBaseChatNewMessageView : UIView` with:
  - `jumpDownImageView` (UIImageView), `messageCountLabel` (UILabel)
  - `messageCountLabelRightAnchor` (NSLayoutConstraint nullable)
  - `- (void)setupUI` (overridable)
  - `- (void)updateMessageCount:(NSInteger)count`

---

### Requirement: NEChatMoreActionView OC Conversion

Convert `NEChatMoreActionView` (more-action panel with paginated collection view).

#### Scenario: Protocol NEMoreViewDelegate
- **WHEN** user taps an action cell in the more panel
- **THEN** provide `@protocol NEMoreViewDelegate <NSObject>`:
  - `- (void)moreViewDidSelectMoreCell:(NEChatMoreActionView *)moreView cell:(NEInputMoreCell *)cell`

#### Scenario: NEChatMoreActionView class
- **WHEN** the more action panel is displayed
- **THEN** declare `@interface NEChatMoreActionView : UIView <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>` with:
  - `delegate` (weak, NEMoreViewDelegate), `moreFlowLayout` (UICollectionViewFlowLayout nullable)
  - `collcetionView` (UICollectionView)
  - `- (void)configData:(NSArray<NEMoreItemModel *> *)data`

---

### Requirement: NEInputMoreCell OC Conversion

Convert `NEInputMoreCell` (UICollectionViewCell for more action items).

#### Scenario: NEInputMoreCell class
- **WHEN** each action item cell is displayed in the more panel
- **THEN** declare `@interface NEInputMoreCell : UICollectionViewCell` with:
  - `cellData` (NEMoreItemModel nullable)
  - `avatarImageView` (UIImageView), `titleLabel` (UILabel)
  - `- (void)configWithModel:(NEMoreItemModel *)itemModel`
  - `+ (CGSize)getSize`
