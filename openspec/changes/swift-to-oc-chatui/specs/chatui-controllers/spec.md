# ChatUI Controllers — Swift-to-OC Conversion Spec

> Source: `NEChatUIKit/Classes/Chat/Controller/`

---

## ADDED Requirements

### Requirement: ChatViewController OC Conversion (Primary Chat Controller)

Convert `ChatViewController` — the main chat page controller (~4400 lines). This is the most critical class.

#### Scenario: Class declaration and protocol conformance
- **WHEN** the OC class is defined
- **THEN** declare `@interface ChatViewController : NEChatBaseViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate, NIMMediaManagerDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, ChatInputViewDelegate, ChatInputMultilineDelegate, ChatViewModelDelegate, MessageOperationViewDelegate, NETranslateViewDelegate, SelectLanguageDelegate>`

#### Scenario: Key public properties
- **WHEN** the controller is used or subclassed
- **THEN** expose:
  - `titleContent` (NSString, with didSet updating title + online status)
  - `viewModel` (ChatViewModel)
  - `isCurrentPage` (BOOL), `isMute` (BOOL)
  - `operationCellFilter` (NSArray<NSNumber(OperationType)> nullable)
  - `cellRegisterDic` (NSMutableDictionary<NSString *, Class>)
  - `onReceiveNewMsgs`, `pendingNewMessages` (NSMutableArray<V2NIMMessage *>)
  - `normalOffset`, `bottomExanpndHeight`, `normalInputHeight`, `brokenNetworkViewHeight`, `currentKeyboardHeight` (CGFloat)
  - `bodyTopViewTopConstant`, `bodyTopViewHeight`, `bodyBottomViewHeight`, `bottomViewHeight` (CGFloat, with didSet updating constraints)
  - Layout constraints: `bodyTopViewTopAnchor`, `bodyTopViewHeightAnchor`, `bodyBottomViewHeightAnchor`, `contentViewTopAnchor`, `bottomViewTopAnchor`, `bottomViewHeightAnchor`, `translateLanguageViewHeightAnchor` (NSLayoutConstraint nullable)

#### Scenario: Key UI subviews
- **WHEN** building the view hierarchy
- **THEN** expose lazy-initialized views:
  - `bodyTopView`, `bodyView`, `bodyBottomView`, `bottomView`, `contentView` (UIView)
  - `brokenNetworkView` (NEBrokenNetworkView)
  - `tableView` (UITableView, with MJRefresh header)
  - `chatInputView` (NEBaseChatInputView)
  - `jumpDownView` (NEBaseChatNewMessageView), `jumpDownViewRightAncher` (NSLayoutConstraint)
  - `replyView` (ReplyView)
  - `mutilSelectBottomView` (NEMutilSelectBottomView)
  - `topMessageView` (TopMessageView)
  - `translateLanguageView` (NEAITranslateView)
  - `operationView` (MessageOperationView)

#### Scenario: Initialization
- **WHEN** creating the chat page
- **THEN** provide `- (instancetype)initWithConversationId:(NSString *)conversationId`
- **THEN** in init: create viewModel, disable NEKeyboardManager, call `addListener`

#### Scenario: Lifecycle methods
- **WHEN** the controller goes through its lifecycle
- **THEN** override and expose:
  - `viewDidLoad` — calls `commonUI`, `addObseve`, `getSessionInfo:completion:`, then `loadData`
  - `viewWillAppear:` — set `isCurrentPage = YES`, configure bodyTopViewTopConstant, start network detection
  - `viewWillDisappear:` — re-enable keyboard manager, stop playback, resign first responder, remove operation view
  - `viewDidDisappear:` — stop audio playback
  - `willMoveToParentViewController:` — if nil: clear @message remind, remove observers, remove listeners, clear unread

#### Scenario: Data loading methods
- **WHEN** messages need to be loaded
- **THEN** expose overridable methods:
  - `- (void)loadData` — calls `viewModel.loadData` with completion, handles anchor/scroll
  - `- (void)loadMoreData` — pull-down refresh via `viewModel.dropDownRemoteRefresh`
  - `- (void)loadCloserToNowData` — pull-up load more via `viewModel.pullRemoteRefresh`
  - `- (void)loadFartherToNowData` — placeholder for subclass
  - `- (void)loadDataFinish` — post-load hook (merge pendingNewMessages, show jump-down)

#### Scenario: Listener management
- **WHEN** adding/removing SDK listeners
- **THEN** expose:
  - `- (void)addListener` — adds NIMSDK mediaManager delegate, login listener
  - `- (void)removeListener` — removes all listeners, nils viewModel delegate

#### Scenario: Observer registration
- **WHEN** keyboard and app lifecycle events are observed
- **THEN** `- (void)addObseve` registers for:
  - `keyboardWillShow:` / `keyboardWillHide:`
  - `didEnterBackground` / `willEnterForeground`
  - `kCallKitShowNoti`, `didTapHeader`, `friendCacheInit`, `NEMarkdownImageDidLoadNotification`

#### Scenario: Keyboard handling
- **WHEN** keyboard appears/disappears
- **THEN** expose:
  - `- (void)keyBoardWillShow:(NSNotification *)notification`
  - `- (void)keyBoardWillHide:(NSNotification *)notification`
  - `- (void)layoutInputViewWithOffset:(CGFloat)offset` / `layoutInputViewWithAnimation:offset:duration:scrollToBottom:`

#### Scenario: ChatInputViewDelegate conformance
- **WHEN** user interacts with the input area
- **THEN** implement delegate methods:
  - `- (void)sendText:(NSString *)text attribute:(NSAttributedString *)attribute`
  - `- (void)sendContentText:(NSString *)text attribute:(NSAttributedString *)attribute`
  - `- (void)didSelectMoreCell:(NEInputMoreCell *)cell`
  - `- (BOOL)textChanged:(NSString *)text`
  - `- (BOOL)textDelete:(NSRange)range text:(NSString *)text`
  - `- (void)textViewDidChange`
  - `- (void)textFieldDidEndEditing:(NSString *)text`
  - `- (void)textFieldDidBeginEditing:(NSString *)text`
  - `- (void)textFieldDidChange:(NSString *)text`
  - `- (void)willSelectItem:(UIButton *)button index:(NSInteger)index`
  - `- (void)startRecord` / `- (void)moveOutView` / `- (void)moveInView` / `- (void)endRecord:(BOOL)insideView`
  - `- (void)titleTextDidClearEmpty`

#### Scenario: ChatInputMultilineDelegate conformance
- **WHEN** multiline/AI chat input events occur
- **THEN** implement:
  - `- (void)expandButtonDidClick`
  - `- (void)didHideMultipleButtonClick`
  - `- (void)aiChatButtonDidClick:(AIChatViewController *)vc open:(BOOL)open`
  - `- (void)aiChatMessageDidClick:(NSString *)text`

#### Scenario: ChatViewModelDelegate conformance
- **WHEN** viewModel notifies the controller of data changes
- **THEN** implement:
  - `- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs`
  - `- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index`
  - `- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index`
  - `- (void)onLoadMoreWithMessage:(NSArray<NSIndexPath *> *)indexs`
  - `- (void)onModefiedMessage:(NSIndexPath *)index`
  - `- (void)onDeleteMessage:(NSArray<V2NIMMessage *> *)messages deleteIndexs:(NSArray<NSIndexPath *> *)deleteIndexs reloadIndex:(NSArray<NSIndexPath *> *)reloadIndex`
  - `- (void)onResendSuccess:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndexPath`
  - `- (void)onRevokeMessage:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs`
  - `- (void)onMessageStatusChange:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs`
  - `- (void)selectedMessagesChanged:(NSInteger)count`
  - `- (void)sendMessageCallback:(V2NIMSendMessageResult *)result error:(V2NIMError *)error progress:(NSUInteger)progress`

#### Scenario: MessageOperationViewDelegate conformance
- **WHEN** user selects a long-press operation item
- **THEN** implement `- (void)didSelectedItem:(OperationItem *)item`
- **THEN** dispatch to operation methods: `copyMessage`, `deleteMessage`, `recallMessage`, `forwardMessage`, `pinMessage`, `removePinMessage`, `topMessage`, `toCollectMessage`, `voiceToText`, `untopMessage`, `selectMessage`, `setHandsetMode:`, `showReplyMessageView:`

#### Scenario: ChatBaseCellDelegate conformance
- **WHEN** cell interaction events are forwarded to the controller
- **THEN** implement:
  - `- (void)didTapAvatarView:model:` → calls `didTapHeadPortrait:`
  - `- (void)didLongPressAvatar:model:` → handles @mention insertion
  - `- (void)didTapMessageView:model:replyModel:` → calls `didTapMessage:model:replyIndex:`
  - `- (void)didLongPressMessageView:model:` → calls `didLongTouchMessageView:model:`
  - `- (void)didTapResendView:model:` → triggers resend confirmation
  - `- (void)didTapReeditButton:model:` → restores revoked message text to input
  - `- (void)didTapReadView:model:` → navigates to read receipt page
  - `- (void)didTapSelectButton:model:` → toggles selection in multi-select mode
  - `- (void)didTextViewLoseFocus:model:` / `messageWillShow:model:`
  - `- (void)stopAIStreamMessage:model:` / `regenAIStreamMessage:model:`
  - `- (void)didTapDetectedLink:model:url:` → opens web/tel/mailto

#### Scenario: TopMessageViewDelegate conformance
- **WHEN** user interacts with the pinned-message top bar
- **THEN** implement `- (void)didClickCloseButton` (untop) and `- (void)didTapTopMessageView` (scroll to pinned message)

#### Scenario: NETranslateViewDelegate conformance
- **WHEN** translation events occur
- **THEN** implement `didSwitchLanguageClick:`, `didCloseClick:`, `didChangeViewHeight:changeHeight:`, `didStartClick`, `didUseTranslate:`

#### Scenario: NEMutilSelectBottomViewDelegate conformance
- **WHEN** multi-select bottom buttons are tapped
- **THEN** implement `didClickSingleForwardButton`, `didClickMultiForwardButton`, `didClickDeleteButton`

#### Scenario: UITableView data source and delegate
- **WHEN** the message table view requires data
- **THEN** implement:
  - `numberOfRowsInSection:` — returns `viewModel.messages.count`
  - `cellForRowAt:` — resolves reuseId from `model.type.rawValue`, checks `cellRegisterDic`, dequeues cell, calls `setModel:isSend:`
  - `heightForRowAt:` — returns `model.cellHeight` (pre-computed)
  - `didSelectRowAt:` — handles multi-select toggle
  - `willDisplayCell:forRowAt:` — marks messages as read, triggers prefetch for history chat

#### Scenario: Key public action methods
- **WHEN** the controller performs major actions
- **THEN** expose overridable methods:
  - `- (void)commonUI` — builds the full view hierarchy
  - `- (void)toSetting` — navigates to team setting or user setting
  - `- (void)jumpDownMessage` — scrolls to bottom, clears new message indicator
  - `- (void)showJumpDownMessage:(NSInteger)messageCount`
  - `- (void)scrollTableViewToBottom`
  - `- (void)didTapHeadPortrait:(MessageContentModel *)model`
  - `- (void)didLongTouchMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)setOperationItems:(NSMutableArray<OperationItem *> *)items model:(MessageContentModel *)model`
  - `- (void)removeOperationView:(BOOL)cellEndEditing`
  - `- (void)onUserOrFriendInfoChanged:(NSString *)accountId`
  - `- (void)setTopValue:content:url:isVideo:hideClose:`
  - `- (void)updateTopName:(NSString *)name`
  - `- (void)markNeedReadMsg:(NSArray<V2NIMMessage *> *)messages`
  - `- (void)addToAtUsers:isReply:accid:isLongPress:`
  - `- (void)showUserSelectVC:(BOOL)showTeamMembers`

#### Scenario: Factory methods for subclass customization
- **WHEN** subclasses (Normal/Fun style) need to provide different UI
- **THEN** expose factory methods:
  - `- (NEBaseChatInputView *)getMenuView:(V2NIMConversationType)type`
  - `- (NEBaseChatNewMessageView *)getJumpDownView`
  - `- (NEBaseUserSettingViewController *)getUserSettingViewController`
  - `- (NEBaseForwardAlertViewController *)getForwardAlertController`
  - `- (NEBaseSelectUserViewController *)getUserSelectVC:(BOOL)showTeamMembers`
  - `- (NEBaseReadViewController *)getReadView:(V2NIMMessage *)message teamId:(NSString *)teamId`
  - `- (TextViewController *)getTextViewController:(NSString *)title body:(NSAttributedString *)body`
  - `- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)url filePath:(NSString *)filePath md5:(NSString *)md5`
  - `- (void)setMutilSelectBottomView`
  - `- (NSArray<NEMoreItemModel *> *)expandMoreAction`

#### Scenario: Table view helper methods
- **WHEN** the table view needs batch updates
- **THEN** expose:
  - `- (void)tableViewReload`
  - `- (void)tableViewReloadIndexs:(NSArray<NSIndexPath *> *)indexs completion:(void(^)(void))completion`
  - `- (void)tableViewDeleteIndexs:(NSArray<NSIndexPath *> *)indexs`
  - `- (void)insertRows:(NSArray<NSIndexPath *> *)indexs scrollToBottom:(BOOL)scrollToBottom`
  - `- (void)dataReload` — resets to latest messages (for history chat mode)

#### Scenario: Media message sending
- **WHEN** the user sends images, videos, or files
- **THEN** expose:
  - `- (void)sendMediaMessage:(NEResultModel *)imageModel isOriginal:(BOOL)isOriginal`
  - `- (void)sendMediaMessage:(NSDictionary *)info`
  - `- (void)cacheImageToSend:(UIImage *)image imageUrl:(NSURL *)url imageName:(NSString *)name`
  - `- (void)copyFileToSend:(NSURL *)url displayName:(NSString *)displayName filePath:(NSString *)filePath`

#### Scenario: Audio playback
- **WHEN** voice messages are played
- **THEN** expose:
  - `- (void)startPlaying:(V2NIMMessage *)audioMessage isSend:(BOOL)isSend`
  - `- (void)startPlay:(id<ChatAudioCellProtocol>)cell model:(MessageAudioModel *)model`
  - `- (void)stopPlay`

#### Scenario: Message tap handlers
- **WHEN** user taps different message types
- **THEN** expose type-specific tap methods:
  - `- (void)didTapMessage:(UITableViewCell *)cell model:(MessageContentModel *)model replyIndex:(NSInteger)replyIndex`
  - `- (void)didTapAudioMessage:model:` / `didTapImageMessage:replyIndex:` / `didTapVideoMessage:model:replyIndex:` / `didTapFileMessage:model:replyIndex:` / `didTapCallMessage:` / `didTapLocationMessage:` / `didTapCustomMessage:replyIndex:`
  - `- (void)downloadFile:model:url:path:`

#### Scenario: P2P editing status
- **WHEN** remote user typing indicators change
- **THEN** expose: `remoteUserEditing`, `remoteUserEndEditing`, `timeoutEndEditing`, `trigerEndTimer`, `remoteUserOnlineChanged`, `checkAndSendTypingState:`

---

### Requirement: MultiForwardViewController OC Conversion

Convert `MultiForwardViewController` (merged-forward message detail viewer).

#### Scenario: Class declaration
- **WHEN** the OC class is defined
- **THEN** declare `@interface MultiForwardViewController : NEChatBaseViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, ChatBaseCellDelegate, UIDocumentInteractionControllerDelegate, MultiForwardViewModelDelegate>`

#### Scenario: Key properties
- **WHEN** the controller is used
- **THEN** expose:
  - `viewModel` (MultiForwardViewModel)
  - `cellRegisterDic` (NSDictionary<NSString *, Class>)
  - `brokenNetworkViewHeight` (CGFloat)
  - `brokenNetworkView` (NEBrokenNetworkView), `tableView` (UITableView)

#### Scenario: Initialization and lifecycle
- **WHEN** creating the controller
- **THEN** provide `- (instancetype)initWithAttachmentUrl:(NSString *)url filePath:(NSString *)filePath md5:(NSString *)md5`
- **THEN** implement `viewDidLoad` → `commonUI` + `loadData`

#### Scenario: Key overridable methods
- **WHEN** subclasses customize behavior
- **THEN** expose: `commonUI`, `getMultiForwardViewController:filePath:md5:`, UITableView data source methods, `didTapMessageView:model:replyModel:`, `didTapMessage:model:replyIndex:`

---

### Requirement: NEBaseCollectionMessageController OC Conversion

Convert `NEBaseCollectionMessageController` (collected messages list).

#### Scenario: Class declaration
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseCollectionMessageController : NEChatBaseViewController <UITableViewDelegate, UITableViewDataSource, CollectionMessageCellDelegate, UIDocumentInteractionControllerDelegate>`

#### Scenario: Key properties and methods
- **WHEN** displaying collected messages
- **THEN** expose:
  - `contentTable` (UITableView), `collectionEmptyView`, `viewModel` (CollectionMessageViewModel)
  - `cellClassDic` (NSDictionary), `collection_content_maxW` (CGFloat)
  - `- (void)setupUI`, `- (NSDictionary *)getRegisterDic`
  - `- (void)loadMoreData`, `- (void)showActions:(CollectionMessageModel *)model`
  - `didClickMore:`, `didClickContent:cell:`, `didTapDetectedLink:cell:url:`

---

### Requirement: NEBasePinMessageViewController OC Conversion

Convert `NEBasePinMessageViewController` (pinned messages list).

#### Scenario: Class declaration
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBasePinMessageViewController : NEChatBaseViewController <UITableViewDataSource, UITableViewDelegate, PinMessageViewModelDelegate, PinMessageCellDelegate, UIDocumentInteractionControllerDelegate, NEIMKitClientListener, NEChatListener>`

#### Scenario: Key properties and methods
- **WHEN** displaying pinned messages
- **THEN** expose:
  - `viewModel` (PinMessageViewModel), `conversationId`, `onReceiveNewMsgs`
  - `cellClassDic`, `pin_content_maxW`, `tableView`
  - `- (instancetype)initWithConversationId:(NSString *)conversationId`
  - `- (void)setupUI`, `- (NSDictionary *)getRegisterCellDic`
  - `- (void)cancelPinActionClicked:(NEPinMessageModel *)item`
  - `- (void)showAction:(NEPinMessageModel *)item`
  - `- (void)tableViewReload:(BOOL)needLoad`
  - `didClickMore:`, `didClickContent:cell:`

---

### Requirement: NEBaseReadViewController OC Conversion

Convert `NEBaseReadViewController` (read receipt list with read/unread tabs).

#### Scenario: Class declaration and key elements
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseReadViewController : NEChatBaseViewController <UITableViewDelegate, UITableViewDataSource>`
- **THEN** expose:
  - `readButton`, `unreadButton` (UIButton), `bottonBottomLine`, `tabView` (UIView)
  - `readTableView`, `unreadTableView` (UITableView)
  - `- (instancetype)initWithMessage:(V2NIMMessage *)message teamId:(NSString *)teamId`
  - `- (void)commonUI`, `- (void)loadData`
  - `- (void)readButtonEvent:(UIButton *)button`, `- (void)unreadButtonEvent:(UIButton *)button`

---

### Requirement: NEBaseForwardAlertViewController OC Conversion

Convert `NEBaseForwardAlertViewController` (forward confirmation dialog) and `ForwardItem` model.

#### Scenario: ForwardItem model
- **WHEN** forward targets are specified
- **THEN** declare `@interface ForwardItem : NSObject` with `conversationId`, `name`, `avatar` (NSString nullable)

#### Scenario: NEBaseForwardAlertViewController class
- **WHEN** the forward confirmation alert is presented
- **THEN** declare `@interface NEBaseForwardAlertViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate>`
- **THEN** expose:
  - `cancelBlock`, `sureBlock` (ForwardCallBack)
  - `forwardSessions` (NSArray<ForwardItem *>), `forwardType`, `sessionName`, `senderName`
  - `sureButton`, `tipLabel`, `sessionCollectionView`, `contentView`, `oneSessionHeadView`, `oneSessionNameLabel`, `contentLabel`, `commentTextFeild`
  - `- (void)setupUI`, `- (void)setItems:(NSArray<ForwardItem *> *)items`

---

### Requirement: NEBaseSelectUserViewController OC Conversion

Convert `NEBaseSelectUserViewController` (@-mention user picker).

#### Scenario: Class declaration and key elements
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseSelectUserViewController : NEChatBaseViewController <UITableViewDelegate, UITableViewDataSource>`
- **THEN** expose:
  - `tableView`, `conversationId`, `viewModel` (TeamMemberSelectVM), `selectedBlock` (DidSelectedAtRow)
  - `- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers`

---

### Requirement: NEBaseUserSettingViewController OC Conversion

Convert `NEBaseUserSettingViewController` (P2P chat settings page).

#### Scenario: Class declaration and key elements
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseUserSettingViewController : NEChatBaseViewController <UITableViewDelegate, UITableViewDataSource, UserSettingViewModelDelegate>`
- **THEN** expose:
  - `userId`, `viewModel` (UserSettingViewModel)
  - `userHeaderView`, `addButton`, `nameLabel`
  - `contentTable` (UITableView), `cellClassDic`
  - `- (instancetype)initWithUserId:(NSString *)userId`
  - `- (void)setupUI`, `- (UIView *)headerView`, `- (void)didLoadData`
  - `- (void)createDiscuss`, `- (void)showUserInfo`
  - `- (NSArray<UIViewController *> *)filterStackViewController`
  - Delegate callbacks: `didNeedRefreshUI`, `didError:`, `didShowErrorMsg:`, `didClickMark`, `didClickHistory`

---

### Requirement: NEBaseSelectLanguageViewController OC Conversion

Convert `NEBaseSelectLanguageViewController` (translate language picker).

#### Scenario: Class declaration and key elements
- **WHEN** the OC class is defined
- **THEN** declare `@interface NEBaseSelectLanguageViewController : NEChatBaseViewController <UITableViewDelegate, UITableViewDataSource>`
- **THEN** expose:
  - `viewModel` (SelectLanguageViewModel), `delegate` (weak, SelectLanguageDelegate), `currentContent`
  - `languageTableView` (UITableView)
  - `- (void)setupLanguageUI`, `- (void)cancelClick`

#### Scenario: Protocol SelectLanguageDelegate
- **WHEN** a language is selected
- **THEN** provide `@protocol SelectLanguageDelegate <NSObject>`:
  - Optional: `- (void)didSelectLanguage:(NSString *)language controller:(UIViewController *)controller`

---

### Requirement: TextViewController OC Conversion

Convert `TextViewController` (full-screen rich text viewer).

#### Scenario: Class declaration and key elements
- **WHEN** the OC class is defined
- **THEN** declare `@interface TextViewController : NEChatBaseViewController <LinkableLabelProtocol>`
- **THEN** expose:
  - `scrollView` (UIScrollView), `textView` (UIView), `titleLabel`, `bodyLabel` (CopyableLabel)
  - `- (instancetype)initWithTitle:(NSString *)title body:(NSAttributedString *)body`
  - `- (void)setupUI`, `- (void)updateLinkDetection`, `- (void)didTapLink:(NSURL *)url`

---

### Requirement: CustomPresentationController OC Conversion

Convert `CustomPresentationController` (custom modal presentation with dimming).

#### Scenario: CustomPresentationController class
- **WHEN** the forward alert or similar modal is presented
- **THEN** declare `@interface CustomPresentationController : UIPresentationController` with:
  - Overrides: `frameOfPresentedViewInContainerView`, `presentationTransitionWillBegin`, `dismissalTransitionWillBegin`, `containerViewWillLayoutSubviews`, `sizeForChildContentContainer:withParentContainerSize:`
