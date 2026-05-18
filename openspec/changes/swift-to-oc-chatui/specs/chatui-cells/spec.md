# ChatUI Cells — Swift-to-OC Conversion Spec

> Source: `NEChatUIKit/Classes/Chat/View/Cell/` (including `CollectionCell/` and `PinCell/` subdirectories)

---

## ADDED Requirements

### Requirement: NEBaseChatMessageCell OC Conversion (Base Message Cell)

Convert `NEBaseChatMessageCell` (the core base cell for all chat message types), its delegate protocol, and the audio cell protocol.

#### Scenario: Protocol ChatBaseCellDelegate
- **WHEN** user interacts with a message cell
- **THEN** provide `@protocol ChatBaseCellDelegate <NSObject>` with required methods:
  - `- (void)didTapAvatarView:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didLongPressAvatar:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model replyModel:(MessageModel *)replyModel`
  - `- (void)didLongPressMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapResendView:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapReeditButton:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapReadView:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapSelectButton:(UITableViewCell *)cell model:(MessageContentModel *)model`
- **THEN** provide optional methods:
  - `- (void)didTextViewLoseFocus:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)messageWillShow:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)stopAIStreamMessage:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)regenAIStreamMessage:(UITableViewCell *)cell model:(MessageContentModel *)model`
  - `- (void)didTapDetectedLink:(UITableViewCell *)cell model:(MessageContentModel *)model url:(NSURL *)url`

#### Scenario: Protocol ChatAudioCellProtocol
- **WHEN** audio playback state needs tracking on a cell
- **THEN** provide `@protocol ChatAudioCellProtocol <NSObject>` with:
  - `@property (nonatomic, assign) BOOL isPlaying`
  - `@property (nonatomic, copy, nullable) NSString *messageId`
  - `- (void)startAnimationByRight:(BOOL)byRight`
  - `- (void)stopAnimationByRight:(BOOL)byRight`

#### Scenario: NEBaseChatMessageCell class declaration
- **WHEN** the OC base cell is defined
- **THEN** declare `@interface NEBaseChatMessageCell : NEChatBaseCell` inheriting from the base cell class
- **THEN** expose public properties (all with proper nullability):
  - `delegate` (weak, ChatBaseCellDelegate)
  - `contentModel` (MessageContentModel)
  - `singleLeft` (BOOL)
  - Left subviews: `userHeaderViewLeft` (NEUserHeaderView), `avatarImageLeftAnchor`, `bubbleImageLeft` (UIImageView), `bubbleTopAnchorLeft`, `bubbleWLeft`, `bubbleHLeft`, `pinImageLeft`, `pinLabelLeft`, `fullNameLabel`, `fullNameH`
  - Right subviews: `userHeaderViewRight`, `bubbleImageRight`, `bubbleWRight`, `bubbleHRight`, `pinImageRight`, `pinLabelRight`
  - Common: `readView` (CirleProgressView), `activityView` (ChatActivityIndicatorView), `activityViewCenterYAnchor`, `selectedButton` (UIButton), `selectedButtonCenterYAnchor`, `timeLabel`, `timeLabelHeightAnchor`
  - Constants: `messageTextFont` (UIFont), `messageMaxSize` (CGSize)

#### Scenario: NEBaseChatMessageCell key overridable methods
- **WHEN** subclasses customize cell layout or behavior
- **THEN** expose methods:
  - `- (void)setBubbleImage`
  - `- (void)initProperty`
  - `- (void)baseCommonUI` / `- (void)baseCommonUILeft` / `- (void)baseCommonUIRight`
  - `- (void)addGesture`
  - `- (void)initSubviewsLayout`
  - `- (void)tapAvatar:(UITapGestureRecognizer *)tap`
  - `- (void)tapMessage:(UITapGestureRecognizer *)tap`
  - `- (void)longPressAvatar:(UILongPressGestureRecognizer *)longPress`
  - `- (void)longPress:(UILongPressGestureRecognizer *)longPress`
  - `- (void)resend:(UIButton *)button`
  - `- (void)tapReadView:(UITapGestureRecognizer *)tap`
  - `- (void)selectButtonClicked`
  - `- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect`
  - `- (void)setModel:(MessageContentModel *)model` (override)
  - `- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend` (override)
  - `- (void)showLeftOrRight:(BOOL)showRight`
  - `- (void)resetSelectRange` / `- (void)selectAllRange`
  - `- (void)updatePinStatus:(MessageContentModel *)model isSend:(BOOL)isSend`

#### Scenario: Cell registration pattern
- **WHEN** registering cells with UITableView
- **THEN** use `NSStringFromClass([NEBaseChatMessageCell class])` as the reuse identifier (matching Swift `"\(NEBaseChatMessageCell.self)"` pattern)
- **THEN** subclass cells follow the same `NSStringFromClass` identifier convention

---

### Requirement: NEBaseChatMessageTipCell OC Conversion

Convert `NEBaseChatMessageTipCell` (system tip / notification cell).

#### Scenario: NEBaseChatMessageTipCell class
- **WHEN** displaying system notifications (join/leave, revoke, etc.)
- **THEN** declare `@interface NEBaseChatMessageTipCell : UITableViewCell` with:
  - `timeLabel` (UILabel), `contentLabel` (UILabel)
  - `timeLabelHeightAnchor`, `contentLabelCenterYAnchor` (NSLayoutConstraint)
  - `- (void)commonUI` (overridable)
  - `- (void)setModel:(MessageTipsModel *)model`

---

### Requirement: NEBaseChatTeamMemberCell OC Conversion

Convert `NEBaseChatTeamMemberCell` (used in @-mention user picker).

#### Scenario: NEBaseChatTeamMemberCell class
- **WHEN** displaying a team member row in the @-mention picker
- **THEN** declare `@interface NEBaseChatTeamMemberCell : UITableViewCell` with:
  - `headerView` (NEUserHeaderView), `nameLabel` (UILabel)
  - `- (void)setupUI` (overridable)
  - `- (void)configure:(NETeamMemberInfoModel *)model`

---

### Requirement: OperationCell OC Conversion

Convert `OperationCell` (UICollectionViewCell for long-press operation menu).

#### Scenario: OperationCell class
- **WHEN** displaying an operation item in the popup menu
- **THEN** declare `@interface OperationCell : UICollectionViewCell` with:
  - `imageView` (UIImageView), `label` (UILabel)
  - `model` (OperationItem, setter triggers UI update)
  - `- (void)commonUI` (overridable)

---

### Requirement: NEBaseLanguageCell OC Conversion

Convert `NEBaseLanguageCell` (CornerCell subclass for language selection).

#### Scenario: NEBaseLanguageCell class
- **WHEN** displaying a language option in the translate language picker
- **THEN** declare `@interface NEBaseLanguageCell : CornerCell` with:
  - `languageLabel` (UILabel), `selectedImageView` (UIImageView)
  - `- (void)setupLanguageCellUI` (overridable)
  - `- (void)configureData:(NElanguageCellModel *)model`

---

### Requirement: NEBaseUserSettingCell and Subclasses OC Conversion

Convert the user-setting cell hierarchy: `NEBaseUserSettingCell`, `NEBaseUserSettingSelectCell`, `NEBaseUserSettingSwitchCell`.

#### Scenario: NEBaseUserSettingCell class
- **WHEN** displaying a row in the user setting page
- **THEN** declare `@interface NEBaseUserSettingCell : CornerCell` with:
  - `model` (UserSettingCellModel), `titleLabel` (UILabel), `arrowImageView` (UIImageView)
  - `subCornerType` (CornerType, getter/setter)
  - `- (void)configure:(id)anyModel` (overridable)

#### Scenario: NEBaseUserSettingSelectCell class
- **WHEN** displaying a setting row with subtitle and arrow
- **THEN** declare `@interface NEBaseUserSettingSelectCell : NEBaseUserSettingCell` with:
  - `subTitleLabel` (UILabel)
  - `- (void)setupUI` (overridable)
  - Override `- (void)configure:(id)anyModel`

#### Scenario: NEBaseUserSettingSwitchCell class
- **WHEN** displaying a setting row with a toggle switch
- **THEN** declare `@interface NEBaseUserSettingSwitchCell : NEBaseUserSettingCell` with:
  - `tSwitch` (UISwitch)
  - `- (void)setupUI` (overridable)
  - `- (void)switchChange:(UISwitch *)s` (overridable)
  - Override `- (void)configure:(id)anyModel`

---

### Requirement: UserBaseTableViewCell OC Conversion

Convert `UserBaseTableViewCell` (read receipt user list cell).

#### Scenario: UserBaseTableViewCell class
- **WHEN** displaying a user in read/unread list
- **THEN** declare `@interface UserBaseTableViewCell : UITableViewCell` with:
  - `userHeaderView` (NEUserHeaderView), `titleLabel` (UILabel)
  - `userModel` (NETeamMemberInfoModel nullable)
  - `- (void)baseCommonUI` (overridable)
  - `- (void)setModel:(NETeamMemberInfoModel *)model` (overridable)

---

### Requirement: CollectionCell Subclasses OC Conversion

Convert the `CollectionCell/` subdirectory hierarchy: base class `NEBaseCollectionMessageCell` and type-specific subclasses.

#### Scenario: Protocol CollectionMessageCellDelegate
- **WHEN** user interacts with a collection message cell
- **THEN** provide `@protocol CollectionMessageCellDelegate <NSObject>`:
  - `- (void)didClickMore:(CollectionMessageModel *)model`
  - `- (void)didClickContent:(CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell`
  - Optional: `- (void)didTapDetectedLink:(CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell url:(NSURL *)url`

#### Scenario: NEBaseCollectionMessageCell class
- **WHEN** displaying a collected message
- **THEN** declare `@interface NEBaseCollectionMessageCell : UITableViewCell` with:
  - `contentWidth`, `contentHeight` (NSLayoutConstraint), `collectionModel`, `delegate` (weak), `contentGesture` (UITapGestureRecognizer)
  - `headerView` (NEUserHeaderView), `nameLabel`, `timeLabel`, `conversationLabel` (UILabel)
  - `moreImageView` (UIImageView), `backView`, `line` (UIView)
  - `- (void)setupCommonUI` (overridable)
  - `- (void)configureData:(CollectionMessageModel *)model` (overridable)
  - `- (void)contentClick` (overridable)
  - `- (void)setFunStyle` (overridable)

#### Scenario: Collection cell subclasses
- **WHEN** specific message types are collected
- **THEN** provide subclasses (each overrides `configureData:` and adds type-specific content subviews):
  - `NEBaseCollectionMessageTextCell` — text content label
  - `NEBaseCollectionMessageAudioCell` — audio playback UI
  - `NEBaseCollectionMessageImageCell` — image thumbnail
  - `NEBaseCollectionMessageVideoCell` — video thumbnail with play icon
  - `NEBaseCollectionMessageFileCell` — file icon and name
  - `NEBaseCollectionMessageLocationCell` — location preview
  - `NEBaseCollectionMessageMultiForwardCell` — multi-forward summary
  - `NEBaseCollectionMessageRichTextCell` — rich text (title + body)
  - `NEBaseCollectionDefaultCell` — fallback "unknown message" cell
  - `NEBaseCollectionMessageDefaultCell` — default collection cell

---

### Requirement: PinCell Subclasses OC Conversion

Convert the `PinCell/` subdirectory hierarchy: base class `NEBasePinMessageCell` and type-specific subclasses.

#### Scenario: Protocol PinMessageCellDelegate
- **WHEN** user interacts with a pinned message cell
- **THEN** provide `@protocol PinMessageCellDelegate <NSObject>`:
  - `- (void)didClickMore:(NEPinMessageModel *)model`
  - `- (void)didClickContent:(NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell`
  - Optional: `- (void)didTapDetectedLink:(NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell url:(NSURL *)url`

#### Scenario: NEBasePinMessageCell class
- **WHEN** displaying a pinned message
- **THEN** declare `@interface NEBasePinMessageCell : UITableViewCell` with:
  - `contentWidth`, `contentHeight` (NSLayoutConstraint), `pinModel`, `delegate` (weak), `contentGesture`
  - `headerView`, `nameLabel`, `timeLabel`, `backView`, `line`
  - `- (void)setupUI` (overridable)
  - `- (void)configure:(NEPinMessageModel *)item` (overridable)
  - `- (void)contentClick` (overridable)

#### Scenario: Pin cell subclasses
- **WHEN** specific message types are pinned
- **THEN** provide subclasses (each overrides `configure:` and adds type-specific content):
  - `NEBasePinMessageTextCell`
  - `NEBasePinMessageAudioCell`
  - `NEBasePinMessageImageCell`
  - `NEBasePinMessageVideoCell`
  - `NEBasePinMessageFileCell`
  - `NEBasePinMessageLocationCell`
  - `NEBasePinMessageMultiForwardCell`
  - `NEBasePinMessageRichTextCell`
  - `NEBasePinMessageDefaultCell`

---

### Requirement: Cell Registration Identifier Convention

All cells must follow a consistent registration identifier pattern.

#### Scenario: Reuse identifier generation
- **WHEN** registering any cell subclass with a UITableView or UICollectionView
- **THEN** use `NSStringFromClass([CellClass class])` as the reuse identifier
- **THEN** this matches the Swift convention of `"\(CellClass.self)"`

#### Scenario: Custom cell registration
- **WHEN** custom message types are registered via `NEChatUIKitClient.instance.getRegisterCustomCell()`
- **THEN** store them in `cellRegisterDic` (NSDictionary<NSString *, Class>) keyed by the message type rawValue string
- **THEN** iterate and register each with `[tableView registerClass:forCellReuseIdentifier:]`
