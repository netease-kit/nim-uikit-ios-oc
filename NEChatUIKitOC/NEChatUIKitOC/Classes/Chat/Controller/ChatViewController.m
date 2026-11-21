// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "ChatViewController.h"
#import "../View/ChatView/NEBaseChatLastReadPositionView.h"
#import "UIImage+Chat.h"
#import <AVFoundation/AVFoundation.h>
#import <MJRefresh/MJRefresh.h>
#import <Photos/Photos.h>
#import <NEChatKit/NEChatKit.h>

#import <NEChatKit/NEALog.h>

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NECustomUtils.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/NEPathUtils.h>
#import <NIMSDK/NIMSDK.h>
#import <objc/runtime.h>
#import "NEChatUIConstant.h"
#import "ChatCellConstantValue.h"
#import "NEChatViewport.h"
#import "MessageContentModel.h"
#import "ChatDeduplicationHelper.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import "MessageUtils.h"
#import "NETeamUserManager.h"
#import "NEP2PChatUserCache.h"
#import "NEAudioSessionManager.h"
#import "ReplyMessageUtil.h"
#import "NEEmotionTool.h"
#import "NIMInputSticker.h"
#import "NEBaseChatMessageCell.h"
#import "NEChatUIKitClient.h"
#import "NEInputMoreCell.h"
#import "MessageTextModel.h"
#import "OperationItem+NEChatUIKit.h"
#import "MessageRichTextModel.h"
#import "MessageAIStreamModel.h"
#import "NEMarkdownParser.h"
#import "NEBaseForwardAlertViewController.h"
#import "NEBaseReadViewController.h"
#import "NEBaseSelectUserViewController.h"
#import "NEBaseChatMessageTipCell.h"
#import "P2PChatViewModel.h"
#import "AIChatViewController.h"
#import "CustomPresentationController.h"
#import "TextViewController.h"
#import "MultiForwardViewController.h"
#import <NEBaseUIKitOC/VideoPlayerViewController.h>
#import "UserSettingViewController.h"
#import "ReadViewController.h"

static NSString *const kClassTag = @"ChatViewController";
static NSString *const kCallKitDismissNoti = @"kCallKitDismissNoti";
static NSString *const kCallKitShowNoti = @"kCallKitShowNoti";
static NSString * const NEChatContactUserInfoPageRouter = @"imkit://contact/userInfo.page";
static NSString * const NEChatMeSettingRouter = @"imkit://mine/userInfo.page";
static NSString * const NEChatTeamSettingViewRouter = @"imkit://team/teamSetting.page";
static NSString * const NEChatCallViewRouter = @"imkit://callkit.page";
static NSString * const NEChatForwardMultiSelectedRouter = @"imkit://contact/tab/selector.result";
static NSString * const NEChatForwardMultiSelectRouter = @"imkit://contact/tab/selector.page";
static NSInteger const NEChatImageCountLimit = 9;
static NSInteger const NEChatVideoCountLimit = 1;

static Class NEChatResolveTableViewCellClass(id cellValue) {
  Class cellClass = Nil;
  if ([cellValue isKindOfClass:[NSString class]]) {
    cellClass = NSClassFromString((NSString *)cellValue);
  } else if (cellValue && object_isClass(cellValue)) {
    cellClass = (Class)cellValue;
  }

  if (cellClass && [cellClass isSubclassOfClass:[UITableViewCell class]]) {
    return cellClass;
  }
  return Nil;
}

static NSArray<NSString *> *NEChatMessageUniqueKeys(V2NIMMessage *message) {
  if (![message isKindOfClass:[V2NIMMessage class]]) {
    return nil;
  }
  NSMutableArray<NSString *> *keys = [NSMutableArray array];
  if (message.messageClientId.length > 0) {
    [keys addObject:[@"client:" stringByAppendingString:message.messageClientId]];
  }
  if (message.messageServerId.length > 0 && ![message.messageServerId isEqualToString:@"0"]) {
    [keys addObject:[@"server:" stringByAppendingString:message.messageServerId]];
  }
  return keys.count > 0 ? [keys copy] : nil;
}

static BOOL NEChatMessageIsSame(V2NIMMessage *lhs, V2NIMMessage *rhs) {
  if (lhs == rhs) {
    return YES;
  }
  NSArray<NSString *> *lhsKeys = NEChatMessageUniqueKeys(lhs);
  NSArray<NSString *> *rhsKeys = NEChatMessageUniqueKeys(rhs);
  if (lhsKeys.count == 0 || rhsKeys.count == 0) {
    return NO;
  }

  NSSet<NSString *> *lhsKeySet = [NSSet setWithArray:lhsKeys];
  for (NSString *key in rhsKeys) {
    if ([lhsKeySet containsObject:key]) {
      return YES;
    }
  }
  return NO;
}

static void NEChatAppendUniqueMessages(NSMutableArray<V2NIMMessage *> *target, NSArray<V2NIMMessage *> *messages) {
  if (![target isKindOfClass:[NSMutableArray class]] || ![messages isKindOfClass:[NSArray class]]) {
    return;
  }
  for (V2NIMMessage *message in messages) {
    if (![message isKindOfClass:[V2NIMMessage class]]) {
      continue;
    }
    BOOL duplicated = NO;
    for (V2NIMMessage *existingMessage in target) {
      if (NEChatMessageIsSame(existingMessage, message)) {
        duplicated = YES;
        break;
      }
    }
    if (!duplicated) {
      [target addObject:message];
    }
  }
}

static void NEChatDeduplicateMessages(NSMutableArray<V2NIMMessage *> *messages) {
  if (![messages isKindOfClass:[NSMutableArray class]] || messages.count <= 1) {
    return;
  }
  NSMutableArray<V2NIMMessage *> *uniqueMessages = [NSMutableArray array];
  for (V2NIMMessage *message in [messages copy]) {
    if (![message isKindOfClass:[V2NIMMessage class]]) {
      continue;
    }
    BOOL duplicated = NO;
    for (V2NIMMessage *existingMessage in uniqueMessages) {
      if (NEChatMessageIsSame(existingMessage, message)) {
        duplicated = YES;
        break;
      }
    }
    if (!duplicated) {
      [uniqueMessages addObject:message];
    }
  }
  if (uniqueMessages.count != messages.count) {
    [messages removeAllObjects];
    [messages addObjectsFromArray:uniqueMessages];
  }
}

static void NEChatRetainMessagesAfterAnchor(NSMutableArray<V2NIMMessage *> *messages,
                                            V2NIMMessage *anchor) {
  if (![messages isKindOfClass:[NSMutableArray class]]) {
    return;
  }
  if (anchor) {
    [messages filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(V2NIMMessage *message,
                                                                         NSDictionary *bindings) {
      return [message isKindOfClass:[V2NIMMessage class]] &&
          [message.conversationId isEqualToString:anchor.conversationId] &&
          message.createTime > anchor.createTime;
    }]];
  }
  NEChatDeduplicateMessages(messages);
}

static NSArray<NSIndexPath *> *NEChatUniqueIndexPaths(NSArray<NSIndexPath *> *indexPaths) {
  if (indexPaths.count == 0) {
    return @[];
  }

  NSMutableSet<NSString *> *seen = [NSMutableSet set];
  NSMutableArray<NSIndexPath *> *result = [NSMutableArray array];
  for (NSIndexPath *indexPath in indexPaths) {
    if (![indexPath isKindOfClass:[NSIndexPath class]]) {
      continue;
    }
    NSString *key = [NSString stringWithFormat:@"%ld-%ld", (long)indexPath.section, (long)indexPath.row];
    if ([seen containsObject:key]) {
      continue;
    }
    [seen addObject:key];
    [result addObject:indexPath];
  }
  [result sortUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
    if (obj1.section != obj2.section) {
      return obj1.section < obj2.section ? NSOrderedAscending : NSOrderedDescending;
    }
    if (obj1.row == obj2.row) {
      return NSOrderedSame;
    }
    return obj1.row < obj2.row ? NSOrderedAscending : NSOrderedDescending;
  }];
  return [result copy];
}

static NSInteger NEChatDataSourceRowCount(UITableView *tableView, NSInteger fallback) {
  id<UITableViewDataSource> dataSource = tableView.dataSource;
  if (!dataSource) {
    return fallback;
  }
  return [dataSource tableView:tableView numberOfRowsInSection:0];
}

static const NSInteger NEChatInitialScrollToBottomMaxRetryCount = 12;
static const NSTimeInterval NEChatInitialScrollToBottomRetryInterval = 0.05;

static NSArray<NSNumber *> *NEChatReactionPanelQuickIndexes(void) {
  return @[@3, @5, @1, @21, @65, @19, @20];
}

static CGFloat NEChatOperationMenuWidth(NSUInteger itemCount) {
  NSUInteger count = MIN(MAX(itemCount, 1), 5);
  return (CGFloat)count * 54.0 + 8.0;
}

static NSString *NEChatReactionErrorMessage(NSInteger code) {
  return code == 107321 ? @"已达 100 种表情上限" : @"表情评论失败";
}

static BOOL NEChatSupportsReactionConversation(NSString *conversationId) {
  V2NIMConversationType type = [V2NIMConversationIdUtil conversationType:conversationId];
  if (type == V2NIMConversationTypeP2P || type == V2NIMConversationTypeTeam) return YES;
  NSString *prefix = [[conversationId componentsSeparatedByString:@"|"] firstObject].lowercaseString;
  return [prefix isEqualToString:@"p2p"] || [prefix isEqualToString:@"team"];
}

static NSInteger NEChatIndexOfMessageInModels(V2NIMMessage *message, NSArray<id<MessageModel> > *models) {
  if (!message || ![models isKindOfClass:[NSArray class]]) {
    return NSNotFound;
  }
  for (NSInteger i = 0; i < (NSInteger)models.count; i++) {
    id<MessageModel> model = models[i];
    if (NEChatMessageIsSame(model.message, message)) {
      return i;
    }
  }
  return NSNotFound;
}

@interface ChatViewController () <UIGestureRecognizerDelegate>

/// 当前详情内容宽度对应的消息展示几何；详情列宽变化时下发到所有消息模型。
@property (nonatomic, strong, nullable) NEChatViewport *chatViewport;
/// 纯宽度重排的 reload 期间，屏蔽 willDisplay / messageWillShow 触发的
@property (nonatomic, assign) BOOL isUpdatingViewport;
@property (nonatomic, assign) CGRect keyboardFrameInScreen;
@property (nonatomic, assign) BOOL hasKeyboardFrameInScreen;

@property (nonatomic, strong) NSMutableSet<NSString *> *registeredCellReuseIds;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, weak) id<ChatAudioCellProtocol> playingCell;
@property (nonatomic, strong, nullable) MessageAudioModel *playingModel;
@property (nonatomic, weak, nullable) NEBaseChatMessageCell *anchorCell;
@property (nonatomic, strong, nullable) MessageVideoModel *anchorModel;
@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic, strong, nullable) NSNumber *isFile;
@property (nonatomic, assign) BOOL isMutilSelect;
@property (nonatomic, assign) BOOL wasCloseToBottomBeforeMutilSelect;
@property (nonatomic, assign) BOOL isLoadingData;
@property (nonatomic, assign) NSInteger loadDataRequestId;
@property (nonatomic, assign) BOOL hasFirstLoadData;
@property (nonatomic, assign) BOOL needCheckJumpDownAfterReload;
@property (nonatomic, assign) BOOL needScrollToBottomAfterReload;
@property (nonatomic, assign) NSInteger scrollToBottomAfterReloadRemainingCount;
@property (nonatomic, assign) BOOL isSchedulingScrollToBottomAfterReload;
@property (nonatomic, assign) BOOL suppressHistoryAutoLoadUntilUserScroll;
@property (nonatomic, assign) BOOL uploadHasNoMore;
@property (nonatomic, assign) BOOL networkBroken;
@property (nonatomic, strong) NSMutableArray<V2NIMMessage *> *needMarkReadMsgs;
@property (nonatomic, strong) NSMutableArray<NSValue *> *atUsersInternal;
@property (nonatomic, assign) BOOL restoringMentionInput;
@property (nonatomic, weak, nullable) NEBaseSelectLanguageViewController *languagePanelOverlay;
@property (nonatomic, weak, nullable) UIView *languagePanelDimmingView;
@property (nonatomic, assign) BOOL isRecvRolling;
@property (nonatomic, assign) NSInteger lastReadPositionRequestId;
@property (nonatomic, strong, nullable) V2NIMMessage *messageIndicatorCutoffAnchor;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *pendingReactionReloadIndexPaths;
@property (nonatomic, assign) BOOL isReactionReloadScheduled;
@property (nonatomic, assign) BOOL isReactionReloadInProgress;
@property (nonatomic, assign) BOOL keepsBottomPinnedForPendingReactionUpdates;
@property (nonatomic, assign) BOOL keepsBottomPinnedForInitialMessageDetails;

- (CGFloat)keyboardOverlap:(CGRect)frame;
- (void)keyboardFrameWillChange:(NSNotification *)notification;
- (void)startScrollToBottomAfterReload;
- (void)cancelScrollToBottomAfterReload;
- (void)scheduleScrollToBottomAfterReload;
- (void)performScrollToBottomAfterReload;
- (BOOL)scrollToAnchorMessage:(nullable V2NIMMessage *)message requestId:(NSInteger)requestId;
- (void)reloadSendMessage:(nullable V2NIMMessage *)message fallbackIndex:(nullable NSIndexPath *)index retry:(BOOL)retry;
- (void)reloadTableViewAfterRowCountMismatchScrollToBottom:(BOOL)scrollToBottom;
- (void)showJumpDownViewAfterLayout;
- (BOOL)isLastMessageVisible;
- (BOOL)isLatestPendingNewMessageVisible;
- (void)refreshLastReadPositionVisibility;
- (void)finishLastReadPositionScrollToMessage:(V2NIMMessage *)message requestId:(NSInteger)requestId;
- (void)loadLastReadPositionAroundMessage:(V2NIMMessage *)message requestId:(NSInteger)requestId;
- (BOOL)isLastReadPositionMessageVisible:(V2NIMMessage *)message;
- (void)scheduleReactionReloadIfNeeded;
- (void)flushPendingReactionReloads;
- (void)finishPendingReactionReloads;
- (void)cancelPendingReactionBottomPinning;

@end

@implementation ChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = [[ChatViewModel alloc] initWithConversationId:conversationId];
    _cellRegisterDic = [NSMutableDictionary dictionary];
    _onReceiveNewMsgs = [NSMutableArray array];
    _pendingNewMessages = [NSMutableArray array];
    _needMarkReadMsgs = [NSMutableArray array];
    _pendingReactionReloadIndexPaths = [NSMutableSet set];
    _normalInputHeight = 100;
    _bottomExanpndHeight = 204;
    _brokenNetworkViewHeight = 36;
    _bottomViewHeight = 404;
    _isCurrentPage = YES;
    [self updateKeyboardManagerEnabled:NO shouldResignOnTouchOutside:NO enableAutoToolbar:NO];
    [self addListener];
  }
  return self;
}

- (void)updateKeyboardManagerEnabled:(BOOL)enabled
         shouldResignOnTouchOutside:(BOOL)shouldResignOnTouchOutside
                   enableAutoToolbar:(BOOL)enableAutoToolbar {
  NEKeyboardManager *manager = [NEKeyboardManager shared];
  manager.enable = enabled;
  manager.shouldResignOnTouchOutside = shouldResignOnTouchOutside;
  manager.enableAutoToolbar = enableAutoToolbar;
}

- (BOOL)isNetworkReachable {
  return ![[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable];
}

- (void)addListener {
  [[NIMSDK sharedSDK].mediaManager addDelegate:self];
  [IMKitClient.instance addLoginListener:self];
}

- (void)removeListener {
  [[NIMSDK sharedSDK].mediaManager removeDelegate:self];
  [IMKitClient.instance removeLoginListener:self];
  self.viewModel.delegate = nil;
}

#pragma mark - Property Accessors

- (void)setTitleContent:(NSString *)titleContent {
  NSString *resolvedTitle = [titleContent copy];
  if (resolvedTitle.length == 0 && ChatRepo.conversationId.length > 0) {
    resolvedTitle = [ChatMessageHelper getSessionName:ChatRepo.conversationId showAlias:YES];
  }
  if (resolvedTitle.length == 0) {
    resolvedTitle = ChatRepo.sessionId ?: @"";
  }
  _titleContent = resolvedTitle ?: @"";

  NSString *displayTitle = _titleContent;
  if ([self.viewModel isKindOfClass:[P2PChatViewModel class]] &&
      IMKitConfigCenter.shared.enableOnlineStatus &&
      ![NEAIUserManager.shared isAIUser:ChatRepo.sessionId]) {
    P2PChatViewModel *vm = (P2PChatViewModel *)self.viewModel;
    NSString *suffix = vm.online ? chatLocalizable(@"p2p_chat_online") : chatLocalizable(@"p2p_chat_offline");
    displayTitle = [(_titleContent ?: @"") stringByAppendingString:(suffix ?: @"")];
  }
  self.title = displayTitle;
  self.navigationItem.title = displayTitle;
  self.navigationView.navTitle.text = displayTitle;
}

- (void)setBodyTopViewTopConstant:(CGFloat)bodyTopViewTopConstant {
  _bodyTopViewTopConstant = bodyTopViewTopConstant;
  self.bodyTopViewTopAnchor.constant = bodyTopViewTopConstant;
}

- (void)setBodyTopViewHeight:(CGFloat)bodyTopViewHeight {
  _bodyTopViewHeight = bodyTopViewHeight;
  self.bodyTopViewHeightAnchor.constant = bodyTopViewHeight;
  self.bodyTopView.hidden = bodyTopViewHeight <= 0;
}

- (void)setBodyBottomViewHeight:(CGFloat)bodyBottomViewHeight {
  _bodyBottomViewHeight = bodyBottomViewHeight;
  self.bodyBottomViewHeightAnchor.constant = bodyBottomViewHeight;
  self.bodyBottomView.hidden = bodyBottomViewHeight <= 0;
}

- (void)setBottomViewHeight:(CGFloat)bottomViewHeight {
  _bottomViewHeight = bottomViewHeight;
  self.bottomViewHeightAnchor.constant = bottomViewHeight;
}

#pragma mark - Lazy Properties

- (UIView *)bodyTopView {
  if (!_bodyTopView) {
    _bodyTopView = [[UIView alloc] init];
    _bodyTopView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyTopView.backgroundColor = UIColor.clearColor;
  }
  return _bodyTopView;
}

- (UIView *)bodyView {
  if (!_bodyView) {
    _bodyView = [[UIView alloc] init];
    _bodyView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyView.backgroundColor = UIColor.clearColor;

    [_bodyView addSubview:self.brokenNetworkView];
    [NSLayoutConstraint activateConstraints:@[
      [self.brokenNetworkView.topAnchor constraintEqualToAnchor:_bodyView.topAnchor],
      [self.brokenNetworkView.leftAnchor constraintEqualToAnchor:_bodyView.leftAnchor],
      [self.brokenNetworkView.rightAnchor constraintEqualToAnchor:_bodyView.rightAnchor],
      [self.brokenNetworkView.heightAnchor constraintEqualToConstant:self.brokenNetworkViewHeight],
    ]];

    [_bodyView addSubview:self.contentView];
    self.contentViewTopAnchor = [self.contentView.topAnchor constraintEqualToAnchor:_bodyView.topAnchor];
    self.contentViewTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
      [self.contentView.leftAnchor constraintEqualToAnchor:_bodyView.leftAnchor],
      [self.contentView.rightAnchor constraintEqualToAnchor:_bodyView.rightAnchor],
      [self.contentView.bottomAnchor constraintEqualToAnchor:_bodyView.bottomAnchor],
    ]];
  }
  return _bodyView;
}

- (NEBrokenNetworkView *)brokenNetworkView {
  if (!_brokenNetworkView) {
    _brokenNetworkView = [[NEBrokenNetworkView alloc] init];
    _brokenNetworkView.translatesAutoresizingMaskIntoConstraints = NO;
    _brokenNetworkView.hidden = YES;
  }
  return _brokenNetworkView;
}

- (UIView *)contentView {
  if (!_contentView) {
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.backgroundColor = UIColor.clearColor;

    [_contentView addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
      [self.tableView.topAnchor constraintEqualToAnchor:_contentView.topAnchor],
      [self.tableView.leftAnchor constraintEqualToAnchor:_contentView.leftAnchor],
      [self.tableView.rightAnchor constraintEqualToAnchor:_contentView.rightAnchor],
      [self.tableView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor],
    ]];
  }
  return _contentView;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.scrollsToTop = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor ?: UIColor.whiteColor;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }

    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    header.lastUpdatedTimeLabel.hidden = YES;
    _tableView.mj_header = header;
  }
  return _tableView;
}

- (UIView *)bodyBottomView {
  if (!_bodyBottomView) {
    _bodyBottomView = [[UIView alloc] init];
    _bodyBottomView.translatesAutoresizingMaskIntoConstraints = NO;
    _bodyBottomView.backgroundColor = UIColor.clearColor;
    _bodyBottomView.accessibilityIdentifier = @"id.chatBodyBottomView";

    if ([IMKitConfigCenter shared].enableAIUser) {
      [_bodyBottomView addSubview:self.translateLanguageView];
      [NSLayoutConstraint activateConstraints:@[
        [self.translateLanguageView.topAnchor constraintEqualToAnchor:_bodyBottomView.topAnchor],
        [self.translateLanguageView.leftAnchor constraintEqualToAnchor:_bodyBottomView.leftAnchor],
        [self.translateLanguageView.rightAnchor constraintEqualToAnchor:_bodyBottomView.rightAnchor],
        [self.translateLanguageView.bottomAnchor constraintEqualToAnchor:_bodyBottomView.bottomAnchor],
      ]];
    }
  }
  return _bodyBottomView;
}

- (UIView *)bottomView {
  if (!_bottomView) {
    _bottomView = [[UIView alloc] init];
    _bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomView.backgroundColor = UIColor.clearColor;
    _bottomView.accessibilityIdentifier = @"id.chatBodyBottomView";

    [_bottomView addSubview:self.chatInputView];
    [_bottomView addSubview:self.mutilSelectBottomView];
    [NSLayoutConstraint activateConstraints:@[
      [self.chatInputView.topAnchor constraintEqualToAnchor:_bottomView.topAnchor],
      [self.chatInputView.leftAnchor constraintEqualToAnchor:_bottomView.leftAnchor],
      [self.chatInputView.rightAnchor constraintEqualToAnchor:_bottomView.rightAnchor],
      [self.chatInputView.heightAnchor constraintEqualToConstant:404],
      [self.mutilSelectBottomView.topAnchor constraintEqualToAnchor:_bottomView.topAnchor],
      [self.mutilSelectBottomView.leftAnchor constraintEqualToAnchor:_bottomView.leftAnchor],
      [self.mutilSelectBottomView.rightAnchor constraintEqualToAnchor:_bottomView.rightAnchor],
      [self.mutilSelectBottomView.heightAnchor constraintEqualToConstant:304],
    ]];
  }
  return _bottomView;
}

- (NEBaseChatInputView *)chatInputView {
  if (!_chatInputView) {
    V2NIMConversationType conversationType = [V2NIMConversationIdUtil conversationType:ChatRepo.conversationId];
    _chatInputView = [self getMenuView:conversationType];
    _chatInputView.translatesAutoresizingMaskIntoConstraints = NO;
    _chatInputView.clipsToBounds = YES;
    _chatInputView.delegate = self;
    _chatInputView.multipleLineDelegate = self;
  }
  return _chatInputView;
}

- (NEBaseChatNewMessageView *)jumpDownView {
  if (!_jumpDownView) {
    _jumpDownView = [self getJumpDownView];
    _jumpDownView.translatesAutoresizingMaskIntoConstraints = NO;
    _jumpDownView.clipsToBounds = YES;
    _jumpDownView.backgroundColor = UIColor.whiteColor;
    _jumpDownView.layer.cornerRadius = 20;
    _jumpDownView.hidden = YES;
    _jumpDownView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpDownMessage)];
    [_jumpDownView addGestureRecognizer:tap];
  }
  return _jumpDownView;
}

- (NEBaseChatLastReadPositionView *)lastReadPositionView {
  if (!_lastReadPositionView) {
    _lastReadPositionView = [self getLastReadPositionView];
    _lastReadPositionView.translatesAutoresizingMaskIntoConstraints = NO;
    _lastReadPositionView.hidden = YES;
    _lastReadPositionView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToLastReadPosition)];
    [_lastReadPositionView addGestureRecognizer:tap];
  }
  return _lastReadPositionView;
}

- (ReplyView *)replyView {
  if (!_replyView) {
    _replyView = [[ReplyView alloc] init];
    _replyView.translatesAutoresizingMaskIntoConstraints = NO;
    _replyView.hidden = YES;
    [_replyView.closeButton addTarget:self action:@selector(closeReply:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _replyView;
}

- (NEMutilSelectBottomView *)mutilSelectBottomView {
  if (!_mutilSelectBottomView) {
    _mutilSelectBottomView = [[NEMutilSelectBottomView alloc] init];
    _mutilSelectBottomView.translatesAutoresizingMaskIntoConstraints = NO;
    _mutilSelectBottomView.hidden = YES;
    _mutilSelectBottomView.delegate = (id<NEMutilSelectBottomViewDelegate>)self;
    [_mutilSelectBottomView setEnable:NO];
  }
  return _mutilSelectBottomView;
}

- (TopMessageView *)topMessageView {
  if (!_topMessageView) {
    _topMessageView = [[TopMessageView alloc] init];
    _topMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    _topMessageView.delegate = (id<TopMessageViewDelegate>)self;
  }
  return _topMessageView;
}

- (NEAITranslateView *)translateLanguageView {
  if (!_translateLanguageView) {
    _translateLanguageView = [[NEAITranslateView alloc] init];
    _translateLanguageView.translatesAutoresizingMaskIntoConstraints = NO;
    _translateLanguageView.delegate = self;
    _translateLanguageView.chatInputText = self.chatInputView.textView;
  }
  return _translateLanguageView;
}

- (MessageOperationView *)operationView {
  if (!_operationView) {
    _operationView = [[MessageOperationView alloc] initWithFrame:CGRectZero];
    _operationView.hidden = YES;
    _operationView.delegate = self;
  }
  if (_operationView.superview != self.view && self.isViewLoaded) {
    [self.view addSubview:_operationView];
  }
  return _operationView;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[ChatRepo shared] addMessageSendListener:self];
  [self updateKeyboardManagerEnabled:NO shouldResignOnTouchOutside:NO enableAutoToolbar:NO];
  self.isCurrentPage = YES;
  [self.viewModel startReactionManager];
  [self.viewModel enterConversation];
  [self renderLastReadPositionState];
  if ([ChatUIConfig shared].messageProperties.showTitleBar) {
    self.bodyTopViewTopConstant = self.topConstant;
  }
  [NEChatDetectNetworkTool.shareInstance netWorkReachability:^(NEReachabilityStatus status) {
    if (status == NEReachabilityStatusNotReachable) {
      self.brokenNetworkView.hidden = NO;
      self.contentViewTopAnchor.constant = self.brokenNetworkViewHeight;
    } else {
      self.brokenNetworkView.hidden = YES;
      self.contentViewTopAnchor.constant = 0;
    }
  }];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  // 从搜索页、好友名片、加群、备注等入口进入聊天时，上一级页面的键盘可能被带入；
  // 用户已聚焦聊天输入框时不能再 endEditing，否则会收掉刚弹起的键盘。
  if (!self.chatInputView.textView.isFirstResponder && !self.chatInputView.titleField.isFirstResponder) {
    [self.view.window endEditing:YES];
  }
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (!weakSelf.chatInputView.textView.isFirstResponder && !weakSelf.chatInputView.titleField.isFirstResponder) {
      [weakSelf.view.window endEditing:YES];
    }
  });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (!weakSelf.chatInputView.textView.isFirstResponder && !weakSelf.chatInputView.titleField.isFirstResponder) {
      [weakSelf.view.window endEditing:YES];
    }
  });
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
  self.viewModel.delegate = self;
  [self commonUI];
  [self addObseve];
  __weak typeof(self) weakSelf = self;
  [self getSessionInfo:ChatRepo.sessionId completion:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf loadData];
    });
  }];
  [[Router shared] register:NERouterUrl.LocationSearchResult closure:^(NSDictionary *result) {
    ChatLocaitonModel *model = [ChatLocaitonModel yx_modelWithDictionary:result];
    if (model) {
      [weakSelf.viewModel sendLocationMessage:model completion:^(NSError *error) {
        [weakSelf showErrorToast:error defaultToast:nil];
      }];
    }
  }];
  weakSelf.viewModel.translationAIUser = [NEAIUserManager.shared getAITranslateUser];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[ChatRepo shared] removeMessageSendListener:self];
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  [self updateKeyboardManagerEnabled:YES shouldResignOnTouchOutside:YES enableAutoToolbar:NO];
  self.isCurrentPage = NO;
  [self.viewModel stopReactionManager];
  [self removeOperationView:YES];
  [self stopPlay];
  if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self stopPlay];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
  [super didMoveToParentViewController:parent];
  if (!parent) {
    self.lastReadPositionRequestId += 1;
    [self.viewModel leaveConversation];
    NSDictionary *param = @{@"sessionId": ChatRepo.conversationId ?: @""};
    [[Router shared] use:@"ClearAtMessageRemind" parameters:param closure:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NETeamUserManager.shared removeAllTeamInfo];
    [self removeListener];
  }
}

- (void)backEvent {
  [super backEvent];
  [self removeListener];
}

#pragma mark - ChatViewModelDelegate

- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs {
  [self removeOperationView:YES];
  BOOL hasPendingNewMessages = self.onReceiveNewMsgs.count > 0;
  [self insertRows:indexs scrollToBottom:NO];
  NSInteger msgCount = [self.tableView numberOfRowsInSection:0];
  NSIndexPath *lastIP = [NSIndexPath indexPathForRow:msgCount - 2 inSection:0];
  BOOL isLastVisible = NO;
  UITableViewCell *lastCell = [self.tableView cellForRowAtIndexPath:lastIP];
  if (lastCell && [self.tableView.visibleCells containsObject:lastCell]) {
    isLastVisible = YES;
  }
  if (!hasPendingNewMessages && (self.isRecvRolling || [self isCloseToBottom])) {
    isLastVisible = YES;
  }
  if (!hasPendingNewMessages && self.isCurrentPage && !self.presentedViewController && isLastVisible) {
    if (!self.isCurrentPage) return;
    if (self.tableView.isDragging || self.tableView.isDecelerating) return;
    NSInteger row = [self.tableView numberOfRowsInSection:0];
    if (row > 0) {
      self.isRecvRolling = YES;
      [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
  } else {
    if (self.tableView.contentSize.height > self.tableView.bounds.size.height) {
      NSMutableArray<V2NIMMessage *> *pendingMessages = [NSMutableArray array];
      for (V2NIMMessage *msg in messages) {
        if (![ChatMessageHelper isSelf:msg]) {
          [pendingMessages addObject:msg];
        }
      }
      NEChatAppendUniqueMessages(self.onReceiveNewMsgs, pendingMessages);
      NEChatRetainMessagesAfterAnchor(self.onReceiveNewMsgs, self.messageIndicatorCutoffAnchor);
      if (!self.isMutilSelect) {
        [self showJumpDownMessage:self.onReceiveNewMsgs.count];
      }
    }
  }
}

- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index {
  BOOL scrollToBottom = self.isCurrentPage && !self.presentedViewController;
  [self insertRows:@[index] scrollToBottom:scrollToBottom];
  if (scrollToBottom) {
    [self.onReceiveNewMsgs removeAllObjects];
    [self showJumpDownMessage:-1];
  } else if (!self.isMutilSelect) {
    [self showJumpDownMessage:self.onReceiveNewMsgs.count];
  }
}

- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index {
  [self reloadSendMessage:message fallbackIndex:index retry:YES];
  if (![IMKitConfigCenter shared].enableAIStream &&
      message.aiConfig &&
      message.aiConfig.aiStatus == V2NIM_MESSAGE_AI_STATUS_AT) {
    [self.view ne_makeToast:chatLocalizable(@"ai_request_ing")];
  }
}

- (void)onResendSuccess:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndexPath {
  NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
  if (!fromIndex || !toIndexPath ||
      fromIndex.row < 0 || fromIndex.row >= rowCount ||
      toIndexPath.row < 0 || toIndexPath.row >= rowCount) {
    [self.tableView reloadData];
    return;
  }
  @try {
    [self.tableView moveRowAtIndexPath:fromIndex toIndexPath:toIndexPath];
    [self.tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView scrollToRowAtIndexPath:toIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
  } @catch (NSException *exception) {
    [self.tableView reloadData];
  }
}

- (void)onLoadMoreWithMessage:(NSArray<NSIndexPath *> *)indexs {
  [self tableViewReloadIndexs:indexs completion:nil];
}

- (void)onModefiedMessage:(NSIndexPath *)index {
  NSArray<NSIndexPath *> *visibleRows = self.tableView.indexPathsForVisibleRows;
  BOOL shouldKeepAtBottom = !(self.tableView.isDragging || self.tableView.isTracking || self.tableView.isDecelerating) &&
                            [visibleRows containsObject:index] &&
                            [self isCloseToBottom];
  __weak typeof(self) weakSelf = self;
  [self tableViewReloadIndexs:@[index] completion:^{
    if (!shouldKeepAtBottom || weakSelf.tableView.isDragging ||
        weakSelf.tableView.isTracking || weakSelf.tableView.isDecelerating) {
      return;
    }
    [weakSelf.tableView layoutIfNeeded];
    [weakSelf scrollTableViewToBottomWithoutAnimationIfPossible];
  }];
}

- (void)onReactionModifiedMessage:(NSIndexPath *)index {
  if (self.isLoadingData || ![index isKindOfClass:[NSIndexPath class]] ||
      index.section < 0 || index.section >= self.tableView.numberOfSections ||
      index.row < 0 || index.row >= [self.tableView numberOfRowsInSection:index.section]) {
    return;
  }

  BOOL isUserInteracting = self.tableView.isDragging || self.tableView.isTracking || self.tableView.isDecelerating;
  BOOL latestMessageVisible = [self isLastMessageVisible];
  if (!isUserInteracting && (self.keepsBottomPinnedForPendingReactionUpdates || latestMessageVisible)) {
    self.keepsBottomPinnedForPendingReactionUpdates = YES;
  }

  [self.pendingReactionReloadIndexPaths addObject:index];
  [self scheduleReactionReloadIfNeeded];
}

- (void)initialMessageDetailsDidLoad {
  if (!self.keepsBottomPinnedForInitialMessageDetails) {
    return;
  }
  self.keepsBottomPinnedForInitialMessageDetails = NO;
  if (self.viewModel.lastReadPositionLocating ||
      self.tableView.isDragging || self.tableView.isTracking || self.tableView.isDecelerating) {
    return;
  }

  [self.tableView layoutIfNeeded];
  NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
  if (rowCount > 0 && rowCount == (NSInteger)self.viewModel.messages.count) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowCount - 1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
  }
}

- (void)scheduleReactionReloadIfNeeded {
  if (self.isReactionReloadScheduled || self.isReactionReloadInProgress) {
    return;
  }
  self.isReactionReloadScheduled = YES;
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.isReactionReloadScheduled = NO;
    [self flushPendingReactionReloads];
  });
}

- (void)flushPendingReactionReloads {
  if (self.isReactionReloadInProgress) {
    return;
  }
  if (self.isLoadingData) {
    [self.pendingReactionReloadIndexPaths removeAllObjects];
    self.keepsBottomPinnedForPendingReactionUpdates = NO;
    return;
  }

  NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
  for (NSIndexPath *index in self.pendingReactionReloadIndexPaths) {
    if (index.section >= 0 && index.section < self.tableView.numberOfSections &&
        index.row >= 0 && index.row < [self.tableView numberOfRowsInSection:index.section]) {
      [indexPaths addObject:index];
    }
  }
  [self.pendingReactionReloadIndexPaths removeAllObjects];
  [indexPaths sortUsingComparator:^NSComparisonResult(NSIndexPath *lhs, NSIndexPath *rhs) {
    if (lhs.section != rhs.section) {
      return lhs.section < rhs.section ? NSOrderedAscending : NSOrderedDescending;
    }
    if (lhs.row == rhs.row) return NSOrderedSame;
    return lhs.row < rhs.row ? NSOrderedAscending : NSOrderedDescending;
  }];

  if (indexPaths.count == 0) {
    [self finishPendingReactionReloads];
    return;
  }

  self.isReactionReloadInProgress = YES;
  __weak typeof(self) weakSelf = self;
  [self tableViewReloadIndexs:indexPaths completion:^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.isReactionReloadInProgress = NO;
    if (self.pendingReactionReloadIndexPaths.count == 0) {
      [self finishPendingReactionReloads];
    } else {
      [self scheduleReactionReloadIfNeeded];
    }
  }];
}

- (void)finishPendingReactionReloads {
  if (!self.keepsBottomPinnedForPendingReactionUpdates) {
    return;
  }
  self.keepsBottomPinnedForPendingReactionUpdates = NO;
  if (self.viewModel.lastReadPositionLocating ||
      self.tableView.isDragging || self.tableView.isTracking || self.tableView.isDecelerating) {
    return;
  }
  [self.tableView layoutIfNeeded];
  NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
  if (rowCount > 0 && rowCount == (NSInteger)self.viewModel.messages.count) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowCount - 1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
  }
}

- (void)cancelPendingReactionBottomPinning {
  self.keepsBottomPinnedForPendingReactionUpdates = NO;
  self.keepsBottomPinnedForInitialMessageDetails = NO;
}

- (void)onDeleteMessage:(NSArray<V2NIMMessage *> *)messages deleteIndexs:(NSArray<NSIndexPath *> *)deleteIndexs reloadIndex:(NSArray<NSIndexPath *> *)reloadIndex {
  NSArray<NSIndexPath *> *safeDeleteIndexs = NEChatUniqueIndexPaths(deleteIndexs);
  if (safeDeleteIndexs.count == 0) return;
  [self removeOperationView:YES];
  __weak typeof(self) weakSelf = self;
  NSMutableArray<NSIndexPath *> *safeReloadIndexs = [NSMutableArray array];
  NSSet<NSIndexPath *> *deleteSet = [NSSet setWithArray:safeDeleteIndexs];
  for (NSIndexPath *indexPath in NEChatUniqueIndexPaths(reloadIndex)) {
    if (![deleteSet containsObject:indexPath]) {
      [safeReloadIndexs addObject:indexPath];
    }
  }
  [self tableViewReloadIndexs:safeReloadIndexs completion:^{
    for (NSIndexPath *idx in safeReloadIndexs) {
      if (idx.row == [weakSelf.tableView numberOfRowsInSection:0] - 1) {
        [weakSelf scrollTableViewToBottom];
      }
    }
  }];
  NSArray<V2NIMMessage *> *messageSnapshot = [messages copy];
  for (V2NIMMessage *msg in messageSnapshot) {
    NSMutableArray *toRemove = [NSMutableArray array];
    NSArray<id<MessageModel> > *modelSnapshot = [self.viewModel.messages copy];
    for (id<MessageModel> m in modelSnapshot) {
      if ([m.message.messageClientId isEqualToString:msg.messageClientId]) {
        [toRemove addObject:m];
      }
    }
    [self.viewModel.messages removeObjectsInArray:toRemove];
    [self.viewModel.selectedMessages removeObjectsAtIndexes:[self.viewModel.selectedMessages indexesOfObjectsPassingTest:^BOOL(V2NIMMessage *obj, NSUInteger idx, BOOL *stop) {
      return [obj.messageClientId isEqualToString:msg.messageClientId];
    }]];

    if ([msg.messageClientId isEqualToString:self.viewModel.operationModel.message.messageClientId]) {
      self.replyView.textLabel.attributedText = nil;
      self.replyView.textLabel.text = chatLocalizable(@"message_not_found");
      [self.replyView layoutIfNeeded];
    }
  }
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
  [self tableViewDeleteIndexs:safeDeleteIndexs];
  if (self.viewModel.messages.count == 0) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakSelf loadMoreData];
    });
  }
}

- (void)onRevokeMessage:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {
  if (atIndexs.count == 0) return;
  __block BOOL revokedPendingNewMessage = NO;
  [self.onReceiveNewMsgs enumerateObjectsUsingBlock:^(V2NIMMessage *obj, NSUInteger idx, BOOL *stop) {
    if (NEChatMessageIsSame(obj, message)) {
      revokedPendingNewMessage = YES;
      *stop = YES;
    }
  }];
  BOOL wasCloseToBottom = [self isCloseToBottom];
  BOOL keepHistoryPosition = revokedPendingNewMessage && !wasCloseToBottom;
  [self.viewModel.selectedMessages removeObjectsAtIndexes:[self.viewModel.selectedMessages indexesOfObjectsPassingTest:^BOOL(V2NIMMessage *obj, NSUInteger idx, BOOL *stop) {
    return [obj.messageClientId isEqualToString:message.messageClientId];
  }]];
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
  [self removeOperationView:YES];
  __weak typeof(self) weakSelf = self;
  [NEALog infoLog:NSStringFromClass(self.class) desc:[NSString stringWithFormat:@"on revoke message at indexs %@", atIndexs]];
  [self tableViewReloadIndexs:atIndexs completion:^{
    for (NSIndexPath *index in atIndexs) {
      NSInteger numberOfRows = [weakSelf.tableView numberOfRowsInSection:0];
      UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:index];
      if (index.row == numberOfRows - 1 && cell && [weakSelf.tableView.visibleCells containsObject:cell]) {
        if (!keepHistoryPosition) {
          [weakSelf scrollTableViewToBottom];
        }
      }
    }
  }];
  if ([message.messageClientId isEqualToString:self.viewModel.operationModel.message.messageClientId]) {
    self.replyView.textLabel.attributedText = nil;
    self.replyView.textLabel.text = chatLocalizable(@"message_not_found");
    [self.replyView layoutIfNeeded];
  }
  [self.onReceiveNewMsgs filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(V2NIMMessage *obj, NSDictionary *bindings) {
    return !NEChatMessageIsSame(obj, message);
  }]];
  if (keepHistoryPosition && !self.isMutilSelect) {
    [self showJumpDownMessage:self.onReceiveNewMsgs.count];
  } else {
    [self showJumpDownView];
  }
}

- (void)onMessageStatusChange:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {
  __weak typeof(self) weakSelf = self;
  [self tableViewReloadIndexs:atIndexs completion:^{
    for (NSIndexPath *index in atIndexs) {
      if (index.row == [weakSelf.tableView numberOfRowsInSection:0] - 1) {
        [weakSelf scrollTableViewToBottom];
      }
    }
  }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  __weak typeof(self) weakSelf = self;
  [picker dismissViewControllerAnimated:YES completion:^{
    [weakSelf sendMediaMessage:info];
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
  [controller dismissViewControllerAnimated:YES completion:nil];
  NSURL *url = urls.firstObject;
  if (!url) return;
  BOOL authorized = [url startAccessingSecurityScopedResource];
  if (authorized) {
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    [coordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL *newUrl) {
      [self copyFileToSend:newUrl displayName:newUrl.lastPathComponent isFile:YES width:0 height:0 duration:0];
    }];
    [url stopAccessingSecurityScopedResource];
  }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
  [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
  return [self documentPreviewPresenter];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  [self stopPlay];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
  [self stopPlay];
}

#pragma mark - UIScrollViewDelegate (extended)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.isRecvRolling = NO;
  self.needScrollToBottomAfterReload = NO;
  self.scrollToBottomAfterReloadRemainingCount = 0;
  self.isSchedulingScrollToBottomAfterReload = NO;
  self.suppressHistoryAutoLoadUntilUserScroll = NO;
  [self cancelPendingReactionBottomPinning];
  [self removeOperationView:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView.isDragging || scrollView.isTracking || scrollView.isDecelerating) {
    [self cancelPendingReactionBottomPinning];
    [self showJumpDownView];
    [self refreshLastReadPositionVisibility];
    [self layoutInputView:0 scrollToBottom:NO];
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  BOOL reachedIndicatorTarget = self.onReceiveNewMsgs.count == 0 ? [self isLastMessageVisible] : [self isLatestPendingNewMessageVisible];
  if (reachedIndicatorTarget) {
    self.isRecvRolling = NO;
    [self.onReceiveNewMsgs removeAllObjects];
    [self showJumpDownMessage:-1];
  }
}

#pragma mark - NEIMKitClientListener

- (void)onDataSync:(V2NIMDataSyncType)type state:(V2NIMDataSyncState)state error:(V2NIMError *)error {
  if (type == V2NIM_DATA_SYNC_TYPE_MAIN && state == V2NIM_DATA_SYNC_STATE_COMPLETED) {
    [self getSessionInfo:ChatRepo.sessionId completion:^{
    }];
  }
}

- (void)onConnectStatus:(V2NIMConnectStatus)status {

  if (status == V2NIM_CONNECT_STATUS_WAITING) {
    self.brokenNetworkView.hidden = NO;
    self.contentViewTopAnchor.constant = self.brokenNetworkViewHeight;
    self.networkBroken = YES;
  }

  if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.networkBroken) {
    self.brokenNetworkView.hidden = YES;
    self.contentViewTopAnchor.constant = 0;
    self.networkBroken = NO;
    if (self.isCurrentPage) {
      [self markNeedReadMsg:[self.needMarkReadMsgs copy]];
      [self.needMarkReadMsgs removeAllObjects];
    }

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [weakSelf reLoadMoreWithMessage];
                   });
  } else if (status == V2NIM_CONNECT_STATUS_CONNECTED) {
    self.brokenNetworkView.hidden = YES;
    self.contentViewTopAnchor.constant = 0;
  } else if (status == V2NIM_CONNECT_STATUS_DISCONNECTED) {
    self.brokenNetworkView.hidden = NO;
    self.contentViewTopAnchor.constant = self.brokenNetworkViewHeight;
  }
}

#pragma mark - Notification handlers

- (void)didShowCallView {
  [self stopPlay];
}

- (void)reLoadMoreWithMessage {
  NSMutableArray<V2NIMMessage *> *messages = [NSMutableArray array];
  NSArray<id<MessageModel> > *modelSnapshot = [self.viewModel.messages copy];
  for (id<MessageModel> model in modelSnapshot) {
    if (model.message) {
      [messages addObject:model.message];
    }
  }
  [self.viewModel loadMoreWithMessage:messages];
}

- (void)didTapHeader:(NSNotification *)noti {
  if ([noti.object isKindOfClass:[NEUserWithFriend class]]) {
    NEUserWithFriend *user = (NEUserWithFriend *)noti.object;
    NSString *accid = user.user.accountId;
    if (accid.length <= 0) {
      return;
    }

    if ([[NEFriendUserCache shared] isFriend:accid]) {
      [[NEFriendUserCache shared] updateFriendInfoByUserWithFriend:user];
    } else if ([[NETeamUserManager shared] getUserInfo:accid]) {
      [[NETeamUserManager shared] updateUserInfoWithFriend:user];
    } else if ([[NEP2PChatUserCache shared] getUserInfo:accid]) {
      [[NEP2PChatUserCache shared] updateUserInfoWithFriend:user];
    }

    [self onUserOrFriendInfoChanged:accid];
    return;
  }

  NSString *uid = noti.userInfo[@"uid"];
  if (uid) {
    [[Router shared] use:NEChatContactUserInfoPageRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"uid": uid} closure:nil];
  }
}

#pragma mark - Viewport

/// 按消息表当前宽度返回 viewport。
///
- (NEChatViewport *)viewportForCurrentTableWidth {
  CGFloat width = CGRectGetWidth(self.tableView.bounds);
  if (width <= 0 || !isfinite(width)) {
    return self.chatViewport;
  }
  if (self.chatViewport && fabs(self.chatViewport.contentWidth - width) < 0.5) {
    return self.chatViewport;
  }
  // 丢掉整表重排与滚动锚点恢复。
  return [[NEChatViewport alloc] initWithContentWidth:width];
}

/// 宽度变化时下发 viewport、重排消息表，并在关闭动画的事务里恢复
- (void)updateChatViewport {
  if (![NEAdaptiveDeviceGate adaptiveHostActive]) {
    return;
  }
  CGFloat width = CGRectGetWidth(self.tableView.bounds);
  if (width <= 0 || !isfinite(width) || self.isUpdatingViewport) {
    return;
  }
  if (self.chatViewport && self.chatViewport.contentWidth == width) {
    return;
  }
  self.isUpdatingViewport = YES;

  NSIndexPath *visible = [[self.tableView indexPathsForVisibleRows]
      sortedArrayUsingSelector:@selector(compare:)].firstObject;
  id anchor = nil;
  CGFloat displacement = 0;
  if (visible && visible.row < (NSInteger)self.viewModel.messages.count) {
    anchor = self.viewModel.messages[visible.row];
    displacement = CGRectGetMinY([self.tableView rectForRowAtIndexPath:visible]) -
                   self.tableView.contentOffset.y;
  }
  BOOL bottom = self.tableView.contentOffset.y + CGRectGetHeight(self.tableView.bounds) >=
                self.tableView.contentSize.height +
                    self.tableView.adjustedContentInset.bottom - 2;

  NEChatViewport *viewport = [[NEChatViewport alloc] initWithContentWidth:width];
  self.chatViewport = viewport;
  for (id<MessageModel> model in self.viewModel.messages) {
    if ([model respondsToSelector:@selector(applyViewport:)]) {
      [(MessageContentModel *)model applyViewport:viewport];
    }
  }
  [self removeOperationView:YES];

  [UIView performWithoutAnimation:^{
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    CGFloat minOffset = -self.tableView.adjustedContentInset.top;
    CGFloat maxOffset = MAX(minOffset,
                            self.tableView.contentSize.height -
                                CGRectGetHeight(self.tableView.bounds) +
                                self.tableView.adjustedContentInset.bottom);
    if (bottom) {
      self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, maxOffset);
    } else if (anchor) {
      NSInteger row = [self.viewModel.messages indexOfObjectIdenticalTo:anchor];
      if (row != NSNotFound) {
        CGFloat y = CGRectGetMinY([self.tableView rectForRowAtIndexPath:
                                      [NSIndexPath indexPathForRow:row inSection:0]]) - displacement;
        self.tableView.contentOffset =
            CGPointMake(self.tableView.contentOffset.x, MIN(MAX(y, minOffset), maxOffset));
      }
    }
  }];

  self.isUpdatingViewport = NO;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if ([NEAdaptiveDeviceGate adaptiveHostActive] && self.hasKeyboardFrameInScreen) {
    CGFloat height = [self keyboardOverlap:self.keyboardFrameInScreen];
    if (fabs(height - self.currentKeyboardHeight) > 0.5) {
      self.currentKeyboardHeight = height;
      [self layoutInputViewWithAnimation:height animation:0 scrollToBottom:NO];
    }
  }
  [self updateChatViewport];
}

- (void)loadData {
  __weak typeof(self) weakSelf = self;
  NSInteger requestId = ++self.loadDataRequestId;
  BOOL requestHistoryChat = self.viewModel.anchor != nil;
  if (requestHistoryChat) {
    [self cancelScrollToBottomAfterReload];
    self.suppressHistoryAutoLoadUntilUserScroll = YES;
  } else {
    self.suppressHistoryAutoLoadUntilUserScroll = NO;
  }
  self.isLoadingData = YES;
  [self.viewModel loadData:^(NSError *error, NSInteger historyEnd, NSInteger newEnd, NSInteger index) {
    if (!weakSelf || requestId != weakSelf.loadDataRequestId) {
      return;
    }
    weakSelf.isLoadingData = NO;
    if (weakSelf.viewModel.messages.count > 0) {
      [weakSelf tableViewReload];
      if (requestHistoryChat && weakSelf.viewModel.isHistoryChat) {
        if ([weakSelf scrollToAnchorMessage:weakSelf.viewModel.anchor requestId:requestId]) {
          if (newEnd > 0) {
            [weakSelf addBottomLoadMore];
          } else {
            weakSelf.viewModel.isHistoryChat = NO;
          }
        }
      } else if (!requestHistoryChat) {
        [weakSelf removeBottomLoadMore];
        weakSelf.keepsBottomPinnedForPendingReactionUpdates = YES;
        weakSelf.keepsBottomPinnedForInitialMessageDetails = YES;
        [weakSelf.tableView layoutIfNeeded];
        [weakSelf startScrollToBottomAfterReload];
        [weakSelf removeBottomLoadMore];
      }
    } else if (error) {
      [weakSelf showErrorToast:error defaultToast:nil];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
    });
    [weakSelf loadDataFinish];
  }];
}

- (void)loadMoreData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel dropDownRemoteRefresh:^(NSError *error, NSInteger count, NSArray *messages) {
    [weakSelf.tableView reloadData];
    if (count > 0) {
      NSInteger num = [weakSelf.tableView numberOfRowsInSection:0];
      if (count <= num) {
        [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
      }
    }
    [weakSelf.tableView.mj_header endRefreshing];
    dispatch_async(dispatch_get_main_queue(), ^{
    });
  }];
}

- (void)loadCloserToNowData {
  __weak typeof(self) weakSelf = self;
  if (self.viewModel.isHistoryChat && self.suppressHistoryAutoLoadUntilUserScroll) {
    [self.tableView.mj_footer endRefreshing];
    return;
  }
  [self.viewModel pullRemoteRefresh:^(NSError *error, NSInteger count, NSArray *datas) {
    if (count <= 0) {
      [weakSelf.tableView.mj_footer endRefreshing];
      if (error || ![weakSelf isNetworkReachable]) {
        return;
      }
      [weakSelf removeBottomLoadMore];
    } else {
      [weakSelf.tableView.mj_footer endRefreshing];
      [weakSelf tableViewReload];
      dispatch_async(dispatch_get_main_queue(), ^{
      });
    }
  }];
}

- (void)mergePendingNewMessages:(nullable NSArray<V2NIMMessage *> *)messages {
  NEChatAppendUniqueMessages(self.pendingNewMessages, messages);
  NEChatDeduplicateMessages(self.pendingNewMessages);
}

- (void)applyHistoryAnchor:(nullable V2NIMMessage *)anchor
    transferredNewMessages:(nullable NSArray<V2NIMMessage *> *)messages {
  self.viewModel.anchor = anchor;
  if (anchor && (!self.messageIndicatorCutoffAnchor ||
                 self.messageIndicatorCutoffAnchor.createTime < anchor.createTime)) {
    self.messageIndicatorCutoffAnchor = anchor;
  }
  NEChatAppendUniqueMessages(self.onReceiveNewMsgs, self.pendingNewMessages);
  NEChatAppendUniqueMessages(self.onReceiveNewMsgs, messages);
  [self.pendingNewMessages removeAllObjects];
  NEChatRetainMessagesAfterAnchor(self.onReceiveNewMsgs, self.messageIndicatorCutoffAnchor);
}

- (void)addObseve {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  if ([NEAdaptiveDeviceGate adaptiveHostActive]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
  }
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegournd) name:UIApplicationWillEnterForegroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowCallView) name:kCallKitShowNoti object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapHeader:) name:NENotificationDidTapHeader object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reLoadMoreWithMessage) name:NENotificationFriendCacheInit object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMarkdownImageDidLoad:) name:NEMarkdownImageDidLoadNotification object:nil];
  if (self.navigationController.interactivePopGestureRecognizer) {
    [self.tableView.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
  }
}

- (void)commonUI {
  self.titleContent = ChatRepo.sessionId;
  self.navigationView.navTitle.lineBreakMode = NSLineBreakByTruncatingMiddle;
  self.navigationView.titleBarBottomLine.hidden = NO;
  [self.navigationView setHandsetMode:[self.viewModel getHandSetEnable]];
  [self setMoreButton];
  [self setMutilSelectBottomView];

  [self.view addSubview:self.bodyTopView];
  [self.view addSubview:self.bodyView];
  [self.view addSubview:self.bodyBottomView];
  [self.view addSubview:self.bottomView];

  self.bodyTopViewHeightAnchor = [self.bodyTopView.heightAnchor constraintEqualToConstant:self.bodyTopViewHeight];
  self.bodyTopViewHeightAnchor.active = YES;
  self.bodyTopViewTopAnchor = [self.bodyTopView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.bodyTopViewTopConstant];
  self.bodyTopViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.bodyTopView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyTopView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];

  self.bottomViewTopAnchor = [self.bottomView.topAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-self.normalInputHeight];
  self.bottomViewTopAnchor.active = YES;
  self.bottomViewHeightAnchor = [self.bottomView.heightAnchor constraintEqualToConstant:self.bottomViewHeight];
  self.bottomViewHeightAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bottomView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];

  self.bodyBottomViewHeightAnchor = [self.bodyBottomView.heightAnchor constraintEqualToConstant:self.bodyBottomViewHeight];
  self.bodyBottomViewHeightAnchor.active = YES;
  self.translateLanguageViewHeightAnchor = [IMKitConfigCenter shared].enableAIUser ? self.bodyBottomViewHeightAnchor : nil;
  [NSLayoutConstraint activateConstraints:@[
    [self.bodyBottomView.bottomAnchor constraintEqualToAnchor:self.bottomView.topAnchor],
    [self.bodyBottomView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyBottomView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.bodyView.topAnchor constraintEqualToAnchor:self.bodyTopView.bottomAnchor],
    [self.bodyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.bodyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.bodyView.bottomAnchor constraintEqualToAnchor:self.bodyBottomView.topAnchor],
  ]];

  if (!self.registeredCellReuseIds) {
    self.registeredCellReuseIds = [NSMutableSet set];
  }
  [self.tableView registerClass:[NEBaseChatMessageCell class] forCellReuseIdentifier:@"NEBaseChatMessageCell"];
  [self.registeredCellReuseIds addObject:@"NEBaseChatMessageCell"];
  if (![self.cellRegisterDic isKindOfClass:[NSMutableDictionary class]]) {
    self.cellRegisterDic = [self.cellRegisterDic mutableCopy] ?: [NSMutableDictionary dictionary];
  }
  NSDictionary<NSString *, Class> *registerCustomCell = [[NEChatUIKitClient instance] getRegisterCustomCell];
  for (NSString *key in registerCustomCell) {
    self.cellRegisterDic[key] = registerCustomCell[key];
  }
  for (NSString *key in [self.cellRegisterDic allKeys]) {
    Class cellClass = NEChatResolveTableViewCellClass(self.cellRegisterDic[key]);
    if (cellClass) {
      self.cellRegisterDic[key] = cellClass;
      [self.tableView registerClass:cellClass forCellReuseIdentifier:key];
      [self.registeredCellReuseIds addObject:key];
    } else {
      [self.cellRegisterDic removeObjectForKey:key];
    }
  }

  [self expandMoreAction];

  if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] == V2NIM_CONVERSATION_TYPE_P2P) {
    __weak typeof(self) weakSelf = self;
    [[NEAIRobotManager shared] checkIfRobot:ChatRepo.sessionId completion:^(__unused BOOL isRobot) {
      [weakSelf expandMoreAction];
    }];
  }

  [self.view addSubview:self.jumpDownView];
  self.jumpDownViewRightAncher = [self.jumpDownView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16];
  self.jumpDownViewRightAncher.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.jumpDownView.widthAnchor constraintGreaterThanOrEqualToConstant:40],
    [self.jumpDownView.heightAnchor constraintEqualToConstant:40],
    [self.jumpDownView.bottomAnchor constraintEqualToAnchor:self.bodyView.bottomAnchor constant:-24],
  ]];

  if ([ChatUIConfig shared].customController) {
    [ChatUIConfig shared].customController(self);
  }
}

- (void)addBottomLoadMore {
  MJRefreshAutoFooter *footer = [MJRefreshAutoFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadCloserToNowData)];
  footer.triggerAutomaticallyRefreshPercent = -20;
  self.tableView.mj_footer = footer;
}

- (void)removeBottomLoadMore {
  [self.tableView.mj_footer endRefreshingWithNoMoreData];
  self.tableView.mj_footer = nil;
  self.viewModel.isHistoryChat = NO;
}

- (void)markNeedReadMsg:(NSArray<V2NIMMessage *> *)messages {
  if (self.isCurrentPage && messages.count > 0) {
    [self.viewModel markReadMessages:messages completion:^(NSError * _Nullable error) {
      [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                 desc:[NSString stringWithFormat:@"CALLBACK markRead %@", error.localizedDescription ?: @"no error"]];
    }];
  }
}

- (void)appEnterBackground {
  self.isCurrentPage = NO;
  [self stopPlay];
}

- (void)appEnterForegournd {
  self.isCurrentPage = YES;
}

- (void)onMarkdownImageDidLoad:(NSNotification *)notification {
  NSString *url = notification.userInfo[@"url"];
  if (!url || url.length == 0) return;
  NSMutableArray<NSIndexPath *> *reloadIndexPaths = [NSMutableArray array];
  for (NSInteger i = 0; i < (NSInteger)self.viewModel.messages.count; i++) {
    id<MessageModel> model = self.viewModel.messages[i];
    if (model.type != MessageTypeAIStreamText) continue;
    if (![model isKindOfClass:[MessageAIStreamModel class]]) continue;
    MessageAIStreamModel *textModel = (MessageAIStreamModel *)model;
    if ([textModel.message.text containsString:url]) {
      [textModel resetMessage:textModel.message];
      [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
  }
  if (reloadIndexPaths.count > 0) {
    [self tableViewReloadIndexs:reloadIndexPaths completion:nil];
  }
}

- (void)onTeamMemberChange:(V2NIMTeam *)team {
  // 子类可重写
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
  if (![NEFriendUserCache.shared getFriendInfo:[IMKitClient.instance account]]) {
    [ContactRepo.shared getUserListFromCloud:@[[IMKitClient.instance account]] completion:^(NSArray *users, NSError *error) {
      if (completion) completion();
    }];
  } else {
    if (completion) completion();
  }
}

- (void)didTapHeadPortrait:(nullable MessageContentModel *)model {
  if ([ChatMessageHelper isSelf:model.message]) {
    [[Router shared] use:NEChatMeSettingRouter parameters:@{@"nav": self.navigationController ?: [NSNull null]} closure:nil];
    return;
  }
  NSString *uid = [ChatMessageHelper getSenderId:model.message];
  if (!uid) return;
  if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] == V2NIM_CONVERSATION_TYPE_P2P) {
    __weak typeof(self) weakSelf = self;
    [[NEAIRobotManager shared] checkIfRobot:uid completion:^(BOOL isRobot) {
      if (!weakSelf) {
        return;
      }
      NSMutableDictionary *params = [@{@"nav": weakSelf.navigationController ?: [NSNull null], @"uid": uid} mutableCopy];
      if (isRobot) {
        params[@"isRobot"] = @YES;
      }
      [[Router shared] use:NEChatContactUserInfoPageRouter parameters:params closure:nil];
    }];
  } else {
    [[Router shared] use:NEChatContactUserInfoPageRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"uid": uid} closure:nil];
  }
}

- (void)setOperationItems:(NSMutableArray<OperationItem *> *)items model:(nullable MessageContentModel *)model {
  // 子类可重写
}

- (void)removeOperationView:(BOOL)cellEndEditing {
  if (!self.operationView.isHidden) {
    self.operationView.hidden = YES;
  }
  self.operationView.onSelectReaction = nil;
  if (cellEndEditing) {
    [self.viewModel.operationModel.cell.contentView endEditing:YES];
  }
  self.isTranslationOperation = NO;
}

- (void)onUserOrFriendInfoChanged:(NSString *)accountId {
  NSString *sessionId = ChatRepo.sessionId;
  if ([accountId isEqualToString:sessionId]) {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      NSString *showName = [NETeamUserManager.shared getShowName:sessionId];
      weakSelf.titleContent = showName;
    });
  }
  [self.viewModel updateMessageInfo:accountId];
}

- (void)didLongTouchMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (!model || !model.message) return;
  if (model.isRevoked) return;
  if (model.message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER ||
      model.message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING) return;
  if (self.isMutilSelect) return;

  BOOL inputWasFirstResponder = self.chatInputView.textView.isFirstResponder ||
                                self.chatInputView.titleField.isFirstResponder;
  BOOL shouldSyncLayoutBeforeMenu = inputWasFirstResponder &&
                                    ![model isKindOfClass:[MessageTextModel class]];
  if (inputWasFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
    [self layoutInputView:0 scrollToBottom:NO];
  }

  NSMutableArray<OperationItem *> *items = [[self.viewModel avalibleOperationsForMessage:model] mutableCopy] ?: [NSMutableArray array];
  id reactionProvider = nil;
  BOOL showReaction = NO;

  NSMutableArray<OperationItem *> *pluginItems = [NSMutableArray array];
  NSString *selectedText = [model selectText];
  if (!model.unkonwMessage && selectedText.length > 0) {
    if (![NEAIUserManager.shared getAISearchUser]) {
      [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag] desc:@"AI Search User is nil"];
    } else if (![IMKitConfigCenter shared].enableAIUser) {
      [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag] desc:@"IMKitConfigCenter enableAIUser is false"];
    } else {
      [pluginItems addObjectsFromArray:[[IMKitPluginManager shared] getPlugins:NEAISearchPlugin text:selectedText]];
    }
  }

  if ([model isKindOfClass:[MessageTextModel class]]) {
    MessageTextModel *textModel = (MessageTextModel *)model;
    if (textModel.selectRange && textModel.selectRange.rangeValue.length > 0) {
      NSRange selectRange = textModel.selectRange.rangeValue;
      NSString *fullText = textModel.attributeStr.string;
      if (textModel.attributeStr == nil && [textModel isKindOfClass:[MessageRichTextModel class]]) {
        MessageRichTextModel *richTextModel = (MessageRichTextModel *)textModel;
        fullText = richTextModel.titleAttributeStr.string;
      }

      NSUInteger fullLength = fullText.length;
      if (fullLength == 0 || selectRange.location >= fullLength) {
        [self removeOperationView:YES];
        return;
      }
      NSUInteger safeLength = MIN(selectRange.length, fullLength - selectRange.location);
      selectRange = NSMakeRange(selectRange.location, safeLength);

      if (selectRange.length != fullLength) {
        NSMutableArray<OperationItem *> *filtered = [NSMutableArray array];
        for (OperationItem *item in items) {
          if (item.type == OperationTypeCopy) {
            [filtered addObject:item];
          }
        }
        items = filtered;
      }
    } else {
      [self removeOperationView:YES];
      return;
    }
  }

  [items addObjectsFromArray:pluginItems];

  // 全局过滤
  if (self.operationCellFilter) {
    NSMutableArray *filtered = [NSMutableArray array];
    for (OperationItem *item in items) {
      if (item.type && ![self.operationCellFilter containsObject:@(item.type)]) {
        [filtered addObject:item];
      }
    }
    items = filtered;
  }
  if (items.count == 0 && !showReaction) {
    [self removeOperationView:YES];
    return;
  }

  if (ChatUIConfig.shared.chatPopMenu) {
    ChatUIConfig.shared.chatPopMenu(self, items, model);
  }

  [self setOperationItems:items model:model];
  if (items.count == 0 && !showReaction) {
    [self removeOperationView:YES];
    return;
  }

  NSIndexPath *index = [self.tableView indexPathForCell:cell];
  if (!index) {
    [self tableViewReload];
    return;
  }

  [self removeOperationView:YES];
  if (self.viewModel.operationModel != model) {
    if ([self.viewModel.operationModel.cell isKindOfClass:[NEBaseChatMessageCell class]]) {
      [(NEBaseChatMessageCell *)self.viewModel.operationModel.cell resetSelectRange];
    }
    self.viewModel.operationModel = model;
    if ([self.viewModel.operationModel.cell isKindOfClass:[NEBaseChatMessageCell class]]) {
      [(NEBaseChatMessageCell *)self.viewModel.operationModel.cell selectAllRange];
    }
  }

  CGFloat operationWidth = NEChatOperationMenuWidth(items.count);
  CGFloat w = showReaction ? MAX(278.0, operationWidth) : operationWidth;
  CGFloat h = (showReaction ? 50.0 : 0) + 18.0 + 58.0 * ceil((CGFloat)items.count / 5.0);

  if (shouldSyncLayoutBeforeMenu) {
    [self.view layoutIfNeeded];
    [self.tableView layoutIfNeeded];
  }

  CGRect rectInTableView = [self.tableView rectForRowAtIndexPath:index];
  CGRect rectInView = [self.tableView convertRect:rectInTableView toView:self.view];
  CGFloat operationY = CGRectGetMaxY(rectInView);
  BOOL viewUnderMessage = YES;
  if (operationY > kScreenHeight / 2.0) {
    viewUnderMessage = NO;
    operationY = CGRectGetMinY(rectInView) - h + (model.timeContent ? chat_timeCellH : 0);
  } else {
    operationY += 8;
  }
  CGFloat frameX = model.message.isSelf ? kScreenWidth - w - 8.0 : 8.0;

  CGRect frame = CGRectMake(frameX, operationY, w, h);
  if (CGRectGetMaxY(frame) < CGRectGetMinY(self.tableView.frame)) {
    frame.origin.y = CGRectGetMinY(self.tableView.frame);
  } else if (CGRectGetMaxY(frame) > CGRectGetHeight(self.view.frame)) {
    frame.origin.y = self.tableView.frame.origin.y + self.tableView.frame.size.height - h;
  }

  self.operationView.visibleFrame = [self.tableView convertRect:self.tableView.bounds toView:self.view];
  self.operationView.hasVisibleFrame = YES;
  self.operationView.messageRect = rectInView;
  self.operationView.hasMessageRect = YES;
  self.operationView.frame = frame;
  self.operationView.items = items;
  self.operationView.oldFrameHeight = h;
  self.operationView.oldFrameWidth = w;
  self.operationView.viewUnderMessage = viewUnderMessage;
  [self.operationView configureReactionsWithProvider:reactionProvider
                                        quickIndexes:NEChatReactionPanelQuickIndexes()
                                           showEmoji:showReaction
                                      showMoreButton:YES];
  __weak typeof(self) weakSelf = self;
  __weak MessageContentModel *weakModel = model;
  self.operationView.onSelectReaction = ^(NSInteger reactionIndex) {
    V2NIMMessage *message = weakModel.message;
    if (!message) return;
    if (![weakSelf isNetworkReachable]) {
      [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      return;
    }
    [weakSelf.viewModel toggleReactionMessage:message index:reactionIndex completion:^(V2NIMError *error) {
      if (error) [weakSelf showToast:NEChatReactionErrorMessage(error.code)];
    }];
  };
  [self.operationView showOperation];
  self.operationView.hidden = NO;
}

- (void)remoteUserEditing {
  self.title = chatLocalizable(@"editing");
  [self trigerEndTimer];
}

- (void)remoteUserEndEditing {
  self.title = self.titleContent;
  if ([self.viewModel isKindOfClass:[P2PChatViewModel class]] && IMKitConfigCenter.shared.enableOnlineStatus) {
    P2PChatViewModel *vm = (P2PChatViewModel *)self.viewModel;
    self.title = [NSString stringWithFormat:@"%@%@", self.titleContent, vm.online ? chatLocalizable(@"p2p_chat_online") : chatLocalizable(@"p2p_chat_offline")];
  }
}

- (void)timeoutEndEditing {
  [self remoteUserEndEditing];
}

- (void)trigerEndTimer {
  if (self.timer && self.timer.isValid) {
    [self.timer invalidate];
    self.timer = nil;
  }
  self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(timeoutEndEditing) userInfo:nil repeats:NO];
}

- (void)remoteUserOnlineChanged {
  if ([self.viewModel isKindOfClass:[P2PChatViewModel class]] && IMKitConfigCenter.shared.enableOnlineStatus) {
    P2PChatViewModel *vm = (P2PChatViewModel *)self.viewModel;
    self.title = [NSString stringWithFormat:@"%@%@", self.titleContent, vm.online ? chatLocalizable(@"p2p_chat_online") : chatLocalizable(@"p2p_chat_offline")];
  }
}

- (NEBaseUserSettingViewController *)getUserSettingViewController {
  return [[UserSettingViewController alloc] initWithUserId:ChatRepo.sessionId];
}

- (void)toSetting {
  if (ChatUIConfig.shared.messageProperties.titleBarRightClick) {
    ChatUIConfig.shared.messageProperties.titleBarRightClick(self);
    return;
  }
  if (self.isMutilSelect) return;
  if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] == V2NIM_CONVERSATION_TYPE_TEAM) {
    [[Router shared] use:NEChatTeamSettingViewRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"teamid": ChatRepo.sessionId ?: @""} closure:nil];
  } else if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] == V2NIM_CONVERSATION_TYPE_P2P) {
    NEBaseUserSettingViewController *userSetting = [self getUserSettingViewController];
    [self.navigationController pushViewController:userSetting animated:YES];
  }
}

- (void)jumpDownMessage {
  if (self.viewModel.isHistoryChat) {
    self.suppressHistoryAutoLoadUntilUserScroll = NO;
    self.viewModel.anchor = nil;
    [self loadData];
    [self showJumpDownMessage:-1];
    return;
  }
  [self scrollTableViewToBottom];
  [self showJumpDownMessage:-1];
  NEChatDeduplicateMessages(self.onReceiveNewMsgs);
  [self markNeedReadMsg:self.onReceiveNewMsgs];
  [self.onReceiveNewMsgs removeAllObjects];
}

- (void)lastReadPositionStateChanged {
  [self refreshLastReadPositionVisibility];
  [self renderLastReadPositionState];
}

- (void)renderLastReadPositionState {
  BOOL shouldHide = !self.isCurrentPage || self.isMutilSelect ||
      self.viewModel.lastReadPositionSnapshot == nil ||
      self.viewModel.lastReadPositionSuppressed;
  self.lastReadPositionView.hidden = shouldHide;
  if (!shouldHide) {
    [self.lastReadPositionView updateWithSnapshot:self.viewModel.lastReadPositionSnapshot
                                          locating:self.viewModel.lastReadPositionLocating];
  }
}

- (void)refreshLastReadPositionVisibility {
  // Selection hides the entry, but viewing messages must still consume it.
  if (!self.isCurrentPage) {
    return;
  }
  NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
  for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows ?: @[]) {
    if (indexPath.section != 0 || indexPath.row < 0 || indexPath.row >= (NSInteger)self.viewModel.messages.count) {
      continue;
    }
    V2NIMMessage *message = self.viewModel.messages[indexPath.row].message;
    if (message.messageClientId.length > 0) [identifiers addObject:message.messageClientId];
    if (message.messageServerId.length > 0) [identifiers addObject:message.messageServerId];
  }
  [self.viewModel updateLastReadPositionVisibility:identifiers];
  [self renderLastReadPositionState];
}

- (BOOL)isLastReadPositionMessageVisible:(V2NIMMessage *)message {
  NSInteger index = NEChatIndexOfMessageInModels(message, self.viewModel.messages);
  if (index == NSNotFound) {
    return NO;
  }
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  if ([[self.tableView.indexPathsForVisibleRows copy] containsObject:indexPath]) {
    return YES;
  }
  CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
  if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {
    return NO;
  }
  UIEdgeInsets inset = self.tableView.adjustedContentInset;
  CGFloat minY = self.tableView.contentOffset.y + inset.top;
  CGFloat maxY = self.tableView.contentOffset.y + self.tableView.bounds.size.height - inset.bottom;
  return CGRectGetMaxY(rect) > minY && CGRectGetMinY(rect) < maxY;
}

- (void)jumpToLastReadPosition {
  if (!self.isCurrentPage || self.isMutilSelect || self.viewModel.lastReadPositionLocating) {
    return;
  }
  NSInteger requestId = ++self.lastReadPositionRequestId;
  __weak typeof(self) weakSelf = self;
  [self.viewModel locateLastReadPosition:^(V2NIMMessage *message) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || requestId != self.lastReadPositionRequestId ||
        !self.isCurrentPage || !message) {
      return;
    }
    NSInteger index = NEChatIndexOfMessageInModels(message, self.viewModel.messages);
    if (index != NSNotFound) {
      [self finishLastReadPositionScrollToMessage:message requestId:requestId];
    } else {
      [self loadLastReadPositionAroundMessage:message requestId:requestId];
    }
  }];
}

- (void)finishLastReadPositionScrollToMessage:(V2NIMMessage *)message requestId:(NSInteger)requestId {
  if (requestId != self.lastReadPositionRequestId || !self.isCurrentPage) {
    return;
  }
  NSInteger index = NEChatIndexOfMessageInModels(message, self.viewModel.messages);
  if (index == NSNotFound) {
    [self.viewModel completeLastReadPositionLocation:NO];
    return;
  }
  [self.tableView layoutIfNeeded];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
  [self.tableView layoutIfNeeded];
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || requestId != self.lastReadPositionRequestId || !self.isCurrentPage) {
      return;
    }
    BOOL visible = [self isLastReadPositionMessageVisible:message];
    [self.viewModel completeLastReadPositionLocation:visible];
    [self renderLastReadPositionState];
    if (visible) {
      self.isRecvRolling = NO;
      [self showJumpDownView];
    }
  });
}

- (void)loadLastReadPositionAroundMessage:(V2NIMMessage *)message requestId:(NSInteger)requestId {
  if (requestId != self.lastReadPositionRequestId || !self.isCurrentPage) {
    return;
  }
  dispatch_group_t group = dispatch_group_create();
  __block NSError *loadError = nil;
  __block NSArray<V2NIMMessage *> *olderMessages = @[];
  __block NSArray<V2NIMMessage *> *newerMessages = @[];
  __weak typeof(self) weakSelf = self;

  dispatch_group_enter(group);
  [self.viewModel getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_DESC
                            message:message
                         completion:^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *messages) {
    if (error && !loadError) loadError = error;
    olderMessages = messages ?: @[];
    dispatch_group_leave(group);
  }];

  dispatch_group_enter(group);
  [self.viewModel getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_ASC
                            message:message
                         completion:^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *messages) {
    if (error && !loadError) loadError = error;
    newerMessages = messages ?: @[];
    dispatch_group_leave(group);
  }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || requestId != self.lastReadPositionRequestId ||
        !self.isCurrentPage || !self.viewModel.lastReadPositionLocating) {
      return;
    }
    if (loadError) {
      [self.viewModel completeLastReadPositionLocation:NO];
      [self showErrorToast:loadError defaultToast:nil];
      return;
    }

    if (NEChatIndexOfMessageInModels(message, self.viewModel.messages) == NSNotFound) {
      [self.viewModel insertToMessages:[self.viewModel modelFromMessage:message]];
    }
    NSMutableArray<V2NIMMessage *> *allMessages = [NSMutableArray arrayWithArray:olderMessages];
    [allMessages addObject:message];
    [allMessages addObjectsFromArray:newerMessages];
    self.viewModel.anchor = message;
    self.viewModel.isHistoryChat = newerMessages.count > 0;
    [self.viewModel loadMoreWithMessage:allMessages];
    [self tableViewReload];
    if (newerMessages.count > 0) {
      [self addBottomLoadMore];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishLastReadPositionScrollToMessage:message requestId:requestId];
    });
  });
}

- (void)showJumpDownMessage:(NSInteger)messageCount {
  if (messageCount >= 0 && (self.isRecvRolling || [self isLastMessageVisible])) {
    [self.onReceiveNewMsgs removeAllObjects];
    [self.jumpDownView updateMessageCount:-1];
    return;
  }
  if (messageCount > 0) {
    NEChatDeduplicateMessages(self.onReceiveNewMsgs);
    messageCount = self.onReceiveNewMsgs.count;
  }
  if (messageCount > 0) {
    [self.jumpDownView updateMessageCount:messageCount];
    self.jumpDownViewRightAncher.constant = 16;
  } else if (messageCount == 0) {
    [self.jumpDownView updateMessageCount:messageCount];
    self.jumpDownViewRightAncher.constant = -16;
  } else {
    [self.jumpDownView updateMessageCount:-1];
  }
}

- (void)keyBoardWillShow:(NSNotification *)notification {
  BOOL returningFromMention = self.restoringMentionInput &&
                              (!self.presentedViewController || self.presentedViewController.isBeingDismissed);
  BOOL isEditingChatInput = self.chatInputView.textView.isFirstResponder ||
                            self.chatInputView.titleField.isFirstResponder || returningFromMention;
  if (!isEditingChatInput) return;
  if (self.chatInputView.currentType != ChatMenuTypeText) return;
  self.restoringMentionInput = NO;
  self.chatInputView.currentButton.selected = NO;
  self.chatInputView.contentSubView.hidden = YES;
  [self removeOperationView:YES];
  [self closeAIChatView];
  NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
  CGRect keyboardRect = [frameValue isKindOfClass:[NSValue class]] ? frameValue.CGRectValue : CGRectZero;
  NSTimeInterval animDuration = 0.1;
  NSNumber *dur = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
  if (dur) animDuration = dur.doubleValue;
  CGFloat offset = CGRectGetHeight(keyboardRect);
  if ([NEAdaptiveDeviceGate adaptiveHostActive]) {
    self.keyboardFrameInScreen = keyboardRect;
    self.hasKeyboardFrameInScreen = YES;
    self.currentKeyboardHeight = [self keyboardOverlap:keyboardRect];
    offset = self.currentKeyboardHeight;
  }
  [self layoutInputViewWithAnimation:offset animation:animDuration scrollToBottom:YES];
}

/// 键盘 frame 变化（浮动/拆分/Undocked）：只把输入区抬到「键盘与详情列的真实交集」，
- (void)keyboardFrameWillChange:(NSNotification *)notification {
  if (![NEAdaptiveDeviceGate adaptiveHostActive]) return;
  BOOL editing = self.chatInputView.textView.isFirstResponder ||
                 self.chatInputView.titleField.isFirstResponder;
  NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
  if (!editing || ![frameValue isKindOfClass:[NSValue class]]) return;
  CGRect frame = frameValue.CGRectValue;
  self.keyboardFrameInScreen = frame;
  self.hasKeyboardFrameInScreen = YES;
  self.currentKeyboardHeight = [self keyboardOverlap:frame];
  NSNumber *durationValue = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval duration = durationValue ? durationValue.doubleValue : 0.1;
  [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:duration scrollToBottom:NO];
}

- (CGFloat)keyboardOverlap:(CGRect)frame {
  UIWindow *window = self.view.window;
  if (!window) return 0;
  CGRect inWindow = [window convertRect:frame fromCoordinateSpace:window.screen.coordinateSpace];
  CGRect inDetail = [self.view convertRect:inWindow fromView:window];
  CGRect intersection = CGRectIntersection(self.view.bounds, inDetail);
  if (CGRectIsNull(intersection) || intersection.size.width <= 0 ||
      CGRectGetMaxY(intersection) < CGRectGetMaxY(self.view.bounds) - 1) {
    return 0;
  }
  return intersection.size.height;
}

- (void)keyBoardWillHide:(NSNotification *)notification {
  if ([NEAdaptiveDeviceGate adaptiveHostActive]) {
    self.hasKeyboardFrameInScreen = NO;
    self.keyboardFrameInScreen = CGRectZero;
    self.currentKeyboardHeight = 0;
  }
  if (self.chatInputView.currentType != ChatMenuTypeText) return;
  self.chatInputView.currentButton.selected = NO;
  NSTimeInterval animDuration = 0.1;
  NSNumber *dur = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
  if (dur) animDuration = dur.doubleValue;
  [self layoutInputViewWithAnimation:0 animation:animDuration scrollToBottom:NO];
}

- (void)scrollTableViewToBottom {
  if (self.viewModel.isHistoryChat) {
    [self dataReload];
    return;
  }
  NSInteger row = [self.tableView numberOfRowsInSection:0];
  if (row > 0 && row == (NSInteger)self.viewModel.messages.count) {
    self.isRecvRolling = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
  }
}

- (void)scrollTableViewToBottomWithoutAnimationIfPossible {
  NSInteger row = [self.tableView numberOfRowsInSection:0];
  if (row > 0 && row == (NSInteger)self.viewModel.messages.count) {
    [self.tableView layoutIfNeeded];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
  }
}

- (void)startScrollToBottomAfterReload {
  if (self.viewModel.isHistoryChat || self.viewModel.anchor) {
    return;
  }
  self.needScrollToBottomAfterReload = YES;
  self.scrollToBottomAfterReloadRemainingCount = NEChatInitialScrollToBottomMaxRetryCount;
  [self scrollTableViewToBottomWithoutAnimationIfPossible];
  [self scheduleScrollToBottomAfterReload];
}

- (void)cancelScrollToBottomAfterReload {
  self.needScrollToBottomAfterReload = NO;
  self.scrollToBottomAfterReloadRemainingCount = 0;
  self.isSchedulingScrollToBottomAfterReload = NO;
}

- (void)scheduleScrollToBottomAfterReload {
  if (!self.needScrollToBottomAfterReload ||
      self.isSchedulingScrollToBottomAfterReload ||
      self.scrollToBottomAfterReloadRemainingCount <= 0 ||
      self.viewModel.isHistoryChat ||
      self.viewModel.anchor) {
    return;
  }

  self.isSchedulingScrollToBottomAfterReload = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NEChatInitialScrollToBottomRetryInterval * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [self performScrollToBottomAfterReload];
  });
}

- (void)performScrollToBottomAfterReload {
  self.isSchedulingScrollToBottomAfterReload = NO;
  if (!self.needScrollToBottomAfterReload || self.viewModel.isHistoryChat || self.viewModel.anchor) {
    self.needScrollToBottomAfterReload = NO;
    self.scrollToBottomAfterReloadRemainingCount = 0;
    return;
  }
  if (self.tableView.isDragging || self.tableView.isTracking || self.tableView.isDecelerating) {
    self.needScrollToBottomAfterReload = NO;
    self.scrollToBottomAfterReloadRemainingCount = 0;
    return;
  }

  [self.view layoutIfNeeded];
  [self.tableView layoutIfNeeded];
  [self scrollTableViewToBottomWithoutAnimationIfPossible];

  self.scrollToBottomAfterReloadRemainingCount -= 1;
  if (self.scrollToBottomAfterReloadRemainingCount <= 0) {
    self.needScrollToBottomAfterReload = NO;
    return;
  }
  [self scheduleScrollToBottomAfterReload];
}

- (BOOL)scrollToAnchorMessage:(nullable V2NIMMessage *)message requestId:(NSInteger)requestId {
  if (!message || requestId != self.loadDataRequestId) {
    return NO;
  }
  NSInteger index = NEChatIndexOfMessageInModels(message, self.viewModel.messages);
  NSInteger num = [self.tableView numberOfRowsInSection:0];
  if (index == NSNotFound || index < 0 || index >= num) {
    return NO;
  }

  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  [self.view layoutIfNeeded];
  [self.tableView layoutIfNeeded];
  [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
  [self.tableView layoutIfNeeded];

  self.anchorCell = (NEBaseChatMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  if (index < 0 || index >= (NSInteger)self.viewModel.messages.count) {
    return NO;
  }
  id<MessageModel> model = self.viewModel.messages[index];
  if ([model isKindOfClass:[MessageVideoModel class]]) {
    self.anchorModel = (MessageVideoModel *)model;
  } else {
    self.anchorModel = nil;
  }
  return YES;
}

- (void)scheduleJumpDownMessageAfterLayout {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view layoutIfNeeded];
    [self.tableView layoutIfNeeded];
    [self jumpDownMessage];
  });
}

- (void)layoutInputView:(CGFloat)offset scrollToBottom:(BOOL)scrollToBottom {
  [self layoutInputViewWithAnimation:offset animation:0.1 scrollToBottom:scrollToBottom];
}

- (void)layoutInputViewWithAnimation:(CGFloat)offset animation:(CGFloat)animation scrollToBottom:(BOOL)scrollToBottom {
  __weak typeof(self) weakSelf = self;
  CGFloat topValue = self.normalInputHeight;
  if (self.chatInputView.chatInpuMode != ChatInputModeMultipleReturn) {
    topValue -= self.normalOffset;
  }
  if (offset == 0) {
    self.chatInputView.contentSubView.hidden = YES;
    self.chatInputView.currentButton.selected = NO;
  }
  [UIView animateWithDuration:animation animations:^{
    weakSelf.bottomViewTopAnchor.constant = -topValue - offset;
  } completion:^(__unused BOOL finished) {
    if (!scrollToBottom) return;
    [weakSelf.view layoutIfNeeded];
    [weakSelf.tableView layoutIfNeeded];
    [weakSelf scheduleJumpDownMessageAfterLayout];
  }];
}

- (void)didTranslateResult:(NSString *)content {
  [self.translateLanguageView setTranslateContent:content];
}

- (void)didSelectSticker:(NIMInputSticker *)sticker {
  NSURL *fileURL = sticker.fileURL;
  NSString *path = fileURL.path;
  UIImage *image = fileURL.isFileURL &&
      [[NSFileManager defaultManager] isReadableFileAtPath:path]
      ? [UIImage imageWithContentsOfFile:path]
      : nil;
  if (!image) {
    [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                 desc:@"didSelectSticker: sticker file is invalid"];
    [self.view ne_makeToast:chatLocalizable(@"imageLoadFailed")];
    return;
  }

  size_t pixelWidth = image.CGImage
      ? CGImageGetWidth(image.CGImage)
      : (size_t)llround(image.size.width * image.scale);
  size_t pixelHeight = image.CGImage
      ? CGImageGetHeight(image.CGImage)
      : (size_t)llround(image.size.height * image.scale);
  if (pixelWidth == 0 || pixelHeight == 0 ||
      pixelWidth > INT32_MAX || pixelHeight > INT32_MAX) {
    [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                 desc:@"didSelectSticker: sticker dimensions are invalid"];
    [self.view ne_makeToast:chatLocalizable(@"imageLoadFailed")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel sendImageMessage:path
                             name:fileURL.lastPathComponent
                            width:(int32_t)pixelWidth
                           height:(int32_t)pixelHeight
                   conversationId:nil
                       completion:^(NSError *error) {
    [weakSelf showErrorToast:error defaultToast:nil];
  }];
}

- (void)sendText:(nullable NSString *)text attribute:(nullable NSAttributedString *)attribute {
  NSString *title = self.chatInputView.titleField.text;
  if (title && [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
    // 换行消息
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    dataDic[@"title"] = title;
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0) dataDic[@"body"] = text;
    NSMutableDictionary *attachDic = [NSMutableDictionary dictionary];
    attachDic[@"type"] = @(customRichTextType);
    attachDic[@"data"] = dataDic;
    NSString *rawAttachment = [NECommonUtil getJSONStringFromDictionary:attachDic];
    V2NIMMessage *customMessage = [MessageUtils customMessageWithText:text ?: @"" rawAttachment:rawAttachment];
    customMessage.text = title;
    NSDictionary *remoteExt = [self.chatInputView getAtRemoteExtension:attribute];
    if (remoteExt) {
      customMessage.serverExtension = [NECommonUtil getJSONStringFromDictionary:remoteExt];
    }
    NSString *firstAIUserAccid = nil;
    for (NSString *accid in self.chatInputView.nickAccidList) {
      if ([[NEAIUserManager shared] isAIUser:accid]) {
        firstAIUserAccid = accid;
        break;
      }
    }
    if ([[NEAIUserManager shared] isAIUser:ChatRepo.sessionId]) {
      firstAIUserAccid = ChatRepo.sessionId;
    }
    [self.chatInputView clearAtCache];
    [self.translateLanguageView changeToIdleState:YES];
    __weak typeof(self) weakSelf = self;
    if (self.viewModel.isReplying && self.viewModel.operationModel.message) {
      [self.viewModel replyMessageWithThread:customMessage replyMessage:self.viewModel.operationModel.message aiUserAccid:firstAIUserAccid completion:^(V2NIMMessage *msg, NSError *error) {
        if (error) [weakSelf showErrorToast:error defaultToast:nil];
        [weakSelf didSendFinishAndCheckoutInput];
      }];
      [self closeReply:nil];
    } else {
      [self.viewModel sendRichTextMessage:customMessage title:title body:text aiUserAccid:firstAIUserAccid completion:^(V2NIMMessage *msg, NSError *error) {
        if (error) [weakSelf showErrorToast:error defaultToast:nil];
        [weakSelf didSendFinishAndCheckoutInput];
      }];
    }
  } else {
    [self sendContentText:text attribute:attribute];
  }
}

- (void)sendContentText:(nullable NSString *)text attribute:(nullable NSAttributedString *)attribute {
  NSString *removeSpace = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (!removeSpace || removeSpace.length == 0) {
    self.chatInputView.titleField.text = nil;
    [self.view neMakeToast:chatLocalizable(@"null_message_not_support") position:NEToastPositionCenter];
    return;
  }
  if (!text || text.length == 0) return;
  [self.translateLanguageView changeToIdleState:YES];
  NSDictionary *remoteExt = [self.chatInputView getAtRemoteExtension:attribute];
  NSString *firstAIUserAccid = nil;
  for (NSString *accid in self.chatInputView.nickAccidList) {
    if ([[NEAIUserManager shared] isAIUser:accid]) {
      firstAIUserAccid = accid;
      break;
    }
  }
  if ([[NEAIUserManager shared] isAIUser:ChatRepo.sessionId]) {
    firstAIUserAccid = ChatRepo.sessionId;
  }
  [self.chatInputView clearAtCache];
  __weak typeof(self) weakSelf = self;
  if (self.viewModel.isReplying && self.viewModel.operationModel.message) {
    V2NIMMessage *textMsg = [MessageUtils textMessageWithText:text remoteExt:remoteExt];
    [self.viewModel replyMessageWithThread:textMsg replyMessage:self.viewModel.operationModel.message aiUserAccid:firstAIUserAccid completion:^(V2NIMMessage *msg, NSError *error) {
      if (error) [weakSelf showErrorToast:error defaultToast:nil];
      [weakSelf didSendFinishAndCheckoutInput];
    }];
    [self closeReply:nil];
  } else {
    [self.viewModel sendTextMessage:text remoteExt:remoteExt aiUserAccid:firstAIUserAccid completion:^(V2NIMMessage *msg, NSError *error) {
      if (error) [weakSelf showErrorToast:error defaultToast:nil];
      [weakSelf didSendFinishAndCheckoutInput];
    }];
  }
}

- (void)didSelectMoreCell:(NEInputMoreCell *)cell {
  if (cell.cellData.action) {
    cell.cellData.action(self, cell.cellData);
    return;
  }
  if (cell.cellData.type == NEMoreActionTypeLocation) {
    CLAuthorizationStatus status = kCLAuthorizationStatusNotDetermined;
    if (@available(iOS 14.0, *)) {
      status = self.manager.authorizationStatus;
    } else {
      status = [CLLocationManager authorizationStatus];
    }
    if (status == kCLAuthorizationStatusDenied) {
      [self showSingleAlert:commonLocalizable(@"jump_location_setting") message:nil handler:^{}];
      return;
    }
    if (status == kCLAuthorizationStatusNotDetermined) {
      self.manager.delegate = self;
      [self.manager requestAlwaysAuthorization];
      [self.manager requestWhenInUseAuthorization];
      return;
    }
    [self didToSearchLocationView];
  } else if (cell.cellData.type == NEMoreActionTypeTakePicture) {
    self.isFile = @(NO);
    [self showTakePicture];
  } else if (cell.cellData.type == NEMoreActionTypeFile) {
    self.isFile = @(YES);
    [self showFileAction];
  } else if (cell.cellData.type == NEMoreActionTypeRtc) {
    [self showRtcCallAction];
  } else if (cell.cellData.type == NEMoreActionTypeTranslate) {
    [self showTranslateView];
  } else if (cell.cellData.type == NEMoreActionTypePhoto) {
    [self openPhoto];
  } else if (cell.cellData.type == NEMoreActionTypeAiChat) {
    [self.chatInputView didClickAIChatButton];
  }
}

- (void)openPhoto {
  [self performOpenPhotoAction];
}

- (void)performOpenPhotoAction {
  self.isFile = @(NO);
  [self stopPlay];

  NEChatInputPhotoClickBlock callback = ChatUIConfig.shared.chatInputPhotoClick;
  if (callback) {
    __weak typeof(self) weakSelf = self;
    callback(self, NEMediaTypeAll, NEChatImageCountLimit, ^(NSArray<NEResultModel *> *results, BOOL isOriginal) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf || results.count == 0) return;

      for (NEResultModel *model in results) {
        if (![model isKindOfClass:[NEResultModel class]]) continue;
        if (model.asset.mediaType == PHAssetMediaTypeImage && results.count > NEChatImageCountLimit) {
          [strongSelf.view neMakeToast:[NSString stringWithFormat:commonLocalizable(@"video_count_over_limit"), (int)NEChatImageCountLimit]
                              position:NEToastPositionCenter];
          return;
        }
        if (model.asset.mediaType == PHAssetMediaTypeVideo && results.count > NEChatVideoCountLimit) {
          [strongSelf.view neMakeToast:[NSString stringWithFormat:commonLocalizable(@"video_count_over_limit"), (int)NEChatVideoCountLimit]
                              position:NEToastPositionCenter];
          return;
        }
        [strongSelf sendMediaMessage:model.asset image:model.image isOriginal:isOriginal];
      }
    });
    return;
  }

  [self willSelectImage];
}

- (void)showTakePicture {
  [self showBottomVideoAction:self cameraOnly:NO];
}

- (void)showFileAction {
  [self stopPlay];
  [self showBottomFileAction:self];
}

- (void)showRtcCallAction {
  UIAlertAction *videoCall = [UIAlertAction actionWithTitle:chatLocalizable(@"video_call") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self useToCallViewRouter:2];
  }];
  UIAlertAction *audioCall = [UIAlertAction actionWithTitle:chatLocalizable(@"audio_call") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self useToCallViewRouter:1];
  }];
  UIAlertAction *cancel = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];
  [self showActionSheet:@[videoCall, audioCall, cancel]];
}

- (void)showTranslateView {
  if (self.translateLanguageViewHeightAnchor.constant == 0) {
    self.translateLanguageViewHeightAnchor.constant = 70;
  }
}

- (void)useToCallViewRouter:(NSInteger)type {
  if (![IMKitConfigCenter shared].enableOnlyFriendCall &&
      ![[NEFriendUserCache shared] isFriend:ChatRepo.sessionId]) {
    [self.viewModel insertTipMessage:chatLocalizable(@"disable_stranger_call")
                          createTime:nil
                      conversationId:nil
                            senderId:nil];
    return;
  }

  NSMutableDictionary *param = [NSMutableDictionary dictionary];
  param[@"remoteUserAccid"] = ChatRepo.sessionId;
  param[@"currentUserAccid"] = [IMKitClient.instance account];
  param[@"remoteShowName"] = self.titleContent;
  param[@"type"] = @(type);
  NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:ChatRepo.sessionId];
  if (user) {
    param[@"remoteAvatar"] = user.user.avatar;
  }
  [[Router shared] use:NEChatCallViewRouter parameters:param closure:nil];
}

- (void)didToSearchLocationView {
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"type"] = @(NEMapTypeSearch);
  params[@"nav"] = self.navigationController;
  [[Router shared] use:NERouterUrl.LocationVCRouter parameters:params closure:nil];
}

- (void)willSelectItem:(nullable UIButton *)button index:(NSInteger)index {
  [self removeOperationView:YES];
  if (index == 2 || button.isSelected) {
    if (index == 0 || index == 1 || index == 3) {
      [self layoutInputView:self.bottomExanpndHeight scrollToBottom:YES];
    } else if (index == 2) {
      [self performOpenPhotoAction];
    }
  } else {
    [self layoutInputView:0 scrollToBottom:NO];
  }
}

- (void)setHandsetMode:(OperationItem *)item {
  if (item.type == OperationTypeEarpiece) {
    [self.viewModel setHandSetEnable:NO];
    [self.navigationView setHandsetMode:NO];
    [self.view neMakeToast:chatLocalizable(@"switch_ear") position:NEToastPositionCenter];
  } else if (item.type == OperationTypeSpeaker) {
    [self.viewModel setHandSetEnable:YES];
    [self.navigationView setHandsetMode:YES];
    [self.view neMakeToast:chatLocalizable(@"switch_speaker") position:NEToastPositionCenter];
  }

  if ([self.viewModel getHandSetEnable]) {
    [[NEAudioSessionManager shared] switchToSpeaker];
  } else {
    [[NEAudioSessionManager shared] switchToReceiver];
  }
}

- (void)copyMessage {
  if ([self.viewModel.operationModel isKindOfClass:[MessageTextModel class]]) {
    MessageTextModel *textModel = (MessageTextModel *)self.viewModel.operationModel;
    NSString *selectedText = [textModel selectText];
    if (selectedText.length > 0) {
      [UIPasteboard generalPasteboard].string = selectedText;
      [self.view neMakeToast:commonLocalizable(@"copy_success") position:NEToastPositionCenter];
      return;
    }

    NSString *text = textModel.message.text;
    if (text.length == 0) {
      text = textModel.attributeStr.string;
    }
    if (text.length > 0) {
      [UIPasteboard generalPasteboard].string = text;
      [self.view neMakeToast:commonLocalizable(@"copy_success") position:NEToastPositionCenter];
    }
  }
}

- (void)deleteMessage {
  [self showAlert:chatLocalizable(@"message_delete_confirm") message:nil sure:^(UIAlertAction *action) {
    if (![self isNetworkReachable]) {
      [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      return;
    }

    [self.viewModel deleteMessage:^(NSError *error) {
      if (error) {
        [self showErrorToast:error defaultToast:chatLocalizable(@"failed_operation")];
      }
    }];
  }];
}

- (void)showReplyMessageView:(BOOL)isReEdit {
  self.viewModel.isReplying = YES;
  if (self.chatInputView.chatInpuMode != ChatInputModeMultipleReturn &&
      self.replyView.superview != self.view) {
    [self.view addSubview:self.replyView];
    if ([IMKitConfigCenter shared].enableAIUser) {
      [NSLayoutConstraint activateConstraints:@[
        [self.replyView.leadingAnchor constraintEqualToAnchor:self.bodyBottomView.leadingAnchor],
        [self.replyView.trailingAnchor constraintEqualToAnchor:self.bodyBottomView.trailingAnchor],
        [self.replyView.bottomAnchor constraintEqualToAnchor:self.bodyBottomView.topAnchor],
        [self.replyView.heightAnchor constraintEqualToConstant:36],
      ]];
    } else {
      [NSLayoutConstraint activateConstraints:@[
        [self.replyView.leadingAnchor constraintEqualToAnchor:self.chatInputView.leadingAnchor],
        [self.replyView.trailingAnchor constraintEqualToAnchor:self.chatInputView.trailingAnchor],
        [self.replyView.bottomAnchor constraintEqualToAnchor:self.chatInputView.topAnchor],
        [self.replyView.heightAnchor constraintEqualToConstant:36],
      ]];
    }
  }

  V2NIMMessage *message = self.viewModel.operationModel.message;
  if (!message) {
    return;
  }

  self.replyView.hidden = NO;
  if (isReEdit) {
    self.replyView.textLabel.attributedText = [NEEmotionTool getAttWithStr:self.viewModel.operationModel.replyText ?: @""
                                                                      font:self.replyView.textLabel.font
                                                                     color:self.replyView.textLabel.textColor
                                                                    offset:CGPointZero];
    __weak typeof(self) weakSelf = self;
    [self.viewModel getReplyMessage:message completion:^(id<MessageModel> model) {
      if ([model isKindOfClass:[MessageContentModel class]]) {
        weakSelf.viewModel.operationModel = (MessageContentModel *)model;
      }
    }];
  } else {
    NSString *text = chatLocalizable(@"operation_replay");
    NSString *uid = [ChatMessageHelper getSenderId:message];
    if (uid) {
      NSString *showName = [NETeamUserManager.shared getShowName:uid showAlias:NO];
      if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] != V2NIM_CONVERSATION_TYPE_P2P &&
          ![[IMKitClient instance] isMe:uid]) {
        [self addToAtUsers:[NSString stringWithFormat:@"@%@ ", showName] isReply:YES accid:uid isLongPress:NO];
      }
      showName = [NETeamUserManager.shared getShowName:uid showAlias:YES];
      text = [NSString stringWithFormat:@"%@ %@: %@", text, showName, [ChatMessageHelper contentOfMessage:message]];
      self.replyView.textLabel.attributedText = [NEEmotionTool getAttWithStr:text
                                                                        font:self.replyView.textLabel.font
                                                                       color:self.replyView.textLabel.textColor
                                                                      offset:CGPointZero];
      [self.chatInputView.textView becomeFirstResponder];
    }
  }
}

- (void)closeReply:(nullable UIButton *)button {
  [self.replyView removeFromSuperview];
  self.viewModel.isReplying = NO;
}

- (void)recallMessage {
  __weak typeof(self) weakSelf = self;
  [self showAlert:chatLocalizable(@"message_revoke_confirm") message:nil sure:^(__unused UIAlertAction *action) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (![strongSelf isNetworkReachable]) {
      [strongSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      return;
    }

    V2NIMMessage *message = strongSelf.viewModel.operationModel.message;
    if (!message) {
      return;
    }

    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    NSInteger revokeTimeGap = [[ChatUIConfig shared] getReeditTimeGap];
    if ((NSInteger)(currentTime - message.createTime) >= revokeTimeGap * 60) {
      [strongSelf.view neMakeToast:chatLocalizable(@"ravokable_time_expired") position:NEToastPositionCenter];
      return;
    }

    if (strongSelf.viewModel.operationModel.type == MessageTypeText ||
        strongSelf.viewModel.operationModel.type == MessageTypeRichText) {
      strongSelf.viewModel.operationModel.isReedit = YES;
      strongSelf.viewModel.operationModel.revokeTime = currentTime;
    }

    BOOL isPin = strongSelf.viewModel.operationModel.isPined;
    [strongSelf.viewModel revokeMessage:message completion:^(NSError *error) {
      __strong typeof(weakSelf) innerSelf = weakSelf;
      if (!innerSelf) {
        return;
      }

      if (error) {
        if (error.code == protocolSendFailed) {
          [innerSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
        } else if (error.code == ravokableTimeExpired) {
          [innerSelf.view neMakeToast:chatLocalizable(@"ravokable_time_expired") position:NEToastPositionCenter];
        } else {
          [innerSelf.view neMakeToast:chatLocalizable(@"ravoked_failed") position:NEToastPositionCenter];
        }
        return;
      }

      if (isPin) {
        [innerSelf.viewModel removePinMessage:message completion:^(__unused NSError *removeError, __unused NSInteger index) {
        }];
      }
    }];
  }];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
  return [[NEBaseForwardAlertViewController alloc] init];
}

- (void)addForwardAlertController:(NSArray<ForwardItem *> *)items type:(NSString *)type sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock {
  NEBaseForwardAlertViewController *forwardAlert = [self getForwardAlertController];
  [forwardAlert setItems:items];
  forwardAlert.forwardType = type;
  forwardAlert.sureBlock = sureBlock;
  forwardAlert.sessionName = [ChatMessageHelper getSessionName:ChatRepo.conversationId showAlias:YES];
  [forwardAlert attachToSource:self];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [[UIApplication sharedApplication].keyWindow endEditing:YES];
                 });
}

- (void)forwardMessage {
  [self.viewModel.selectedMessages removeAllObjects];
  if (self.viewModel.operationModel.message) {
    [self.viewModel.selectedMessages addObject:self.viewModel.operationModel.message];
  }
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
  [self didClickSingleForwardButton];
}

- (void)pinMessage {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (!self.viewModel.operationModel.message || self.viewModel.operationModel.isPined || self.viewModel.operationModel.isRevoked) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel addPinMessage:self.viewModel.operationModel.message completion:^(NSError *error, NSInteger index) {
    if (error) {
      if (error.code == pinAlreadyExist) {
        return;
      } else if (error.code == protocolSendFailed) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      } else if (error.code == pinLimitExceeded) {
        [weakSelf.view neMakeToast:chatLocalizable(@"pin_limit_exceeded") position:NEToastPositionCenter];
      } else {
        [weakSelf.view neMakeToast:error.localizedDescription position:NEToastPositionCenter];
      }
      return;
    }

    if (index >= 0) {
      NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
      [weakSelf tableViewReloadIndexs:@[reloadIndexPath] completion:^{
        NSInteger numberOfRows = [weakSelf.tableView numberOfRowsInSection:0];
        if (index == numberOfRows - 1) {
          [weakSelf scrollTableViewToBottom];
        }
      }];
    }
  }];
}

- (void)removePinMessage {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (!self.viewModel.operationModel.isPined || !self.viewModel.operationModel.message) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel removePinMessage:self.viewModel.operationModel.message completion:^(NSError *error, NSInteger index) {
    if (error) {
      if (error.code == pinNotExist) {
        return;
      } else if (error.code == protocolSendFailed) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      } else {
        [weakSelf.view neMakeToast:error.localizedDescription position:NEToastPositionCenter];
      }
      return;
    }

    if (index >= 0) {
      NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
      [weakSelf tableViewReloadIndexs:@[reloadIndexPath] completion:^{
        NSInteger numberOfRows = [weakSelf.tableView numberOfRowsInSection:0];
        if (index == numberOfRows - 1) {
          [weakSelf scrollTableViewToBottom];
        }
      }];
    }
  }];
}

- (void)topMessage {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel topMessage:^(NSError *error) {
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      } else if (error.code == noPermissionOperationCode) {
        [weakSelf.view neMakeToast:chatLocalizable(@"no_permission_tip") position:NEToastPositionCenter];
      } else {
        [weakSelf.view neMakeToast:error.localizedDescription position:NEToastPositionCenter];
      }
    }
  }];
}

- (void)toCollectMessage {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (!self.viewModel.operationModel) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel collectMessage:self.viewModel.operationModel conversationName:self.titleContent completion:^(NSError *error) {
    if (error) {
      if (error.code == collectionLimitCode) {
        [weakSelf.view neMakeToast:chatLocalizable(@"collection_limit") position:NEToastPositionCenter];
      } else {
        [weakSelf.view neMakeToast:commonLocalizable(@"failed_operation") position:NEToastPositionCenter];
      }
    } else {
      [weakSelf.view neMakeToast:chatLocalizable(@"collection_success") position:NEToastPositionCenter];
    }
  }];
}

- (void)voiceToText {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (!self.viewModel.operationModel) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel voiceToText:self.viewModel.operationModel completion:^(NSString *text, NSError *error) {
    if (error || text.length <= 0) {
      [weakSelf.view neMakeToast:chatLocalizable(@"operation_to_text_failed") position:NEToastPositionCenter];
    }
  }];
}

- (void)untopMessage {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel untopMessage:^(NSError *error) {
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      } else if (error.code == noPermissionOperationCode) {
        [weakSelf.view neMakeToast:chatLocalizable(@"no_permission_tip") position:NEToastPositionCenter];
      } else if (error.code == failedOperation) {
        [weakSelf.view neMakeToast:commonLocalizable(@"failed_operation") position:NEToastPositionCenter];
      } else {
        [weakSelf.view neMakeToast:error.localizedDescription position:NEToastPositionCenter];
      }
    }
  }];
}

- (void)selectMessage {
  self.wasCloseToBottomBeforeMutilSelect = [self isCloseToBottom];
  self.isMutilSelect = YES;
  NSArray<id<MessageModel> > *modelSnapshot = [self.viewModel.messages copy];
  for (id<MessageModel> item in modelSnapshot) {
    if ([item isKindOfClass:[MessageContentModel class]]) {
      ((MessageContentModel *)item).isSelected = NO;
    }
  }
  [self.viewModel.selectedMessages removeAllObjects];
  if (self.viewModel.operationModel.message) {
    // The operation menu can retain a value-equivalent model that is not the
    // instance currently owned by the table data source. Resolve the selected
    // message against the live model list so the checkbox survives the first
    // multi-select reload.
    MessageContentModel *selectedModel = nil;
    NSString *messageClientId = self.viewModel.operationModel.message.messageClientId;
    for (id<MessageModel> item in self.viewModel.messages) {
      if (![item isKindOfClass:[MessageContentModel class]]) continue;
      MessageContentModel *candidate = (MessageContentModel *)item;
      BOOL matches = messageClientId.length > 0 &&
          [candidate.message.messageClientId isEqualToString:messageClientId];
      if (!matches && candidate.message == self.viewModel.operationModel.message) matches = YES;
      if (matches) {
        selectedModel = candidate;
        break;
      }
    }
    selectedModel = selectedModel ?: self.viewModel.operationModel;
    selectedModel.isSelected = YES;
    self.viewModel.operationModel = selectedModel;
    if (selectedModel.message) {
      [self.viewModel.selectedMessages addObject:selectedModel.message];
    }
  }
  [self.navigationView setMoreButtonTitle:commonLocalizable(@"cancel") color:UIColor.ne_darkText];
  [self.navigationView addMoreButtonTarget:self selector:@selector(cancelMutilSelectAction)];
  UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:commonLocalizable(@"cancel")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(cancelMutilSelectAction)];
  [cancelItem setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.ne_darkText}
                            forState:UIControlStateNormal];
  self.navigationItem.rightBarButtonItem = cancelItem;
  self.topMessageView.hidden = YES;
  [self setInputView:NO];
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
  [self tableViewReload];
  [self showJumpDownMessage:-1];
}

- (void)cancelMutilSelect {
  BOOL shouldKeepAtBottom = self.wasCloseToBottomBeforeMutilSelect &&
                            self.onReceiveNewMsgs.count == 0 &&
                            !self.viewModel.isHistoryChat;
  self.wasCloseToBottomBeforeMutilSelect = NO;
  self.isMutilSelect = NO;
  [self setInputView:YES];
  [self.viewModel.selectedMessages removeAllObjects];
  NSArray<id<MessageModel> > *modelSnapshot = [self.viewModel.messages copy];
  for (id<MessageModel> item in modelSnapshot) {
    if ([item isKindOfClass:[MessageContentModel class]]) {
      ((MessageContentModel *)item).isSelected = NO;
    }
  }
  [self setMoreButton];
  if (self.viewModel.topMessage) {
    self.topMessageView.hidden = NO;
  }
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
  [self tableViewReload];
  if (shouldKeepAtBottom) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.view layoutIfNeeded];
      [self.tableView layoutIfNeeded];
      NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
      if (rowCount > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:rowCount - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];
      }
      [self showJumpDownMessage:-1];
    });
  } else {
    [self showJumpDownViewAfterLayout];
  }
}

- (void)setInputView:(BOOL)edit {
  [self closeAIChatView];
  self.chatInputView.hidden = !edit;
  self.mutilSelectBottomView.hidden = edit;
  self.bottomViewTopAnchor.constant = edit ? -self.normalInputHeight : -100;
  self.chatInputView.contentSubView.hidden = YES;
  self.chatInputView.currentButton.selected = NO;
}

- (void)startPlay:(nullable id<ChatAudioCellProtocol>)cell model:(nullable MessageAudioModel *)model {
  if (!model) return;
  BOOL isSend = [ChatMessageHelper isSelf:model.message];
  if (self.playingModel == model) {
    if (self.audioPlayer.isPlaying) {
      [self stopPlay];
    } else {
      [self startPlaying:model.message isSend:isSend];
    }
  } else {
    [self stopPlay];
    self.playingCell = cell;
    self.playingModel = model;
    [self startPlaying:model.message isSend:isSend];
  }
}

- (void)stopPlay {
  if (self.audioPlayer && self.audioPlayer.isPlaying) {
    [self.audioPlayer stop];
  }
  self.audioPlayer = nil;
  [self.playingCell stopAnimation:[ChatMessageHelper isSelf:self.playingModel.message]];
  self.playingCell = nil;
  self.playingModel = nil;
  [[NEAudioSessionManager shared] stopProximityMonitoring];
  if (![NEAudioSessionManager shared].isRecording) {
    [[NEAudioSessionManager shared] deactivate];
  }
}

- (void)startRecord {
  [self jumpDownMessage];

  CGFloat duration = 59.6;  // 60 - 0.4, align Swift to avoid audio-to-text overlength.
  if ([NEAuthManager hasAudioAuthorization]) {
    [[NIMSDK sharedSDK].mediaManager recordForDuration:duration];
  } else {
    __weak typeof(self) weakSelf = self;
    [NEAuthManager requestAudioAuthorization:^(BOOL granted) {
      if (!granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf showSingleAlert:commonLocalizable(@"jump_microphone_setting") completion:^{}];
        });
      }
    }];
  }
}

- (void)endRecord:(BOOL)insideView {
  if (insideView) {
    [[NIMSDK sharedSDK].mediaManager stopRecord];
  } else {
    [[NIMSDK sharedSDK].mediaManager cancelRecord];
  }
}

- (void)startPlaying:(nullable V2NIMMessage *)audioMessage isSend:(BOOL)isSend {
  if (!audioMessage) return;
  V2NIMMessageAudioAttachment *attach = (V2NIMMessageAudioAttachment *)audioMessage.attachment;
  if (!attach) return;

  [self.playingCell startAnimation:isSend];

  if ([self.viewModel getHandSetEnable]) {
    [NEAudioSessionManager.shared switchToSpeaker];
  } else {
    [NEAudioSessionManager.shared switchToReceiver];
  }

  NSString *path = attach.path ?: [ChatMessageHelper createFilePath:audioMessage];
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    if (!error && self.audioPlayer) {
      self.audioPlayer.delegate = (id<AVAudioPlayerDelegate>)self;
      [self.audioPlayer play];
    } else {
      [self.playingCell stopAnimation:isSend];
      self.audioPlayer = nil;
      NSLog(@"Error loading audio: %@", error.localizedDescription);
    }
  } else {
    [self.playingCell stopAnimation:isSend];
  }
}

- (void)didTapMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex {
  if (model.type == MessageTypeAudio) {
    [self didTapAudioMessage:cell model:model];
  } else if (model.type == MessageTypeImage) {
    [self didTapImageMessage:model replyIndex:replyIndex];
  } else if (model.type == MessageTypeVideo) {
    [self didTapVideoMessage:cell model:model replyIndex:replyIndex];
  } else if (model.type == MessageTypeFile) {
    [self didTapFileMessage:cell model:model replyIndex:replyIndex];
  } else if (model.type == MessageTypeRtcCallRecord) {
    [self didTapCallMessage:model];
  } else if (model.type == MessageTypeLocation) {
    [self didTapLocationMessage:model];
  } else if (model.type == MessageTypeCustom) {
    [self didTapCustomMessage:model replyIndex:replyIndex];
  } else if (model.type == MessageTypeText || model.type == MessageTypeAIStreamText) {
    if (replyIndex >= 0) {
      [self showTextViewController:model];
    }
  } else if (model.type == MessageTypeRichText) {
    [self didTapCustomMessage:model replyIndex:replyIndex];
  }
}

- (void)didTapAudioMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (![model.message.attachment isKindOfClass:[V2NIMMessageAudioAttachment class]]) {
    return;
  }

  V2NIMMessageAudioAttachment *audioObject = (V2NIMMessageAudioAttachment *)model.message.attachment;
  NSString *path = audioObject.path ?: [ChatMessageHelper createFilePath:model.message];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    if (audioObject.url.length > 0) {
      __weak typeof(self) weakSelf = self;
      __weak typeof(cell) weakCell = cell;
      __weak typeof(model) weakModel = model;
      [self.viewModel downLoad:audioObject.url filePath:path progress:nil completion:^(NSString *p, NSError *error) {
        if (!error) {
          [weakSelf startPlay:(id<ChatAudioCellProtocol>)weakCell model:(MessageAudioModel *)weakModel];
        } else {
          [weakSelf showErrorToast:error defaultToast:nil];
        }
      }];
    }
  } else {
    [self startPlay:(id<ChatAudioCellProtocol>)cell model:(MessageAudioModel *)model];
  }
}

- (void)didTapImageMessage:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex {
  if (![model.message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) {
    return;
  }

  V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)model.message.attachment;
  NSString *imageUrl = @"";
  if (imageObject.url.length > 0) {
    imageUrl = imageObject.url;
  } else if (imageObject.path.length > 0 &&
             [[NSFileManager defaultManager] fileExistsAtPath:imageObject.path]) {
    imageUrl = imageObject.path;
  }

  if (imageUrl.length <= 0) {
    return;
  }

  NSInteger currentIndex = 0;
  NSMutableArray<NSString *> *showImages =
      [[ChatMessageHelper getUrls:model
                         messages:(NSArray<MessageContentModel *> *)self.viewModel.messages
                      currentIndex:&currentIndex] mutableCopy];
  if (![showImages containsObject:imageUrl]) {
    [showImages insertObject:imageUrl atIndex:0];
  }

  PhotoBrowserController *showController =
      [[PhotoBrowserController alloc] initWithUrls:showImages
                                               url:imageUrl
                                       currenIndex:currentIndex];
  showController.modalPresentationStyle = UIModalPresentationOverFullScreen;

  BOOL isKeyboardActive = self.chatInputView.textView.isFirstResponder ||
                          self.chatInputView.titleField.isFirstResponder;
  NSUInteger messageCountBeforePreview = self.viewModel.messages.count;
  [self.chatInputView.textView resignFirstResponder];
  [self.chatInputView.titleField resignFirstResponder];
  __weak typeof(self) weakSelf = self;
  showController.onDismiss = ^{
    if (isKeyboardActive && weakSelf.viewModel.messages.count == messageCountBeforePreview) {
      [weakSelf scrollTableViewToBottom];
    }
  };
  [self stopPlay];
  [self presentAdaptivePreview:showController animated:NO completion:nil];
}

- (void)didTapVideoMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex {
  if (![model.message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) {
    return;
  }

  V2NIMMessageVideoAttachment *object = (V2NIMMessageVideoAttachment *)model.message.attachment;
  NSString *path = [ChatMessageHelper videoLocalPathForMessage:model.message];
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    [self stopPlay];
    [NEAudioSessionManager.shared switchToSpeaker];
    [NEAudioSessionManager.shared stopProximityMonitoring];

    VideoPlayerViewController *videoPlayer = [[VideoPlayerViewController alloc] init];
    videoPlayer.modalPresentationStyle = UIModalPresentationOverFullScreen;
    videoPlayer.videoUrl = [NSURL fileURLWithPath:path];
    videoPlayer.totalTime = (NSInteger)object.duration;
    [self presentAdaptivePreview:videoPlayer animated:YES completion:nil];
  } else {
    if (replyIndex >= 0) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:replyIndex inSection:0];
      if ([self.tableView cellForRowAtIndexPath:indexPath]) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
      } else {
        self.viewModel.anchor = model.message;
        [self loadData];
      }
    }

    [self downloadFile:cell model:model url:object.url path:path];
  }
}

- (void)didTapFileMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex {
  if (![model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) {
    return;
  }

  V2NIMMessageFileAttachment *object = (V2NIMMessageFileAttachment *)model.message.attachment;
  NSString *path = object.path ?: [ChatMessageHelper createFilePath:model.message];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    if (replyIndex >= 0) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:replyIndex inSection:0];
      if ([self.tableView cellForRowAtIndexPath:indexPath]) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
      } else {
        self.viewModel.anchor = model.message;
        [self loadData];
      }
    }

    [self downloadFile:cell model:model url:object.url path:path];
  } else {
    NSURL *url = [NSURL fileURLWithPath:path];
    if ([ChatMessageHelper isImageFileAttachment:object]) {
      PhotoBrowserController *showController = [[PhotoBrowserController alloc] initWithUrls:@[path] url:path];
      showController.modalPresentationStyle = UIModalPresentationOverFullScreen;
      [self presentAdaptivePreview:showController animated:NO completion:nil];
    } else {
      self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:url];
      self.interactionController.delegate = self;
      if (![self.interactionController presentPreviewAnimated:YES]) {
        [self.interactionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
      }
    }
  }
}

- (void)didTapCallMessage:(nullable MessageContentModel *)model {
  if (![model.message.attachment isKindOfClass:[V2NIMMessageCallAttachment class]]) {
    return;
  }
  V2NIMMessageCallAttachment *attachment = (V2NIMMessageCallAttachment *)model.message.attachment;
  [self useToCallViewRouter:attachment.type];
}

- (void)didTapLocationMessage:(nullable MessageContentModel *)model {
  if (!model.message) return;
  V2NIMMessageLocationAttachment *locationAttach = (V2NIMMessageLocationAttachment *)model.message.attachment;
  if (!locationAttach) return;
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"type"] = @(NEMapTypeDetail);
  params[@"nav"] = self.navigationController;
  params[@"lat"] = @(locationAttach.latitude);
  params[@"lng"] = @(locationAttach.longitude);
  params[@"locationTitle"] = locationAttach.address ?: @"";
  [[Router shared] use:NERouterUrl.LocationVCRouter parameters:params closure:nil];
}

- (void)didTapCustomMessage:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex {
  if (model.customType == customRichTextType) {
    if (replyIndex >= 0) {
      [self showTextViewController:model];
    }
  } else if (model.customType == customMultiForwardType) {
    NSDictionary *data = [NECustomUtils dataOfCustomMessage:model.message.attachment];
    if (![data isKindOfClass:[NSDictionary class]]) {
      return;
    }

    NSString *url = data[@"url"];
    NSString *md5 = data[@"md5"];
    NSString *fileDirectory = [NEPathUtils getDirectoryForDocuments:[NSString stringWithFormat:@"%@file/", imkitDir]];
    if (!fileDirectory) {
      return;
    }

    NSString *fileName = [multiForwardFileName stringByAppendingString:model.message.messageClientId ?: @""];
    NSString *filePath = [fileDirectory stringByAppendingString:fileName];
    MultiForwardViewController *multiForwardVC = [self getMultiForwardViewController:url filePath:filePath md5:md5];
    [self.navigationController pushViewController:multiForwardVC animated:YES];
  }
}

- (void)downloadFile:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model url:(nullable NSString *)url path:(NSString *)path {
  if (url.length == 0 || ![model isKindOfClass:[MessageVideoModel class]]) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag] desc:[NSString stringWithFormat:@"%s MessageVideoModel not exit", __FUNCTION__]];
    return;
  }

  MessageVideoModel *fileModel = (MessageVideoModel *)model;
  if (fileModel.state == DownloadStateDownalod) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag] desc:[NSString stringWithFormat:@"%s downLoad state, click ingore", __FUNCTION__]];
    return;
  }

  NEBaseChatMessageCell *fileCell = [cell isKindOfClass:[NEBaseChatMessageCell class]] ? (NEBaseChatMessageCell *)cell : nil;
  fileModel.state = DownloadStateDownalod;
  fileModel.progress = 0;
  if (fileCell) {
    BOOL isSend = [ChatMessageHelper isSelf:fileModel.message];
    [fileCell setModel:fileModel isSend:isSend];
    [fileCell uploadProgress:0];
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel downLoad:url filePath:path progress:^(NSUInteger progress) {
    [weakSelf setModelProgress:model.message progress:progress];
  } completion:^(NSString *filePath, NSError *error) {
    if (error) {
      [weakSelf showErrorToast:error defaultToast:chatLocalizable(@"download_failed")];
    } else if (filePath.length > 0) {
      fileModel.state = DownloadStateSuccess;
    }
  }];
}

- (void)setModelProgress:(nullable V2NIMMessage *)message progress:(NSUInteger)progress {
  if (!message) return;
  for (NSInteger i = 0; i < self.viewModel.messages.count; i++) {
    id<MessageModel> model = self.viewModel.messages[i];
    if ([model.message.messageClientId isEqualToString:message.messageClientId]) {
      if ([model isKindOfClass:[MessageVideoModel class]]) {
        MessageVideoModel *videoModel = (MessageVideoModel *)model;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
          videoModel.cell = (NEBaseChatMessageCell *)cell;
        }
        [videoModel setModelProgress:progress];
      }
      break;
    }
  }
}

- (void)showTextViewController:(nullable MessageContentModel *)model {
  if (![model isKindOfClass:[MessageTextModel class]]) {
    return;
  }

  MessageTextModel *textModel = (MessageTextModel *)model;
  NSString *title = [NECustomUtils titleOfRichText:textModel.message.attachment];
  NSAttributedString *body = textModel.attributeStr;
  if (!(title.length > 0) && !(body.string.length > 0)) {
    return;
  }

  TextViewController *textViewController = [self getTextViewController:title body:body];
  [textViewController presentAsColumnChildFrom:self];
}

- (TextViewController *)getTextViewController:(nullable NSString *)title body:(nullable NSAttributedString *)body {
  TextViewController *textViewController = [[TextViewController alloc] initWithTitle:title body:body];
  [textViewController updateLinkDetection];
  return textViewController;
}

- (MultiForwardViewController *)getMultiForwardViewController:(nullable NSString *)messageAttachmentUrl filePath:(NSString *)messageAttachmentFilePath md5:(nullable NSString *)messageAttachmentMD5 {
  return [[MultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl attachmentFilePath:messageAttachmentFilePath attachmentMD5:messageAttachmentMD5];
}

- (NSArray<NEMoreItemModel *> *)expandMoreAction {
  V2NIMConversationType conversationType = [V2NIMConversationIdUtil conversationType:ChatRepo.conversationId];
  NSMutableArray<NEMoreItemModel *> *items =
      [[[NEChatUIKitClient instance] getMoreActionDataWithSessionType:conversationType
                                                       viewController:self] mutableCopy];
  if (!items) {
    return @[];
  }

  if ([NEChatKitClient instance].delegate == nil) {
    [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
      return item.type != NEMoreActionTypeLocation;
    }]];
  }

  if ([[NEAIUserManager shared] isAIUser:ChatRepo.sessionId] ||
      [[NEAIRobotManager shared] isRobot:ChatRepo.sessionId]) {
    [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
      return item.type != NEMoreActionTypeRtc;
    }]];
  }

  if ([[NEAIUserManager shared] getAITranslateUser] == nil) {
    [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
      return item.type != NEMoreActionTypeTranslate;
    }]];
  }

  if (conversationType != V2NIM_CONVERSATION_TYPE_P2P) {
    [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
      return item.type != NEMoreActionTypeAiChat;
    }]];
  }

  return [items copy];
}

- (NEBaseChatInputView *)getMenuView:(V2NIMConversationType)conversationType {
  return [[NEBaseChatInputView alloc] initWithFrame:CGRectZero];
}

- (NEBaseChatNewMessageView *)getJumpDownView {
  return [[NEBaseChatNewMessageView alloc] init];
}

- (NEBaseChatLastReadPositionView *)getLastReadPositionView {
  return [[NEBaseChatLastReadPositionView alloc] init];
}

- (void)setMutilSelectBottomView {
  self.mutilSelectBottomView.backgroundColor =
      [ChatUIConfig shared].messageProperties.chatViewBackgroundSolid ?
          [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor :
          UIColor.ne_backgroundColor;
}

- (NEBaseSelectUserViewController *)getUserSelectVC:(BOOL)showTeamMembers {
  return [[NEBaseSelectUserViewController alloc] initWithConversationId:ChatRepo.conversationId showSelf:NO showTeamMembers:showTeamMembers];
}

- (void)showUserSelectVC:(BOOL)showTeamMembers {
  NEBaseSelectUserViewController *vc = [self getUserSelectVC:showTeamMembers];
  vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
  self.definesPresentationContext = YES;
  __weak typeof(self) weakSelf = self;
  vc.selectedBlock = ^(NSInteger index, NETeamMemberInfoModel *model) {
    NSString *addText = @"";
    NSString *accid = @"";

    if (!model && showTeamMembers) {
      addText = chatLocalizable(@"user_select_all");
    } else {
      addText = [model showNameInTeam] ?: @"";
      if (addText.length == 0) {
        addText = model.nimUser.user.accountId ?: @"";
      }
      accid = model.nimUser.user.accountId ?: @"";
    }
    addText = [@"@" stringByAppendingString:addText];
    [weakSelf addToAtUsers:addText isReply:NO accid:accid isLongPress:NO];
  };
  [self presentViewController:vc animated:YES completion:nil];
  // Selection and cancellation both return through a keyboard transition.
  self.restoringMentionInput = YES;
}

- (void)showErrorToast:(nullable NSError *)error defaultToast:(nullable NSString *)defaultToast {
  if (!error) {
    return;
  }

  if (error.code == protocolSendFailed) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
  } else if (error.code == fileUploadFailed) {
    [self.view neMakeToast:commonLocalizable(@"file_upload_failed") position:NEToastPositionCenter];
  } else if (error.code == aiMessagesNotExist) {
    [self.view neMakeToast:chatLocalizable(@"message_not_found") position:NEToastPositionCenter];
  } else if (defaultToast.length > 0) {
    [self.view neMakeToast:defaultToast position:NEToastPositionCenter];
  } else {
    [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                desc:[NSString stringWithFormat:@"%s failed, error: %@", __FUNCTION__, error.localizedDescription]];
  }
}

- (void)tableViewDeleteIndexs:(NSArray<NSIndexPath *> *)indexs {
  if (self.isLoadingData) return;
  NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
  NSArray<NSIndexPath *> *uniqueIndexs = NEChatUniqueIndexPaths(indexs);
  NSInteger newRows = self.viewModel.messages.count;
  if (rowCount <= 0 || rowCount - (NSInteger)uniqueIndexs.count != newRows) {
    [self.tableView reloadData];
    return;
  }
  NSMutableArray<NSIndexPath *> *validIndexs = [NSMutableArray array];
  for (NSIndexPath *index in uniqueIndexs) {
    if (![index isKindOfClass:[NSIndexPath class]]) continue;
    if (index.section == 0 && index.row >= 0 && index.row < rowCount) {
      [validIndexs addObject:index];
    }
  }
  if (validIndexs.count != uniqueIndexs.count) {
    [self.tableView reloadData];
    return;
  }
  @try {
    __weak typeof(self) weakSelf = self;
    [self.tableView deleteData:validIndexs
                     animation:UITableViewRowAnimationFade
                    completion:^(__unused BOOL finished) {
      if ([weakSelf.tableView numberOfRowsInSection:0] != (NSInteger)weakSelf.viewModel.messages.count) {
        [weakSelf.tableView reloadData];
      }
    }];
  } @catch (NSException *exception) {
    [self.tableView reloadData];
  }
}

- (void)tableViewReloadIndexs:(NSArray<NSIndexPath *> *)indexs completion:(nullable void (^)(void))completion {
  if (self.isLoadingData) return;
  NSInteger tableRowCount = [self.tableView numberOfRowsInSection:0];
  NSInteger modelRowCount = self.viewModel.messages.count;
  NSInteger dataSourceRowCount = NEChatDataSourceRowCount(self.tableView, modelRowCount);
  if (tableRowCount != dataSourceRowCount || dataSourceRowCount != modelRowCount) {
    [self tableViewReload];
    if (completion) completion();
    return;
  }

  NSMutableArray<NSIndexPath *> *validIndexs = [NSMutableArray array];
  for (NSIndexPath *index in NEChatUniqueIndexPaths(indexs)) {
    if (index.section == 0 && index.row >= 0 && index.row < tableRowCount) {
      [validIndexs addObject:index];
    }
  }
  if (validIndexs.count == 0) {
    if (completion) completion();
    return;
  }
  @try {
    [UIView performWithoutAnimation:^{
      [self.tableView reloadData:validIndexs
                       animation:UITableViewRowAnimationNone
                      completion:^(__unused BOOL finished) {
                        if (completion) completion();
      }];
    }];
  } @catch (NSException *exception) {
    [self tableViewReload];
    if (completion) completion();
  }
}

- (void)reloadSendMessage:(nullable V2NIMMessage *)message fallbackIndex:(nullable NSIndexPath *)index retry:(BOOL)retry {
  if (self.isLoadingData) {
    if (retry) {
      __weak typeof(self) weakSelf = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf reloadSendMessage:message fallbackIndex:index retry:NO];
      });
    }
    return;
  }

  NSInteger row = NSNotFound;
  if ([index isKindOfClass:[NSIndexPath class]] && index.section == 0) {
    NSInteger candidateRow = index.row;
    if (candidateRow >= 0 && candidateRow < (NSInteger)self.viewModel.messages.count) {
      id<MessageModel> candidateModel = self.viewModel.messages[candidateRow];
      if (NEChatMessageIsSame(candidateModel.message, message)) {
        row = candidateRow;
      }
    }
  }
  if (row == NSNotFound) {
    row = NEChatIndexOfMessageInModels(message, self.viewModel.messages);
  }
  if (row == NSNotFound || row < 0 || row >= (NSInteger)self.viewModel.messages.count) {
    return;
  }

  NSIndexPath *reloadIndex = [NSIndexPath indexPathForRow:row inSection:0];
  NSInteger tableRows = [self.tableView numberOfRowsInSection:0];
  if (row < tableRows) {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:reloadIndex];
    id<MessageModel> model = self.viewModel.messages[row];
    if ([cell isKindOfClass:[NEChatBaseCell class]] &&
        [model isKindOfClass:[MessageContentModel class]]) {
      MessageContentModel *contentModel = (MessageContentModel *)model;
      BOOL isSend = [ChatMessageHelper isSelf:contentModel.message];
      [(NEChatBaseCell *)cell setModel:contentModel isSend:isSend];
      if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
        [(NEBaseChatMessageCell *)cell setSelect:contentModel enableSelect:self.isMutilSelect];
      }
    }
    return;
  }

  if (retry) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf reloadSendMessage:message fallbackIndex:reloadIndex retry:NO];
    });
    return;
  }

  [self.tableView reloadData];
}

- (void)reloadTableViewAfterRowCountMismatchScrollToBottom:(BOOL)scrollToBottom {
  [self.tableView reloadData];
  if (!scrollToBottom) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [self jumpDownMessage];
  });
}

- (void)tableViewReload {
  [self.tableView reloadData];
  [self scheduleScrollToBottomAfterReload];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self refreshLastReadPositionVisibility];
  });
  if (self.needCheckJumpDownAfterReload) {
    self.needCheckJumpDownAfterReload = NO;
    [self showJumpDownViewAfterLayout];
  }
}

- (void)dataReload {
  if (self.viewModel.isHistoryChat) {
    self.suppressHistoryAutoLoadUntilUserScroll = NO;
    self.viewModel.anchor = nil;
    [self loadData];
  }
}

- (void)insertRows:(NSArray<NSIndexPath *> *)indexs scrollToBottom:(BOOL)scrollToBottom {
  if (!self.hasFirstLoadData) {
    return;
  }
  NSInteger oldRows = [self.tableView numberOfRowsInSection:0];
  if (oldRows == 0) {
    [self reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
    return;
  }
  if (oldRows == (NSInteger)self.viewModel.messages.count) {
    [self reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
    return;
  }
  NSArray<NSIndexPath *> *uniqueIndexs = NEChatUniqueIndexPaths(indexs);
  NSInteger newRows = self.viewModel.messages.count;
  NSInteger dataSourceRowCount = NEChatDataSourceRowCount(self.tableView, newRows);
  if (dataSourceRowCount != newRows ||
      oldRows + (NSInteger)uniqueIndexs.count != dataSourceRowCount) {
    [self reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
    return;
  }
  NSMutableArray<NSIndexPath *> *validIndexs = [NSMutableArray array];
  for (NSIndexPath *index in uniqueIndexs) {
    if (![index isKindOfClass:[NSIndexPath class]]) continue;
    if (index.section == 0 && index.row >= 0 && index.row < newRows) {
      [validIndexs addObject:index];
    }
  }
  if (validIndexs.count == uniqueIndexs.count) {
    __weak typeof(self) weakSelf = self;
    @try {
      [self.tableView insertData:validIndexs
                      animation:UITableViewRowAnimationNone
                      completion:^(__unused BOOL finished) {
        NSInteger modelRows = weakSelf.viewModel.messages.count;
        NSInteger tableRows = [weakSelf.tableView numberOfRowsInSection:0];
        NSInteger dataSourceRows = NEChatDataSourceRowCount(weakSelf.tableView, modelRows);
        if (tableRows != dataSourceRows || dataSourceRows != modelRows) {
          [weakSelf reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
          return;
        }
        if (scrollToBottom) {
          [weakSelf jumpDownMessage];
        }
      }];
    } @catch (NSException *exception) {
      [self reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
    }
  } else {
    [self reloadTableViewAfterRowCountMismatchScrollToBottom:scrollToBottom];
  }
}

- (void)addToAtUsers:(NSString *)addText isReply:(BOOL)isReply accid:(NSString *)accid isLongPress:(BOOL)isLongPress {
  UIFont *font = self.chatInputView.textView.font;
  if (!font) {
    return;
  }

  NSAttributedString *currentAttributedText =
      self.chatInputView.textView.attributedText ?: [[NSAttributedString alloc] initWithString:@""];
  NSMutableAttributedString *mutaString =
      [[NSMutableAttributedString alloc] initWithAttributedString:currentAttributedText];
  NSAttributedString *atString =
      [[NSAttributedString alloc] initWithString:addText
                                      attributes:@{
                                        NSForegroundColorAttributeName : UIColor.ne_defaultPrimaryColor,
                                        NSFontAttributeName : font
                                      }];

  NSRange selectRange = NSMakeRange(0, 0);
  NSUInteger location = 0;
  if (self.chatInputView.textView.isFirstResponder) {
    location = self.chatInputView.textView.selectedRange.location;
    selectRange = self.chatInputView.textView.selectedRange;
  } else {
    location = mutaString.length;
    selectRange = NSMakeRange(location, 0);
  }

  location = MIN(location, (NSUInteger)mutaString.length);
  selectRange.location = MIN(selectRange.location, (NSUInteger)mutaString.length);

  NSString *mentionAccid = accid.length > 0 ? accid : @"ait_all";
  if (isReply || isLongPress) {
    NSMutableAttributedString *tempAttributedString =
        [[NSMutableAttributedString alloc] initWithAttributedString:atString];
    NSAttributedString *spaceString =
        [[NSAttributedString alloc] initWithString:@" "
                                        attributes:@{NSFontAttributeName : font}];
    [tempAttributedString appendAttributedString:spaceString];
    [mutaString insertAttributedString:tempAttributedString atIndex:location];

    [self.chatInputView.nickAccidList addObject:mentionAccid];
    self.chatInputView.nickAccidDic[addText] = mentionAccid;
    self.chatInputView.textView.attributedText = mutaString;
    self.chatInputView.textView.selectedRange =
        NSMakeRange(MIN(selectRange.location + tempAttributedString.length, (NSUInteger)mutaString.length), 0);
    return;
  }

  NSUInteger insertionLocation = selectRange.location;
  if (insertionLocation > 0 && insertionLocation <= (NSUInteger)mutaString.length &&
      [[mutaString.string substringWithRange:NSMakeRange(insertionLocation - 1, 1)] isEqualToString:@"@"]) {
    insertionLocation -= 1;
    [mutaString replaceCharactersInRange:NSMakeRange(insertionLocation, 1) withString:@""];
  } else if (insertionLocation == 0 && mutaString.length > 0 &&
             [[mutaString.string substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"@"]) {
    [mutaString replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
  }

  NSMutableAttributedString *tempAttributedString =
      [[NSMutableAttributedString alloc] initWithAttributedString:atString];
  NSAttributedString *spaceString =
      [[NSAttributedString alloc] initWithString:@" "
                                      attributes:@{NSFontAttributeName : font}];
  [tempAttributedString appendAttributedString:spaceString];
  [mutaString insertAttributedString:tempAttributedString atIndex:insertionLocation];

  [self.chatInputView.nickAccidList addObject:mentionAccid];
  self.chatInputView.nickAccidDic[addText] = mentionAccid;

  self.chatInputView.textView.attributedText = mutaString;
  self.chatInputView.textView.selectedRange =
      NSMakeRange(MIN(insertionLocation + tempAttributedString.length, (NSUInteger)mutaString.length), 0);
}

- (void)setMoreButton {
  if ([ChatUIConfig shared].messageProperties.showTitleBarRightIcon) {
    UIImage *image = [ChatUIConfig shared].messageProperties.titleBarRightRes ?: [coreLoader() loadImage:@"three_point"];
    [self addRightAction:image action:@selector(toSetting) target:self];
    [self.navigationView setMoreButtonImage:image];
  } else {
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationView.moreButton.hidden = YES;
  }
}

- (void)showJumpDownView {
  NSInteger messageCount = [self.tableView numberOfRowsInSection:0];
  if (messageCount <= 0) {
    [self showJumpDownMessage:-1];
    return;
  }

  BOOL reachedIndicatorTarget = self.onReceiveNewMsgs.count == 0 ? [self isLastMessageVisible] : [self isLatestPendingNewMessageVisible];
  if (reachedIndicatorTarget) {
    [self.onReceiveNewMsgs removeAllObjects];
    [self showJumpDownMessage:-1];
    return;
  }

  NEChatDeduplicateMessages(self.onReceiveNewMsgs);
  if (!self.isMutilSelect) {
    [self showJumpDownMessage:self.onReceiveNewMsgs.count];
  }
}

- (void)showJumpDownViewAfterLayout {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view layoutIfNeeded];
    [self.tableView layoutIfNeeded];
    [self showJumpDownView];
  });
}

- (BOOL)isLastMessageVisible {
  NSInteger messageCount = [self.tableView numberOfRowsInSection:0];
  if (messageCount <= 0) {
    return YES;
  }

  NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:messageCount - 1 inSection:0];
  UITableViewCell *lastCell = [self.tableView cellForRowAtIndexPath:lastIndexPath];
  if (lastCell && [self.tableView.visibleCells containsObject:lastCell]) {
    return YES;
  }

  NSArray<NSIndexPath *> *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
  if ([visibleIndexPaths containsObject:lastIndexPath]) {
    return YES;
  }

  CGRect lastRect = [self.tableView rectForRowAtIndexPath:lastIndexPath];
  if (CGRectIsNull(lastRect) || CGRectIsEmpty(lastRect)) {
    return NO;
  }

  UIEdgeInsets inset = self.tableView.contentInset;
  if (@available(iOS 11.0, *)) {
    inset = self.tableView.adjustedContentInset;
  }
  CGFloat visibleMinY = self.tableView.contentOffset.y + inset.top;
  CGFloat visibleMaxY = self.tableView.contentOffset.y + self.tableView.bounds.size.height - inset.bottom;
  return CGRectGetMaxY(lastRect) > visibleMinY && CGRectGetMinY(lastRect) < visibleMaxY;
}

- (BOOL)isLatestPendingNewMessageVisible {
  V2NIMMessage *pending = [self.onReceiveNewMsgs sortedArrayUsingComparator:^NSComparisonResult(V2NIMMessage *lhs, V2NIMMessage *rhs) {
    if (lhs.createTime < rhs.createTime) return NSOrderedAscending;
    if (lhs.createTime > rhs.createTime) return NSOrderedDescending;
    return NSOrderedSame;
  }].lastObject;
  if (!pending) return NO;

  for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
    if (indexPath.row >= (NSInteger)self.viewModel.messages.count) continue;
    V2NIMMessage *visible = self.viewModel.messages[indexPath.row].message;
    if (NEChatMessageIsSame(pending, visible)) return YES;
  }
  return NO;
}

- (BOOL)isCloseToBottom {
  CGFloat visibleHeight = self.tableView.frame.size.height - self.tableView.contentInset.top - self.tableView.contentInset.bottom;
  CGFloat y = self.tableView.contentOffset.y + self.tableView.contentInset.top;
  CGFloat threshold = 50.0;
  return y + visibleHeight >= self.tableView.contentSize.height - threshold;
}

- (void)loadDataFinish {
  self.hasFirstLoadData = YES;
  if (self.pendingNewMessages.count > 0) {
    NEChatAppendUniqueMessages(self.onReceiveNewMsgs, self.pendingNewMessages);
    [self.pendingNewMessages removeAllObjects];
  }
  NEChatRetainMessagesAfterAnchor(self.onReceiveNewMsgs, self.messageIndicatorCutoffAnchor);
  if (self.viewModel.anchor || self.viewModel.isHistoryChat || self.onReceiveNewMsgs.count > 0) {
    self.needCheckJumpDownAfterReload = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !self.needCheckJumpDownAfterReload) {
        return;
      }
      self.needCheckJumpDownAfterReload = NO;
      [self.view layoutIfNeeded];
      [self.tableView layoutIfNeeded];
      [self showJumpDownView];
    });
  }
}

- (void)showLeaveTeamAlert {
  [self showSingleAlert:chatLocalizable(@"team_has_been_quit") message:nil handler:^{
    [self.navigationController popToRootViewControllerAnimated:YES];
  }];
}

- (void)showDismissTeamAlert {
  [self showSingleAlert:chatLocalizable(@"team_has_been_removed") message:nil handler:^{
    [self.navigationController popToRootViewControllerAnimated:YES];
  }];
}

- (void)dismissAlert {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didClickMultiForwardButton {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (self.viewModel.selectedMessages.count > customMultiForwardLimitCount) {
    [self.view neMakeToast:[NSString stringWithFormat:chatLocalizable(@"multiForward_forward_limit"),
                                                      (int)customMultiForwardLimitCount]
                  position:NEToastPositionCenter];
    return;
  }

  NSMutableArray<V2NIMMessage *> *invalidMessages = [NSMutableArray array];
  NSInteger forwardDepth = 0;
  NSArray<V2NIMMessage *> *selectedSnapshot = [self.viewModel.selectedMessages copy];
  for (V2NIMMessage *msg in selectedSnapshot) {
    if (msg.sendingState == V2NIM_MESSAGE_SENDING_STATE_FAILED ||
        msg.messageStatus.errorCode != operationSuccess ||
        ![self canMultiForwardMessage:msg]) {
      [invalidMessages addObject:msg];
      continue;
    }

    NSDictionary *data = [NECustomUtils dataOfCustomMessage:msg.attachment];
    NSNumber *depthValue = [data[@"depth"] isKindOfClass:[NSNumber class]] ? data[@"depth"] : nil;
    if (depthValue) {
      NSInteger currentDepth = depthValue.integerValue;
      if (currentDepth >= customMultiForwardMaxDepth) {
        [invalidMessages addObject:msg];
      } else if (currentDepth >= forwardDepth) {
        forwardDepth = currentDepth;
      }
    }
  }

  forwardDepth += 1;
  __weak typeof(self) weakSelf = self;
  if (invalidMessages.count > 0) {
    [self showAlert:chatLocalizable(@"exception_description")
            message:chatLocalizable(@"exist_invalid")
               sure:^(UIAlertAction *action) {
                 [weakSelf filterSelectedMessage:invalidMessages];
                 if (weakSelf.viewModel.selectedMessages.count > 0) {
                   [weakSelf forwardMessages:YES depth:forwardDepth];
                 }
               }];
  } else if (self.viewModel.selectedMessages.count > 0) {
    [self forwardMessages:YES depth:forwardDepth];
  }
}

- (BOOL)canMultiForwardMessage:(V2NIMMessage *)message {
  if (!message) {
    return NO;
  }

  NSNumber *customType = [NECustomUtils typeOfCustomMessage:message.attachment];
  if (customType.integerValue == customMultiForwardType) {
    NSDictionary *data = [NECustomUtils dataOfCustomMessage:message.attachment];
    NSString *url = [data[@"url"] isKindOfClass:[NSString class]] ? data[@"url"] : nil;
    if (url.length == 0) {
      return NO;
    }
  }

  V2NIMMessage *forwardMessage = [MessageUtils forwardMessageWithMessage:message];
  [ChatMessageHelper clearForwardReplyMark:forwardMessage];
  NSString *serialized = [V2NIMMessageConverter messageSerialization:forwardMessage];
  return serialized.length > 0;
}

- (void)didClickSingleForwardButton {
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }

  if (self.viewModel.selectedMessages.count > customSingleForwardLimitCount) {
    [self.view neMakeToast:[NSString stringWithFormat:chatLocalizable(@"per_item_forward_limit"),
                                                      (int)customSingleForwardLimitCount]
                  position:NEToastPositionCenter];
    return;
  }

  NSMutableArray<V2NIMMessage *> *invalidMessages = [NSMutableArray array];
  NSArray<V2NIMMessage *> *selectedSnapshot = [self.viewModel.selectedMessages copy];
  for (V2NIMMessage *msg in selectedSnapshot) {
    if (msg.messageType == V2NIM_MESSAGE_TYPE_AUDIO ||
        msg.messageType == V2NIM_MESSAGE_TYPE_CALL ||
        msg.sendingState == V2NIM_MESSAGE_SENDING_STATE_FAILED ||
        msg.messageStatus.errorCode != operationSuccess) {
      [invalidMessages addObject:msg];
    }
  }

  __weak typeof(self) weakSelf = self;
  if (invalidMessages.count > 0) {
    [self showAlert:chatLocalizable(@"exception_description")
            message:chatLocalizable(@"exist_invalid")
               sure:^(UIAlertAction *action) {
                 [weakSelf filterSelectedMessage:invalidMessages];
                 if (weakSelf.viewModel.selectedMessages.count > 0) {
                   [weakSelf forwardMessages:NO depth:0];
                 }
               }];
  } else if (self.viewModel.selectedMessages.count > 0) {
    [self forwardMessages:NO depth:0];
  }
}

- (void)forwardMessages:(BOOL)isMultiForward depth:(NSInteger)depth {
  __weak typeof(self) weakSelf = self;
  [[Router shared] register:NEChatForwardMultiSelectedRouter closure:^(NSDictionary *param) {
    NSArray *conversations = param[@"conversations"];
    if (![conversations isKindOfClass:[NSArray class]]) {
      return;
    }

    NSMutableArray<ForwardItem *> *items = [NSMutableArray array];
    NSMutableArray<NSString *> *conversationIds = [NSMutableArray array];
    NSArray<NSDictionary *> *conversationSnapshot = [conversations copy];
    for (NSDictionary *conversation in conversationSnapshot) {
      if (![conversation isKindOfClass:[NSDictionary class]]) {
        continue;
      }
      NSString *conversationId = conversation[@"conversationId"];
      if (conversationId.length > 0) {
        [conversationIds addObject:conversationId];

        ForwardItem *item = [[ForwardItem alloc] init];
        item.conversationId = conversationId;
        item.name = conversation[@"name"];
        item.avatar = conversation[@"avatar"];
        [items addObject:item];
      }
    }

    NSString *type = isMultiForward ? chatLocalizable(@"select_multi") :
                      (weakSelf.isMutilSelect ? chatLocalizable(@"select_per_item") : chatLocalizable(@"operation_forward"));
    [weakSelf addForwardAlertController:items type:type sureBlock:^(NSString *comment) {
      if (![weakSelf isNetworkReachable]) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
        return;
      }

      [weakSelf.viewModel forwardMessages:conversationIds
                            isMultiForward:isMultiForward
                                    depth:depth
                                  comment:comment
                               completion:^(NSError *error) {
                                 [weakSelf cancelMutilSelect];
                               }];
    }];
  }];

  [[Router shared] use:NEChatForwardMultiSelectRouter
             parameters:@{@"nav" : self.navigationController ?: [NSNull null], @"selctorMode" : @0}
                closure:nil];
}

- (void)customOperation {
  // 自定义操作 — 子类可重写
}

- (void)cancelMutilSelectAction {
  [self cancelMutilSelect];
}

- (void)selectedMessagesChanged:(NSInteger)count {
  [self.mutilSelectBottomView setEnable:count > 0];
}

- (void)expandButtonDidClick {
  if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
  }
  [self removeOperationView:YES];
  [self closeAIChatView];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [self scrollTableViewToBottom];
                 });
}

- (void)showAIChatView {
  if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
  }
  [self layoutInputView:ai_chat_view_height scrollToBottom:YES];
}

- (void)closeAIChatView {
  [self.chatInputView hideAIChatView];
  [self layoutInputView:0 scrollToBottom:NO];
}

- (void)didHideMultiple {
  // 子类可重写
}

- (void)didSendFinishAndCheckoutInput {
  if (self.chatInputView.chatInpuMode != ChatInputModeNormal) {
    self.chatInputView.chatInpuMode = ChatInputModeNormal;
    [self.chatInputView restoreNormalInputStyle];
    if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
      [self.chatInputView.textView becomeFirstResponder];
    }
    [self didHideMultiple];
  }
}

- (void)didHideMultipleButtonClick {
  [self.chatInputView restoreNormalInputStyle];
  if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
  }
  [self closeAIChatView];
}

- (void)titleTextDidClearEmpty {
  // 子类可重写
}

- (void)checkAndSendTypingState:(BOOL)endEdit {
  // 子类可重写（P2P 特有）
}

- (void)showLanguageContentController:(NEBaseSelectLanguageViewController *)controller {
  if (![controller isKindOfClass:[NEBaseSelectLanguageViewController class]]) {
    return;
  }
  [self.view endEditing:YES];
  if ([NEAdaptiveDeviceGate adaptiveHostActive] && self.isViewLoaded && self.view.window) {
    [self showLanguagePanelInColumn:controller host:self.view];
    return;
  }
  controller.modalPresentationStyle = UIModalPresentationCustom;
  controller.transitioningDelegate = self;
  controller.delegate = self;
  [self presentViewController:controller animated:YES completion:nil];
}

- (void)showLanguagePanelInColumn:(NEBaseSelectLanguageViewController *)controller host:(UIView *)host {
  [controller loadViewIfNeeded];
  controller.delegate = self;
  CGFloat sheetHeight = MIN(404.0, CGRectGetHeight(host.bounds));
  UIView *dimming = [[UIView alloc] initWithFrame:host.bounds];
  dimming.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
  dimming.alpha = 0;
  dimming.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [dimming addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(closeLanguagePanelInColumn)]];
  [host addSubview:dimming];

  [controller beginAppearanceTransition:YES animated:NO];
  [self addChildViewController:controller];
  controller.view.frame = CGRectMake(0, CGRectGetHeight(host.bounds), CGRectGetWidth(host.bounds), sheetHeight);
  controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  [host addSubview:controller.view];
  [controller didMoveToParentViewController:self];
  [controller endAppearanceTransition];

  __weak typeof(self) weakSelf = self;
  controller.columnDismissHandler = ^{
    [weakSelf closeLanguagePanelInColumn];
  };
  self.languagePanelOverlay = controller;
  self.languagePanelDimmingView = dimming;
  [UIView animateWithDuration:0.25
                   animations:^{
                     CGRect frame = controller.view.frame;
                     frame.origin.y = CGRectGetHeight(host.bounds) - sheetHeight;
                     controller.view.frame = frame;
                     dimming.alpha = 1;
                   }];
  void (^dismiss)(void) = ^{
    [weakSelf closeLanguagePanelInColumn];
  };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidPresent"
                                                      object:nil
                                                    userInfo:@{@"dismiss": dismiss}];
}

- (void)closeLanguagePanelInColumn {
  NEBaseSelectLanguageViewController *controller = self.languagePanelOverlay;
  if (!controller) {
    return;
  }
  UIView *dimming = self.languagePanelDimmingView;
  self.languagePanelOverlay = nil;
  self.languagePanelDimmingView = nil;
  controller.columnDismissHandler = nil;
  CGFloat hostHeight = controller.view.superview ? CGRectGetHeight(controller.view.superview.bounds)
                                                 : CGRectGetMaxY(controller.view.frame);
  [controller beginAppearanceTransition:NO animated:NO];
  [UIView animateWithDuration:0.2
                   animations:^{
                     CGRect frame = controller.view.frame;
                     frame.origin.y = hostHeight;
                     controller.view.frame = frame;
                     dimming.alpha = 0;
                   }
                   completion:^(__unused BOOL finished) {
                     [dimming removeFromSuperview];
                     [controller willMoveToParentViewController:nil];
                     [controller.view removeFromSuperview];
                     [controller removeFromParentViewController];
                     [controller endAppearanceTransition];
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidDismiss"
                                                                         object:nil];
                   }];
}

- (void)sendMessageCallback:(nullable V2NIMSendMessageResult *)result error:(nullable V2NIMError *)error progress:(NSUInteger)progress {
  if (ChatKitClient.shared.sendMessageCallback) {
    ChatKitClient.shared.sendMessageCallback(self, result, error, progress);
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= (NSInteger)self.viewModel.messages.count) {
    return [[NEBaseChatMessageCell alloc] init];
  }

  id<MessageModel> model = self.viewModel.messages[indexPath.row];
  if ([model isKindOfClass:[MessageContentModel class]]) {
    [(MessageContentModel *)model applyViewport:[self viewportForCurrentTableWidth]];
  }
  NSString *reuseId = NSStringFromClass([NEBaseChatMessageCell class]);
  NSString *key = [NSString stringWithFormat:@"%ld", (long)model.type];

  if (model.type == MessageTypeCustom) {
    NSInteger customType = model.customType;
    if (customType == customMultiForwardType) {
      reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeMultiForward];
    } else if (customType == customRichTextType) {
      reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeRichText];
    } else if ([[NEChatUIKitClient instance] getRegisterCustomCell][[NSString stringWithFormat:@"%ld", (long)customType]] != nil) {
      reuseId = [NSString stringWithFormat:@"%ld", (long)customType];
    }
  } else if (model.type == MessageTypeNotification || model.type == MessageTypeTip) {
    reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeTime];
  } else if (self.cellRegisterDic[key] != nil) {
    reuseId = key;
  }

  BOOL isSend = [ChatMessageHelper isSelf:model.message];
  // 表情回应等异步刷新会命中离屏 cell，此时 reuseId 可能来自未注册的分支；
  NSString *resolvedReuseId =
      [self.registeredCellReuseIds containsObject:reuseId] || self.registeredCellReuseIds.count == 0
          ? reuseId
          : @"NEBaseChatMessageCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resolvedReuseId forIndexPath:indexPath];
  if ([cell isKindOfClass:[NEBaseChatMessageTipCell class]]) {
    if ([model isKindOfClass:[MessageTipsModel class]]) {
      [(NEBaseChatMessageTipCell *)cell setModel:(MessageTipsModel *)model];
    }
    return cell;
  }

  if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
    NEBaseChatMessageCell *msgCell = (NEBaseChatMessageCell *)cell;
    msgCell.delegate = self;

    if ([cell conformsToProtocol:@protocol(ChatAudioCellProtocol)] &&
        [model isKindOfClass:[MessageAudioModel class]]) {
      id<ChatAudioCellProtocol> audioCell = (id<ChatAudioCellProtocol>)cell;
      MessageAudioModel *audioModel = (MessageAudioModel *)model;
      if (self.audioPlayer.isPlaying &&
          [audioModel.message.messageClientId isEqualToString:self.playingModel.message.messageClientId]) {
        self.playingCell = audioCell;
        audioModel.isPlaying = YES;
      }
      if (audioModel.isPlaying == NO) {
        [audioCell stopAnimation:isSend];
      }
    }

    if ([model isKindOfClass:[MessageVideoModel class]]) {
      MessageVideoModel *videoModel = (MessageVideoModel *)model;
      if ([videoModel.message.messageConfig isEqual:self.anchorModel.message.messageConfig] &&
          self.anchorModel.state == DownloadStateDownalod) {
        self.anchorCell = msgCell;
      }
    }

    if ([model isKindOfClass:[MessageContentModel class]]) {
      MessageContentModel *contentModel = (MessageContentModel *)model;
      [msgCell setModel:contentModel isSend:isSend];
      [msgCell setSelect:contentModel enableSelect:self.isMutilSelect];
    }
    return msgCell;
  }

  if ([cell isKindOfClass:[NEChatBaseCell class]] &&
      [model isKindOfClass:[MessageContentModel class]]) {
    [(NEChatBaseCell *)cell setModel:(MessageContentModel *)model isSend:isSend];
    return cell;
  }

  return [[NEBaseChatMessageCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= (NSInteger)self.viewModel.messages.count) {
    return;
  }
  if (self.isMutilSelect) {
    id<MessageModel> item = self.viewModel.messages[indexPath.row];
    if (![item isKindOfClass:[MessageContentModel class]]) {
      return;
    }
    MessageContentModel *model = (MessageContentModel *)item;
    if (model.isRevoked) {
      return;
    }
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (![cell isKindOfClass:[NEBaseChatMessageCell class]]) {
      return;
    }
    model.isSelected = !model.isSelected;
    ((NEBaseChatMessageCell *)cell).selectedButton.selected = model.isSelected;
    [self.viewModel.selectedMessages removeObjectsInArray:[self.viewModel.selectedMessages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(V2NIMMessage *obj, NSDictionary *bindings) {
      return [obj.messageClientId isEqualToString:model.message.messageClientId];
    }]]];
    if (model.isSelected && model.message) {
      [self.viewModel.selectedMessages addObject:model.message];
    }
    [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
    return;
  }

  if (!self.operationView.isHidden) {
    [self removeOperationView:YES];
  } else {
    if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
      [self.chatInputView.textView resignFirstResponder];
      [self.chatInputView.titleField resignFirstResponder];
    }
    [self closeAIChatView];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < (NSInteger)self.viewModel.messages.count) {
    id<MessageModel> model = self.viewModel.messages[indexPath.row];
    if ([model isKindOfClass:[MessageContentModel class]]) {
      [(MessageContentModel *)model applyViewport:[self viewportForCurrentTableWidth]];
    }
    return [model cellHeight] + chat_content_margin;
  }
  return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < (NSInteger)[tableView numberOfRowsInSection:indexPath.section]) {
    CGRect rowRect = [tableView rectForRowAtIndexPath:indexPath];
    if (!CGRectIntersectsRect(rowRect, tableView.bounds)) {
      return;
    }
  }
  if (self.isUpdatingViewport) {
    return;
  }
  [self refreshLastReadPositionVisibility];

  NSInteger messageCount = [tableView numberOfRowsInSection:0];
  BOOL reachedIndicatorTarget = self.onReceiveNewMsgs.count == 0
      ? (indexPath.row == messageCount - 1 && [self isLastMessageVisible])
      : [self isLatestPendingNewMessageVisible];
  if (reachedIndicatorTarget) {
    [self.onReceiveNewMsgs removeAllObjects];
    [self showJumpDownMessage:-1];
  }

  if (self.viewModel.messages.count < self.viewModel.messagPageNum) {
    return;
  }

  if (self.viewModel.isHistoryChat && self.suppressHistoryAutoLoadUntilUserScroll) {
    return;
  }

  NSInteger leaveCount = 10;
  __weak typeof(self) weakSelf = self;
  if (indexPath.row <= leaveCount && !self.isLoadingData && !self.uploadHasNoMore) {
    if (!self.isLoadingData) {
      self.isLoadingData = YES;
      [self.viewModel dropDownRemoteRefresh:^(NSError *error, NSInteger count, NSArray *messages) {
        if (error) {
          [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                      desc:[NSString stringWithFormat:@"%s CALLBACK dropDownRemoteRefresh %@", __FUNCTION__, error.localizedDescription]];
          weakSelf.isLoadingData = NO;
        } else {
          [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag]
                     desc:[NSString stringWithFormat:@"%s CALLBACK dropDownRemoteRefresh %@", __FUNCTION__, error.localizedDescription ?: @"no error"]];
          if (count <= 0) {
            if (![weakSelf isNetworkReachable]) {
              weakSelf.isLoadingData = NO;
              return;
            }
            weakSelf.uploadHasNoMore = YES;
            weakSelf.tableView.mj_header = nil;
            weakSelf.isLoadingData = NO;
          } else {
            [weakSelf tableViewReload];
            NSInteger num = [weakSelf.tableView numberOfRowsInSection:0];
            if (indexPath.row + count <= num) {
              [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + count - 1 inSection:0]
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:NO];
            }
            weakSelf.isLoadingData = NO;
          }
        }
      }];
    }
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  self.isRecvRolling = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    self.isRecvRolling = NO;
  }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
  self.isRecvRolling = NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  return YES;
}

#pragma mark - Media Send

- (void)cacheImageToSend:(UIImage *)image imageUrl:(nullable NSURL *)imageUrl imageName:(nullable NSString *)imageName {
  NSInteger imageWidth = (NSInteger)image.size.width;
  NSInteger imageHeight = (NSInteger)image.size.height;
  NSData *pngImage = UIImagePNGRepresentation(image);
  BOOL needDelete = NO;
  NSURL *url = imageUrl;

  if (!url) {
    NSString *dir = [NEPathUtils getDirectoryForDocuments:[NSString stringWithFormat:@"%@image/", imkitDir]];
    if (pngImage && dir) {
      NSString *filePath = [dir stringByAppendingFormat:@"%@.png", imageName ?: @"cache"];
      url = [NSURL fileURLWithPath:filePath];
      NSError *writeError = nil;
      [pngImage writeToURL:url options:NSDataWritingAtomic error:&writeError];
      if (writeError) {
        [self.view ne_makeToast:commonLocalizable(@"failed_operation")];
        return;
      }
      needDelete = YES;
    }
  }

  if (!url) {
    [self.view ne_makeToast:commonLocalizable(@"failed_operation")];
    return;
  }

  double imgSize_MB = (double)(pngImage.length) / 1e6;
  if (imgSize_MB > [ChatUIConfig shared].fileSizeLimit) {
    [self.view ne_makeToast:[NSString stringWithFormat:chatLocalizable(@"fileSize_over_limit"), [NSString stringWithFormat:@"%f", [ChatUIConfig shared].fileSizeLimit]]];
  } else {
    __weak typeof(self) weakSelf = self;
    if (self.isFile.boolValue) {
      [self.viewModel sendFileMessage:url.relativePath displayName:imageName conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
        [weakSelf showErrorToast:error defaultToast:nil];
        if (progress > 0 && progress <= 100) {
          [weakSelf setModelProgress:message progress:progress];
        }
      }];
    } else {
      [self.viewModel sendImageMessage:url.relativePath name:imageName width:(int32_t)imageWidth height:(int32_t)imageHeight conversationId:nil completion:^(NSError *error) {
        [weakSelf showErrorToast:error defaultToast:nil];
        if (needDelete) {
          [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
      }];
    }
  }
}

- (void)copyFileToSend:(NSURL *)url displayName:(NSString *)displayName isFile:(BOOL)isFile width:(int32_t)width height:(int32_t)height duration:(int32_t)duration {
  NSString *desPath = [NSTemporaryDirectory() stringByAppendingPathComponent:url.lastPathComponent];
  NSURL *dirUrl = [NSURL fileURLWithPath:desPath];
  if (![[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
    NSError *copyError = nil;
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:dirUrl error:&copyError];
    if (copyError) {
      [NEALog errorLog:[NSString stringWithFormat:@"%@ %@", ModuleName, kClassTag] desc:[NSString stringWithFormat:@"copyItem ERROR: %@", copyError]];
    }
  }
  if ([[NSFileManager defaultManager] fileExistsAtPath:desPath]) {
    NSError *attrError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:desPath error:&attrError];
    if (!attrError) {
      double size_B = [fileAttributes[NSFileSize] doubleValue];
      double size_MB = size_B / 1e6;
      if (size_MB > [ChatUIConfig shared].fileSizeLimit) {
        [self.view ne_makeToast:[NSString stringWithFormat:chatLocalizable(@"fileSize_over_limit"), [NSString stringWithFormat:@"%f", [ChatUIConfig shared].fileSizeLimit]]];
        [[NSFileManager defaultManager] removeItemAtPath:desPath error:nil];
      } else {
        __weak typeof(self) weakSelf = self;
        if (isFile) {
          [self.viewModel sendFileMessage:desPath displayName:displayName conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
            [weakSelf showErrorToast:error defaultToast:nil];
            if (progress > 0 && progress <= 100) {
              [weakSelf setModelProgress:message progress:progress];
            }
          }];
        } else {
          NSURL *videoURL = [NSURL URLWithString:desPath];
          if (!videoURL) return;
          [self.viewModel sendVideoMessage:videoURL name:displayName width:width height:height duration:duration conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
            [weakSelf showErrorToast:error defaultToast:nil];
            if (progress > 0 && progress <= 100) {
              [weakSelf setModelProgress:message progress:progress];
            }
          }];
        }
      }
    }
  }
}

- (void)sendMediaMessage:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
  NSString *imageName = @"IMG_0001";
  int32_t imageWidth = 0;
  int32_t imageHeight = 0;
  int32_t videoDuration = 0;

  if (self.isFile.boolValue) {
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    if (asset) {
      NSString *fileName = [asset valueForKey:@"filename"];
      if (fileName) imageName = fileName;
    }
  } else if (info[UIImagePickerControllerImageURL]) {
    imageName = ((NSURL *)info[UIImagePickerControllerImageURL]).lastPathComponent;
  } else if (info[UIImagePickerControllerMediaURL]) {
    imageName = ((NSURL *)info[UIImagePickerControllerMediaURL]).lastPathComponent;
  } else if (info[UIImagePickerControllerReferenceURL]) {
    imageName = ((NSURL *)info[UIImagePickerControllerReferenceURL]).lastPathComponent;
  }

  PHAsset *phAsset = info[UIImagePickerControllerPHAsset];
  if (phAsset) {
    imageWidth = (int32_t)phAsset.pixelWidth;
    imageHeight = (int32_t)phAsset.pixelHeight;
    videoDuration = (int32_t)(phAsset.duration * 1000);
  }

  // video
  NSURL *videoUrl = info[UIImagePickerControllerMediaURL];
  if (videoUrl) {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    videoDuration = (int32_t)(CMTimeGetSeconds(asset.duration) * 1000);
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (track) {
      CGSize size = track.naturalSize;
      CGAffineTransform transform = track.preferredTransform;
      CGSize correctedSize = CGSizeApplyAffineTransform(size, transform);
      imageWidth = (int32_t)fabs(correctedSize.width);
      imageHeight = (int32_t)fabs(correctedSize.height);
    }
    [self copyFileToSend:videoUrl displayName:imageName isFile:self.isFile ? self.isFile.boolValue : YES width:imageWidth height:imageHeight duration:videoDuration];
    return;
  }

  NSURL *imageUrl = info[UIImagePickerControllerImageURL];
  UIImage *image = info[UIImagePickerControllerOriginalImage];
  if (image) {
    image = [image fixOrientation];
    [self cacheImageToSend:image imageUrl:imageUrl imageName:imageName];
  } else {
    [self.view ne_makeToast:commonLocalizable(@"failed_operation")];
  }
}

- (void)sendMediaMessage:(PHAsset *)asset image:(nullable UIImage *)image isOriginal:(BOOL)isOriginal {
  NSString *filename = [PHAssetResource assetResourcesForAsset:asset].firstObject.originalFilename ?: @"unknown";
  int32_t width = (int32_t)asset.pixelWidth;
  int32_t height = (int32_t)asset.pixelHeight;
  __weak typeof(self) weakSelf = self;

  if (asset.mediaType == PHAssetMediaTypeImage) {
    if (!isOriginal && image) {
      [self cacheImageToSend:image imageUrl:nil imageName:filename];
      return;
    }
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData *adjustmentData) { return YES; };
    [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *input, NSDictionary *info) {
      NSURL *url = input.fullSizeImageURL;
      if (!url) return;
      if (weakSelf.isFile.boolValue) {
        [weakSelf.viewModel sendFileMessage:url.path displayName:filename conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
          [weakSelf showErrorToast:error defaultToast:nil];
          if (progress > 0 && progress <= 100) {
            [weakSelf setModelProgress:message progress:progress];
          }
        }];
      } else {
        [weakSelf.viewModel sendImageMessage:url.path name:filename width:width height:height conversationId:nil completion:^(NSError *error) {
          [weakSelf showErrorToast:error defaultToast:nil];
        }];
      }
    }];
  } else if (asset.mediaType == PHAssetMediaTypeVideo) {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
      if (![avAsset isKindOfClass:[AVURLAsset class]]) return;
      AVURLAsset *avURLAsset = (AVURLAsset *)avAsset;
      int32_t duration = (int32_t)(CMTimeGetSeconds(avURLAsset.duration) * 1000);
      NSURL *url = avURLAsset.URL;
      if (weakSelf.isFile.boolValue) {
        [weakSelf.viewModel sendFileMessage:url.path displayName:filename conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
          [weakSelf showErrorToast:error defaultToast:nil];
          if (progress > 0 && progress <= 100) {
            [weakSelf setModelProgress:message progress:progress];
          }
        }];
      } else {
        [weakSelf.viewModel sendVideoMessage:url name:filename width:width height:height duration:duration conversationId:nil completion:^(V2NIMMessage *message, NSError *error, NSUInteger progress) {
          [weakSelf showErrorToast:error defaultToast:nil];
          if (progress > 0 && progress <= 100) {
            [weakSelf setModelProgress:message progress:progress];
          }
        }];
      }
    }];
  }
}

#pragma mark - ChatBaseCellDelegate

- (void)didTapReaction:(UITableViewCell *)cell model:(nullable MessageContentModel *)model index:(NSInteger)index {
  if (!model.message || ![IMKitConfigCenter shared].enableEmojiReaction ||
      !NEChatSupportsReactionConversation(ChatRepo.conversationId)) return;
  if (index == 0) {
    [self presentReactionPanelForMessage:model.message cell:cell model:model];
    return;
  }
  if (![self isNetworkReachable]) {
    [self.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.viewModel toggleReactionMessage:model.message index:index completion:^(V2NIMError *error) {
    if (error) [weakSelf showToast:NEChatReactionErrorMessage(error.code)];
  }];
}

- (void)presentReactionPanelForMessage:(V2NIMMessage *)message
                                   cell:(UITableViewCell *)cell
                                  model:(MessageContentModel *)model {
  id provider = nil;
  if (!provider) return;
  if (self.chatInputView.textView.isFirstResponder || self.chatInputView.titleField.isFirstResponder) {
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
    [self layoutInputView:0 scrollToBottom:NO];
  }
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  if (!indexPath) return;
  [self removeOperationView:YES];
  self.viewModel.operationModel = model;

  CGFloat width = 278.0;
  CGFloat height = 310.0;
  CGRect rowRect = [self.tableView convertRect:[self.tableView rectForRowAtIndexPath:indexPath] toView:self.view];
  BOOL viewUnderMessage = YES;
  CGFloat y = CGRectGetMaxY(rowRect);
  if (y > kScreenHeight / 2.0) {
    viewUnderMessage = NO;
    y = CGRectGetMinY(rowRect) - height + (model.timeContent ? chat_timeCellH : 0);
  } else {
    y += 8;
  }
  CGFloat x = message.isSelf ? kScreenWidth - width - 8.0 : 8.0;
  self.operationView.visibleFrame = [self.tableView convertRect:self.tableView.bounds toView:self.view];
  self.operationView.hasVisibleFrame = YES;
  self.operationView.messageRect = rowRect;
  self.operationView.hasMessageRect = YES;
  self.operationView.frame = CGRectMake(x, y, width, height);
  self.operationView.items = [NSMutableArray array];
  self.operationView.oldFrameHeight = height;
  self.operationView.oldFrameWidth = width;
  self.operationView.viewUnderMessage = viewUnderMessage;
  [self.operationView configureReactionsWithProvider:provider
                                        quickIndexes:NEChatReactionPanelQuickIndexes()
                                           showEmoji:YES
                                      showMoreButton:NO];
  __weak typeof(self) weakSelf = self;
  self.operationView.onSelectReaction = ^(NSInteger reactionIndex) {
    if (![weakSelf isNetworkReachable]) {
      [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
      return;
    }
    [weakSelf.viewModel toggleReactionMessage:message index:reactionIndex completion:^(V2NIMError *error) {
      if (error) [weakSelf showToast:NEChatReactionErrorMessage(error.code)];
    }];
  };
  [self.operationView showAllEmoji];
  self.operationView.hidden = NO;
}

- (void)didLongPressAvatar:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] != V2NIM_CONVERSATION_TYPE_TEAM) return;
  if (self.isMute) return;
  if (self.isMutilSelect) return;

  NSString *addText = @"";
  NSString *accid = @"";
  if (model) {
    NSString *senderId = [ChatMessageHelper getSenderId:model.message];
    if (senderId) {
      accid = senderId;
      NSString *name = [NETeamUserManager.shared getShowName:senderId showAlias:NO];
      addText = [NSString stringWithFormat:@"@%@", name];
      [self addToAtUsers:addText isReply:NO accid:accid isLongPress:YES];
    }
  }
}

- (void)didTapAvatarView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isMutilSelect) return;
  [self didTapHeadPortrait:model];
}

- (void)didTapMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model replyModel:(nullable id<MessageModel> )replyModel {
  if ([ChatUIConfig shared].messageItemClick) {
    [ChatUIConfig shared].messageItemClick(self, cell, model);
    return;
  }
  if (!model || model.isRevoked) return;
  if (self.isMutilSelect) {
    model.isSelected = !model.isSelected;
    if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
      ((NEBaseChatMessageCell *)cell).selectedButton.selected = model.isSelected;
    }
    [self.viewModel.selectedMessages removeObjectsInArray:[self.viewModel.selectedMessages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(V2NIMMessage *obj, NSDictionary *bindings) {
      return [obj.messageClientId isEqualToString:model.message.messageClientId];
    }]]];
    if (model.isSelected && model.message) {
      [self.viewModel.selectedMessages addObject:model.message];
    }
    [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
    return;
  }

  if ((model.type == MessageTypeText || model.type == MessageTypeRichText || model.type == MessageTypeAIStreamText) && replyModel) {
    MessageContentModel *replyContentModel = (MessageContentModel *)replyModel;
    if (replyContentModel.message) {
      [self didTapReplyMessage:replyContentModel];
    } else if (model.message) {
      __weak typeof(self) weakSelf = self;
      [self.viewModel getReplyMessage:model.message completion:^(id<MessageModel> resolved) {
        if (![resolved isKindOfClass:[MessageContentModel class]] || !resolved.message) return;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf didTapReplyMessage:(MessageContentModel *)resolved];
        });
      }];
    }
  } else {
    [self didTapMessage:cell model:model replyIndex:-1];
  }
}

- (void)didTapReplyMessage:(MessageContentModel *)replyModel {
  NSString *clientId = replyModel.message.messageClientId;
  if (clientId.length == 0) return;

  MessageContentModel *resolvedModel = replyModel;
  NSInteger index = -1;
  for (NSInteger i = 0; i < (NSInteger)self.viewModel.messages.count; i++) {
    if ([clientId isEqualToString:self.viewModel.messages[i].message.messageClientId]) {
      index = i;
      if ([self.viewModel.messages[i] isKindOfClass:[MessageContentModel class]]) {
        resolvedModel = (MessageContentModel *)self.viewModel.messages[i];
      }
      break;
    }
  }

  BOOL isLoaded = index >= 0 && index < [self.tableView numberOfRowsInSection:0];
  UITableViewCell *replyCell = isLoaded ? [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] : nil;
  [self didTapMessage:replyCell model:resolvedModel replyIndex:isLoaded ? index : -1];
}

- (void)didLongPressMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  [self didLongTouchMessageView:cell model:model];
}

- (void)didLongPressTranslationView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isMutilSelect || ![model isKindOfClass:[MessageTextModel class]]) return;
  MessageTextModel *textModel = (MessageTextModel *)model;
  if (textModel.translationInfo.translatedText.length == 0) return;
  NSIndexPath *index = [self.tableView indexPathForCell:cell];
  if (!index) return;
  [self removeOperationView:YES];
  self.viewModel.operationModel = model;
  self.isTranslationOperation = YES;
  OperationItem *hideItem = [OperationItem hideTranslationItem];
  hideItem.text = chatLocalizable(@"chat_translate_hide");
  NSArray<OperationItem *> *items = @[[OperationItem copyItem], [OperationItem forwardItem], hideItem];
  CGFloat itemH = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 62.0 : 56.0;
  CGFloat width = NEChatOperationMenuWidth(items.count);
  CGFloat height = itemH + 16.0;
  CGRect rowRect = [self.tableView convertRect:[self.tableView rectForRowAtIndexPath:index] toView:self.view];
  CGFloat y = NEUIKitNavigationAndStatusHeight() + height + self.bodyTopViewHeight > rowRect.origin.y
      ? CGRectGetMaxY(rowRect) - chat_timeCellH : rowRect.origin.y - height + (model.timeContent ? chat_timeCellH : 0);
  CGFloat x = model.message.isSelf ? kScreenWidth - width - 56.0 : 56.0;
  CGRect frame = CGRectMake(x, y, width, height);
  frame.origin.y = MAX(CGRectGetMinY(self.tableView.frame), MIN(frame.origin.y, CGRectGetMaxY(self.tableView.frame) - height));
  self.operationView.visibleFrame = [self.tableView convertRect:self.tableView.bounds toView:self.view];
  self.operationView.hasVisibleFrame = YES;
  self.operationView.messageRect = rowRect;
  self.operationView.hasMessageRect = YES;
  self.operationView.frame = frame;
  self.operationView.items = [items mutableCopy];
  self.operationView.oldFrameHeight = height;
  [self.operationView configureReactionsWithProvider:nil
                                        quickIndexes:@[]
                                           showEmoji:NO
                                      showMoreButton:NO];
  [self.operationView showOperation];
  self.operationView.hidden = NO;
}

- (void)didTapTranslationRetryView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (![model isKindOfClass:[MessageTextModel class]]) return;
  self.viewModel.operationModel = model;
  self.isTranslationOperation = NO;
  [self translateMessage];
}

- (void)applyTranslationLayoutForModel:(MessageTextModel *)model visible:(BOOL)visible {
  BOOL normalStyle = [self isKindOfClass:NSClassFromString(@"NormalChatViewController")];
  if (model.addedTranslationHeight > 0) {
    model.height = MAX(0, model.height - model.addedTranslationHeight);
    if (normalStyle) {
      model.contentSize = CGSizeMake(model.translationBaseContentWidth > 0 ? model.translationBaseContentWidth : model.contentSize.width,
                                     MAX(0, model.contentSize.height - model.addedTranslationHeight));
    }
    model.addedTranslationHeight = 0;
  }
  if (!visible) return;
  CGFloat height = [model estimateTranslationBubbleHeight];
  if (height <= 0) return;
  if (normalStyle) {
    CGFloat baseWidth = model.translationBaseContentWidth > 0 ? model.translationBaseContentWidth : model.contentSize.width;
    CGFloat width = MAX(baseWidth, [model estimateTranslationTextWidth] + chat_content_margin * 2);
    model.contentSize = CGSizeMake(width, model.contentSize.height + height);
  }
  model.height += height;
  model.addedTranslationHeight = height;
}

/// 翻译完成后需要滚动展示的目标行：只有当前最后一条可见消息才允许改变滚动位置。
- (nullable NSIndexPath *)translationScrollTargetForIndexPath:(NSIndexPath *)indexPath {
  if (self.presentedViewController != nil || self.tableView.isDragging || self.tableView.isDecelerating) {
    return nil;
  }
  NSArray<NSIndexPath *> *visibleRows = self.tableView.indexPathsForVisibleRows;
  if (visibleRows.count == 0 || ![visibleRows containsObject:indexPath]) {
    return nil;
  }
  NSInteger maxVisibleRow = -1;
  for (NSIndexPath *path in visibleRows) {
    if (path.row > maxVisibleRow) {
      maxVisibleRow = path.row;
    }
  }
  if (maxVisibleRow != indexPath.row) {
    return nil;
  }
  NSInteger nextRow = indexPath.row + 1;
  if (nextRow < (NSInteger)self.viewModel.messages.count) {
    return [NSIndexPath indexPathForRow:nextRow inSection:indexPath.section];
  }
  if (indexPath.row == (NSInteger)self.viewModel.messages.count - 1) {
    return indexPath;
  }
  return nil;
}

/// 翻译高度写入后滚动，确保译文完整可见。
- (void)scrollToShowTranslationIfNeeded:(nullable NSIndexPath *)target {
  if (!target) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      return;
    }
    if (self.presentedViewController != nil || self.tableView.isDragging || self.tableView.isDecelerating) {
      return;
    }
    if (target.section >= self.tableView.numberOfSections ||
        target.row >= [self.tableView numberOfRowsInSection:target.section]) {
      return;
    }
    [self.tableView layoutIfNeeded];
    if (target.row == (NSInteger)self.viewModel.messages.count - 1) {
      [self scrollTableViewToBottom];
    } else {
      [self.tableView scrollToRowAtIndexPath:target
                            atScrollPosition:UITableViewScrollPositionBottom
                                    animated:YES];
    }
  });
}

- (void)prepareTranslationLayoutsForLoadedMessages {
  for (id<MessageModel> value in [self.viewModel.messages copy]) {
    if (![value isKindOfClass:[MessageTextModel class]]) continue;
    MessageTextModel *model = (MessageTextModel *)value;
    BOOL visible = model.translationVisible && (model.translationFailed || model.translationInfo.translatedText.length > 0);
    [self applyTranslationLayoutForModel:model visible:visible];
  }
}

- (void)triggerAutoTranslateHistory {
  if ([IMKitConfigCenter shared].autoTranslationEnableTime <= 0) return;
  NSArray<NSIndexPath *> *visiblePaths = self.tableView.indexPathsForVisibleRows;
  if (![visiblePaths isKindOfClass:[NSArray class]] || visiblePaths.count == 0) return;
  NSMutableArray<id<MessageModel>> *models = [NSMutableArray array];
  for (id value in visiblePaths) {
    if (![value isKindOfClass:[NSIndexPath class]]) continue;
    NSIndexPath *path = (NSIndexPath *)value;
    if (path.row >= 0 && path.row < self.viewModel.messages.count) {
      id<MessageModel> model = self.viewModel.messages[path.row];
      if (model) [models addObject:model];
    }
  }
  [self.viewModel autoTranslateVisibleHistory:models];
}

- (void)translateMessage {
  if (![self.viewModel.operationModel isKindOfClass:[MessageTextModel class]]) return;
  MessageTextModel *model = (MessageTextModel *)self.viewModel.operationModel;
  __weak typeof(self) weakSelf = self;
  [self.viewModel performTranslation:model targetLanguage:nil completion:^(NSInteger index, NSError *error) {
    if (error) {
      [weakSelf applyTranslationLayoutForModel:model visible:YES];
      if (index >= 0) [weakSelf tableViewReloadIndexs:@[[NSIndexPath indexPathForRow:index inSection:0]] completion:nil];
      return;
    }
    [weakSelf applyTranslationLayoutForModel:model visible:YES];
    if (index >= 0) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
      NSIndexPath *scrollTarget = [weakSelf translationScrollTargetForIndexPath:indexPath];
      [weakSelf tableViewReloadIndexs:@[indexPath] completion:^{
        [weakSelf scrollToShowTranslationIfNeeded:scrollTarget];
      }];
    }
  }];
}

- (void)hideTranslationMessage {
  if (![self.viewModel.operationModel isKindOfClass:[MessageTextModel class]]) return;
  MessageTextModel *model = (MessageTextModel *)self.viewModel.operationModel;
  [self applyTranslationLayoutForModel:model visible:NO];
  __weak typeof(self) weakSelf = self;
  [self.viewModel hideTranslation:model completion:^(NSInteger index) {
    if (index >= 0) [weakSelf tableViewReloadIndexs:@[[NSIndexPath indexPathForRow:index inSection:0]] completion:nil];
  }];
}

- (void)autoTranslationDidFinish:(NSInteger)index {
  if (index < 0 || index >= self.viewModel.messages.count) return;
  id model = self.viewModel.messages[index];
  if (![model isKindOfClass:[MessageTextModel class]]) return;
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  NSIndexPath *scrollTarget = [self translationScrollTargetForIndexPath:indexPath];
  [self applyTranslationLayoutForModel:model visible:YES];
  __weak typeof(self) weakSelf = self;
  [self tableViewReloadIndexs:@[indexPath] completion:^{
    [weakSelf scrollToShowTranslationIfNeeded:scrollTarget];
  }];
}

- (void)didTapResendView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isMutilSelect) return;
  if (model && model.message) {
    V2NIMMessage *msg = model.message;
    [[ChatDeduplicationHelper instance] removeBlackTipSendedId:msg.messageClientId];
    [self.viewModel sendMessage:msg conversationId:nil params:nil completion:^(V2NIMMessage *m, NSError *error, NSUInteger pro) {
      if (error) {
        NSLog(@"resend message error: %@", error.localizedDescription);
      }
    }];
  }
}

- (void)didTapReeditButton:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isMute || self.isMutilSelect) return;
  if (!model || !model.message) return;

  V2NIMMessage *message = model.message;
  if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT || message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
    if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
      if (model.customType != customRichTextType) return;
    }

    NSDate *date = [NSDate date];
    double currentTime = date.timeIntervalSince1970;
    if (model.revokeTime > 0 && currentTime - model.revokeTime >= 60 * 2) {
      [self.view ne_makeToast:chatLocalizable(@"editable_time_expired")];
      [self tableViewReload];
      return;
    }

    NSString *extensionStr = @"";
    if (message.serverExtension.length > 0) {
      extensionStr = message.serverExtension;
    } else if (message.localExtension.length > 0) {
      extensionStr = message.localExtension;
    }

    if (message.threadReply.messageClientId.length > 0 ||
        [NECommonUtil getDictionaryFromJSONString:extensionStr][keyReplyMsgKey] != nil) {
      self.viewModel.operationModel = model;
      [self showReplyMessageView:YES];
    } else {
      [self closeReply:nil];
    }

    NSDictionary *data = [NECustomUtils dataOfCustomMessage:message.attachment] ?: [NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""];

    NSString *text = @"";
    if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT && message.text) {
      text = message.text;
    } else if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
      NSString *body = data[@"body"] ?: data[revokeLocalMessageContent];
      if (body) text = body;
    }

    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    [attributeStr addAttributes:@{NSForegroundColorAttributeName: [UIColor ne_darkText], NSFontAttributeName: [UIFont systemFontOfSize:16]} range:NSMakeRange(0, text.length)];
    NSDictionary *remoteExt = [NECommonUtil getDictionaryFromJSONString:extensionStr];
    NSDictionary *atDic = [remoteExt objectForKey:yxAtMsg];
    if ([atDic isKindOfClass:[NSDictionary class]]) {
      for (NSString *key in atDic) {
        NSDictionary *contentDic = atDic[key];
        if (![contentDic isKindOfClass:[NSDictionary class]]) {
          continue;
        }
        NSArray *array = contentDic[atSegmentsKey];
        if (![array isKindOfClass:[NSArray class]]) {
          continue;
        }
        NSArray<MessageAtInfoModel *> *models = [NSArray yx_modelArrayWithClass:[MessageAtInfoModel class] json:array];
        if (![models isKindOfClass:[NSArray class]]) {
          continue;
        }
        NSString *atText = contentDic[atTextKey];
        if ([atText isKindOfClass:[NSString class]] && atText.length > 0) {
          if ([atText hasSuffix:@" "]) {
            atText = [atText substringToIndex:atText.length - 1];
          }
          [self.chatInputView.nickAccidList addObject:key];
          self.chatInputView.nickAccidDic[atText] = key;
        }
        for (MessageAtInfoModel *atModel in models) {
          if (atModel.end > atModel.start && attributeStr.length > (NSUInteger)atModel.end) {
            [attributeStr addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor ne_defaultPrimaryColor]
                                 range:NSMakeRange(atModel.start, atModel.end - atModel.start)];
          }
        }
      }
    }

    NSString *title = data[@"title"] ?: data[revokeLocalMessageTitle];
    if (title.length > 0) {
      self.chatInputView.titleField.text = title;
      [self expandButtonDidClick];
    } else {
      self.chatInputView.titleField.text = nil;
      if (self.chatInputView.chatInpuMode != ChatInputModeNormal) {
        [self didHideMultipleButtonClick];
      }
    }

    self.chatInputView.textView.attributedText = attributeStr;
    [self.chatInputView.textView becomeFirstResponder];
  }
}

- (void)didTapReadView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isMutilSelect) return;
  if (![self isNetworkReachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  if (model.message && model.message.conversationType == V2NIM_CONVERSATION_TYPE_TEAM) {
    NEBaseReadViewController *readVC = [self getReadView:model.message teamId:ChatRepo.sessionId];
    [self.navigationController pushViewController:readVC animated:YES];
  }
}

- (void)didTapSelectButton:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  [self.viewModel.selectedMessages removeObjectsInArray:[self.viewModel.selectedMessages filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(V2NIMMessage *obj, NSDictionary *bindings) {
    return [obj.messageClientId isEqualToString:model.message.messageClientId];
  }]]];
  if (model.isSelected && model.message) {
    [self.viewModel.selectedMessages addObject:model.message];
  }
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
}

- (void)didTextViewLoseFocus:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  [self removeOperationView:YES];
}

- (void)messageWillShow:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (self.isUpdatingViewport) {
    return;
  }
  if (model.message) {
    if (self.isCurrentPage && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
      [self.viewModel markRead:@[model.message] completion:^(NSError *error) {}];
    }
    if (self.networkBroken) {
      [self.needMarkReadMsgs addObject:model.message];
    }
  }
}

- (void)stopAIStreamMessage:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (!model.message) return;
  [self.viewModel stopAIStreamMessage:model.message];
}

- (void)regenAIStreamMessage:(UITableViewCell *)cell model:(nullable MessageContentModel *)model {
  if (!model.message) return;
  if (model.message.aiConfig.aiStream == NO) {
    [self.view ne_makeToast:chatLocalizable(@"ai_request_ing")];
  }
  [self.viewModel regenAIMessage:model.message];
}

- (void)didTapDetectedLink:(UITableViewCell *)cell model:(nullable MessageContentModel *)model url:(NSURL *)url {
  if ([url.scheme isEqualToString:@"mailto"]) {
    [self didTapMailto:url];
  } else if ([url.scheme isEqualToString:@"tel"]) {
    [self didTapTel:url];
  } else {
    NEWKWebViewController *ctrl = [[NEWKWebViewController alloc] initWithUrl:url.absoluteString title:url.absoluteString];
    [self.navigationController pushViewController:ctrl animated:YES];
  }
}

- (void)didTapTel:(NSURL *)url {
  [self showBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
  [self showBottomMailAction:url];
}

#pragma mark - NETranslateViewDelegate & SelectLanguageDelegate

- (void)didUseTranslate:(NSString *)content {
  self.chatInputView.textView.text = content;
}

- (void)didStartClick {
  NSString *contentString = [self.chatInputView getRealSendText:self.chatInputView.textView.attributedText];
  if (contentString) {
    __weak typeof(self) weakSelf = self;
    [self.viewModel translateLanguage:contentString targetLanguage:self.translateLanguageView.currentLanguage completion:^(NSError *error) {
      if (error) {
        NSString *content = [ChatMessageHelper getAIErrorMessage:error.code];
        if (content.length > 0) {
          [weakSelf.view ne_makeToast:content];
        } else if (error.localizedDescription) {
          [weakSelf.view ne_makeToast:error.localizedDescription];
        }
        [weakSelf.translateLanguageView changeToIdleState:NO];
      }
    }];
  }
}

- (void)didChangeViewHeight:(NEAITranslateView *)translateView changeHeight:(CGFloat)changeHeight {
  self.translateLanguageViewHeightAnchor.constant = changeHeight;
}

- (void)didSwitchLanguageClick:(nullable NSString *)currentLanguage {
  NSLog(@"translateLanguageViewDidClickSwitchLanguage %@", currentLanguage);
}

- (void)didCloseClick:(NEAITranslateView *)view {
  self.translateLanguageViewHeightAnchor.constant = 0;
}

- (void)didSelectLanguage:(nullable NSString *)language controller:(nullable UIViewController *)controller {
  if (language) {
    self.translateLanguageView.currentLanguage = language;
  }
}

#pragma mark - TopMessageViewDelegate

- (void)didClickCloseButton {
  if (![self isNetworkReachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.viewModel untopMessage:^(NSError *error) {
    if (error) {
      [weakSelf showErrorToast:error defaultToast:nil];
    } else {
      [weakSelf.topMessageView removeFromSuperview];
    }
  }];
}

- (void)didTapTopMessageView {
  if (![self isNetworkReachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  NSInteger index = -1;
  for (NSInteger i = 0; i < (NSInteger)self.viewModel.messages.count; i++) {
    if ([self.viewModel.topMessage.messageClientId isEqualToString:self.viewModel.messages[i].message.messageClientId]) {
      index = i;
      break;
    }
  }
  NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
  if (index >= 0 && index < rowCount) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    if (index == rowCount - 1) {
      [self.onReceiveNewMsgs removeAllObjects];
      [self showJumpDownMessage:-1];
    } else {
      [self showJumpDownMessage:self.onReceiveNewMsgs.count];
    }
  } else {
    self.viewModel.anchor = self.viewModel.topMessage;
    [self loadData];
  }
}

#pragma mark - NEMutilSelectBottomViewDelegate

- (void)didClickDeleteButton {
  if (![self isNetworkReachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  if (self.viewModel.selectedMessages.count > deleteMessagesLimitCount) {
    [self.view ne_makeToast:[NSString stringWithFormat:chatLocalizable(@"selete_messages_limit"), (int)deleteMessagesLimitCount]];
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self showAlert:chatLocalizable(@"message_delete_confirm") message:nil sure:^(UIAlertAction *action) {
    NSArray<V2NIMMessage *> *messages = [weakSelf.viewModel.selectedMessages copy];
    [weakSelf.viewModel deleteMessages:messages completion:^(NSError *error) {
      [weakSelf showErrorToast:error defaultToast:nil];
    }];
    [weakSelf cancelMutilSelect];
  }];
}

- (void)filterSelectedMessage:(NSArray<V2NIMMessage *> *)invalidMessages {
  NSArray<V2NIMMessage *> *selectedSnapshot = [self.viewModel.selectedMessages copy];
  for (V2NIMMessage *msg in selectedSnapshot) {
    BOOL isInvalid = NO;
    for (V2NIMMessage *invalid in invalidMessages) {
      if ([msg.messageClientId isEqualToString:invalid.messageClientId]) { isInvalid = YES; break; }
    }
    if (isInvalid) {
      for (NSInteger row = 0; row < (NSInteger)self.viewModel.messages.count; row++) {
        id<MessageModel> model = self.viewModel.messages[row];
        if ([msg.messageClientId isEqualToString:model.message.messageClientId]) {
          if (!model.isRevoked) {
            model.isSelected = !model.isSelected;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            NEBaseChatMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) cell.selectedButton.selected = model.isSelected;
          }
        }
      }
    }
  }
  NSMutableArray *toRemove = [NSMutableArray array];
  selectedSnapshot = [self.viewModel.selectedMessages copy];
  for (V2NIMMessage *msg in selectedSnapshot) {
    for (V2NIMMessage *invalid in invalidMessages) {
      if ([msg.messageClientId isEqualToString:invalid.messageClientId]) { [toRemove addObject:msg]; break; }
    }
  }
  [self.viewModel.selectedMessages removeObjectsInArray:toRemove];
  [self selectedMessagesChanged:self.viewModel.selectedMessages.count];
}

#pragma mark - AI Chat

- (void)loadAIChatData:(AIChatViewController *)aiChatViewController {
  NSMutableArray *msgs = [NSMutableArray array];
  NSArray<id<MessageModel> > *messageSnapshot = [self.viewModel.messages copy];
  for (id<MessageModel> model in messageSnapshot) {
    if (model.message) [msgs addObject:model.message];
  }
  [aiChatViewController loadData:msgs];
}

- (void)aiChatButtonDidClick:(AIChatViewController *)aiChatViewController open:(BOOL)open {
  if (open) {
    [self showAIChatView];
    [self loadAIChatData:aiChatViewController];
  } else {
    [self closeAIChatView];
  }
}

- (void)aiChatMessageDidClick:(NSString *)text {
  __weak typeof(self) weakSelf = self;
  [self.viewModel sendTextMessage:text conversationId:nil remoteExt:nil aiUserAccid:nil completion:^(V2NIMMessage *message, NSError *error) {
    if (error) [weakSelf showErrorToast:error defaultToast:nil];
    [weakSelf didSendFinishAndCheckoutInput];
  }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (!self.isCurrentPage) return;
  if (@available(iOS 14.0, *)) {
    if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
      [self didToSearchLocationView];
    }
  } else {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
      [self didToSearchLocationView];
    }
  }
}

#pragma mark - MessageOperationViewDelegate

- (void)didSelectedItem:(OperationItem *)item {
  BOOL fromTranslation = self.isTranslationOperation;
  [self removeOperationView:YES];
  if ([ChatUIConfig shared].popMenuClick) {
    [ChatUIConfig shared].popMenuClick(self, item);
    return;
  }
  if (item.type == OperationTypeEarpiece || item.type == OperationTypeSpeaker) {
    [self setHandsetMode:item];
  } else if (item.type == OperationTypeCopy) {
    if (fromTranslation && [(MessageTextModel *)self.viewModel.operationModel translationInfo].translatedText.length > 0) {
      UIPasteboard.generalPasteboard.string = [(MessageTextModel *)self.viewModel.operationModel translationInfo].translatedText;
      [self showToast:commonLocalizable(@"copy_success")];
    } else {
      [self copyMessage];
    }
  } else if (item.type == OperationTypeDelete) {
    [self deleteMessage];
  } else if (item.type == OperationTypeReply) {
    if (!self.isMute) [self showReplyMessageView:NO];
  } else if (item.type == OperationTypeRecall) {
    [self recallMessage];
  } else if (item.type == OperationTypeForward) {
    if (fromTranslation && [(MessageTextModel *)self.viewModel.operationModel translationInfo].translatedText.length > 0) {
      [self forwardTranslation:[(MessageTextModel *)self.viewModel.operationModel translationInfo].translatedText];
    } else {
      [self forwardMessage];
    }
  } else if (item.type == OperationTypePin) {
    [self pinMessage];
  } else if (item.type == OperationTypeRemovePin) {
    [self removePinMessage];
  } else if (item.type == OperationTypeMultiSelect) {
    [self selectMessage];
  } else if (item.type == OperationTypeTop) {
    [self topMessage];
  } else if (item.type == OperationTypeUntop) {
    [self untopMessage];
  } else if (item.type == OperationTypeCollection) {
    [self toCollectMessage];
  } else if (item.type == OperationTypeVoiceToText) {
    [self voiceToText];
  } else if (item.type == OperationTypeTranslate) {
    [self translateMessage];
  } else if (item.type == OperationTypeHideTranslation) {
    [self hideTranslationMessage];
  } else {
    if (item.onClick) item.onClick(self);
    [self customOperation];
  }
}

- (void)forwardTranslation:(NSString *)translatedText {
  if (translatedText.length == 0) return;
  self.pendingTranslationForwardText = translatedText;
  __weak typeof(self) weakSelf = self;
  [[Router shared] register:NEChatForwardMultiSelectedRouter closure:^(NSDictionary *param) {
    NSString *text = weakSelf.pendingTranslationForwardText;
    weakSelf.pendingTranslationForwardText = nil;
    if (text.length == 0) return;

    NSArray *conversations = [param[@"conversations"] isKindOfClass:[NSArray class]] ? param[@"conversations"] : @[];
    NSMutableArray<ForwardItem *> *items = [NSMutableArray array];
    NSMutableArray<NSString *> *conversationIds = [NSMutableArray array];
    for (NSDictionary *conversation in conversations) {
      if (![conversation isKindOfClass:[NSDictionary class]]) continue;
      NSString *conversationId = conversation[@"conversationId"];
      if (conversationId.length == 0) continue;
      [conversationIds addObject:conversationId];
      ForwardItem *item = [[ForwardItem alloc] init];
      item.conversationId = conversationId;
      item.name = conversation[@"name"];
      item.avatar = conversation[@"avatar"];
      [items addObject:item];
    }

    [weakSelf addForwardAlertController:items type:chatLocalizable(@"operation_forward") sureBlock:^(NSString *comment) {
      if (![weakSelf isNetworkReachable]) {
        [weakSelf.view neMakeToast:commonLocalizable(@"network_error") position:NEToastPositionCenter];
        return;
      }
      [weakSelf.viewModel sendTranslationForwardMessage:text comment:comment conversationIds:conversationIds completion:^(NSError *error) {
        if (error) [weakSelf showErrorToast:error defaultToast:nil];
      }];
    }];
  }];

  [[Router shared] use:NEChatForwardMultiSelectRouter
             parameters:@{ @"nav" : self.navigationController ?: [NSNull null], @"selctorMode" : @0 }
                closure:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(nullable UIViewController *)presenting sourceViewController:(UIViewController *)source {
  return [[CustomPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

- (NEBaseReadViewController *)getReadView:(V2NIMMessage *)message teamId:(NSString *)teamId {
  return [[ReadViewController alloc] initWithMessage:message teamId:teamId];
}

#pragma mark - ChatInputViewDelegate (textChanged / textDelete / textViewDidChange / textFieldDidEndEditing / textFieldDidBeginEditing / textFieldDidChange)

- (BOOL)textChanged:(NSString *)text {
  if ([text isEqualToString:@"@"]) {
    if (![IMKitConfigCenter shared].enableAtMessage) return YES;
    if ([V2NIMConversationIdUtil conversationType:ChatRepo.conversationId] == V2NIM_CONVERSATION_TYPE_P2P) {
      if ([IMKitConfigCenter shared].enableAIUser && ![[NEAIUserManager shared] isAIUser:ChatRepo.sessionId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self showUserSelectVC:NO];
        });
      }
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showUserSelectVC:YES];
      });
    }
    return YES;
  }
  return YES;
}

- (void)textViewDidChange {
  [self.translateLanguageView changeToIdleState:NO];
}

- (void)textFieldDidEndEditing:(nullable NSString *)text {
  [self checkAndSendTypingState:YES];
}

- (void)textFieldDidBeginEditing:(nullable NSString *)text {
  [self checkAndSendTypingState:NO];
}

- (void)textFieldDidChange:(nullable NSString *)text {
  [self checkAndSendTypingState:NO];
}

#pragma mark - setTopValue / updateTopName

- (void)setTopValueWithName:(nullable NSString *)name content:(nullable NSString *)content url:(nullable NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose {
  if (content) {
    [self.contentView addSubview:self.topMessageView];
    [NSLayoutConstraint activateConstraints:@[
      [self.topMessageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:chat_content_margin],
      [self.topMessageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:chat_content_margin],
      [self.topMessageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-chat_content_margin],
      [self.topMessageView.heightAnchor constraintEqualToConstant:40],
    ]];
    [self.topMessageView setTopContentWithName:name content:content url:url isVideo:isVideo hideClose:hideClose];
  } else {
    [self.topMessageView removeFromSuperview];
  }
}

- (void)updateTopName:(nullable NSString *)name {
  [self.topMessageView updateTopName:name];
}

#pragma mark - Public interaction methods

- (void)loadFartherToNowData {
  // 空实现，子类覆写
}

- (void)didDismissCallView {
  // 通话页面关闭回调 — 空实现
}

- (void)showMenue:(UIView *)sourceView {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:chatLocalizable(@"choose")
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
  alert.modalPresentationStyle = UIModalPresentationPopover;

  __weak typeof(self) weakSelf = self;
  UIAlertAction *camera = [UIAlertAction actionWithTitle:commonLocalizable(@"take_picture") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [weakSelf takePhoto];
  }];
  UIAlertAction *photo = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [weakSelf willSelectImage];
  }];
  UIAlertAction *cancel = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];

  [alert addAction:camera];
  [alert addAction:photo];
  [alert addAction:cancel];

  UIPopoverPresentationController *popover = alert.popoverPresentationController;
  if (popover) {
    popover.sourceView = sourceView;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
  }
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)takePhoto {
  UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
  imagePickerVC.delegate = self;
  imagePickerVC.allowsEditing = NO;
  imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)willSelectImage {
  UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
  imagePickerVC.delegate = self;
  imagePickerVC.allowsEditing = NO;
  imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  imagePickerVC.mediaTypes = @[@"public.image", @"public.movie"];
  [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (BOOL)textDelete:(NSRange)range text:(NSString *)text {
  if (range.location == NSNotFound || range.location > text.length) {
    return YES;
  }

  if (!self.atUsersInternal) {
    self.atUsersInternal = [NSMutableArray array];
  }
  NSInteger matchedIndex = NSNotFound;
  NSRange removedRange = NSMakeRange(NSNotFound, 0);
  for (NSInteger i = 0; i < self.atUsersInternal.count; i++) {
    NSRange atRange = self.atUsersInternal[i].rangeValue;
    NSInteger rightIndex = (NSInteger)atRange.location + (NSInteger)atRange.length - 1;
    if (rightIndex == (NSInteger)range.location) {
      matchedIndex = i;
      removedRange = atRange;
      break;
    }
  }

  if (matchedIndex == NSNotFound) {
    return YES;
  }

  [self.atUsersInternal removeObjectAtIndex:matchedIndex];
  NSMutableArray<NSValue *> *adjustedRanges = [NSMutableArray arrayWithCapacity:self.atUsersInternal.count];
  for (NSValue *value in self.atUsersInternal) {
    NSRange atRange = value.rangeValue;
    if (removedRange.location < atRange.location) {
      atRange.location -= removedRange.length;
    }
    [adjustedRanges addObject:[NSValue valueWithRange:atRange]];
  }
  if (adjustedRanges.count > 0) {
    self.atUsersInternal = adjustedRanges;
  }

  NSString *cacheKey = [NSString stringWithFormat:@"%lu_%lu",
                        (unsigned long)removedRange.location,
                        (unsigned long)(removedRange.length - 1)];
  [self.chatInputView.atRangeCache removeObjectForKey:cacheKey];

  UITextView *textView = self.chatInputView.textView;
  if (removedRange.location + removedRange.length <= textView.text.length) {
    NSRange selectedRange = textView.selectedRange;
    NSInteger newCursorLocation = MAX(0, (NSInteger)selectedRange.location - (NSInteger)removedRange.length);
    textView.text = [textView.text stringByReplacingCharactersInRange:removedRange withString:@""];
    textView.selectedRange = NSMakeRange(MIN(newCursorLocation, textView.text.length), 0);
  }

  // Returning NO prevents UITextView from applying a second deletion.
  return NO;
}

- (void)moveInView {
  // 录音手势移入 — 空实现，子类可重写
}

- (void)moveOutView {
  // 录音手势移出 — 空实现，子类可重写
}

#pragma mark - NIMMediaManagerDelegate (record)

- (void)recordAudio:(nullable NSString *)filePath didBeganWithError:(nullable NSError *)error {
  NSLog(@"%f [record] sdk Began error:%@", [[NSDate date] timeIntervalSince1970], error.localizedDescription ?: @"");
  // 录音已开始：stopPlay 只停播放，不能释放音频会话。
  [NEAudioSessionManager shared].isRecording = YES;
  [self stopPlay];
}

- (void)recordAudio:(nullable NSString *)filePath didCompletedWithError:(nullable NSError *)error {
  [NEAudioSessionManager shared].isRecording = NO;
  NSLog(@"%f [record] sdk Completed error:%@", [[NSDate date] timeIntervalSince1970], error.localizedDescription ?: @"");
  [self.chatInputView stopRecordAnimation];
  if (!filePath) {
    [self showErrorToast:error defaultToast:nil];
    return;
  }
  Float64 dur = [self recordDuration:filePath];
  NSLog(@"dur:%f", dur);
  if (dur > 1) {
    __weak typeof(self) weakSelf = self;
    [self.viewModel sendAudioMessage:filePath conversationId:nil completion:^(NSError *error) {
      [weakSelf showErrorToast:error defaultToast:nil];
    }];
  } else {
    [self.view ne_makeToast:chatLocalizable(@"record_too_short")];
  }
}

- (void)recordAudioDidCancelled {
  [NEAudioSessionManager shared].isRecording = NO;
  NSLog(@"[record] sdk cancel");
}

- (void)recordAudioProgress:(NSTimeInterval)currentTime {
  NSLog(@"%f [record] sdk Progress：%f", [[NSDate date] timeIntervalSince1970], currentTime);
}

- (void)recordAudioInterruptionBegin {
  // 录音中断 — 空实现
}

- (Float64)recordDuration:(NSString *)filePath {
  AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
  return CMTimeGetSeconds(avAsset.duration);
}

@end
