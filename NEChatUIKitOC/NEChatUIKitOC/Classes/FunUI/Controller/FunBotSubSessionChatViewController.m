// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunBotSubSessionChatViewController.h"

#import "ChatNavigationView.h"
#import "ChatUIConfig.h"
#import "FunBotSubSessionListViewController.h"
#import "FunChatUIColor.h"
#import "FunUserSettingViewController.h"
#import "NEBaseBotSubSessionListViewController.h"
#import "NEChatMoreActionView.h"
#import "NEChatUIConstant.h"
#import "NEMoreItemModel.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/ViewControllerExtension.h>

@interface FunBotSubSessionChatViewController ()

@property(nonatomic, copy, readwrite) NSString *botSessionName;
@property(nonatomic, strong, readwrite) UILabel *botSubSessionGuideLabel;
@property(nonatomic, strong, nullable) NSLayoutConstraint *botSubSessionGuideTopConstraint;
@property(nonatomic, weak, nullable) UIView *botSubSessionGuideTopView;

@end


@implementation FunBotSubSessionChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName
                                  topic:(V2NIMTopic *)topic {
  self = [super initWithConversationId:conversationId anchor:nil];
  if (self) {
    _botSessionName = [sessionName copy] ?: @"";
    _botConversationDisplayTitle = [sessionName copy] ?: @"";
    _botSubSessionGuideLabel = [[UILabel alloc] init];
    self.viewModel = [[TopicChatViewModel alloc] initWithConversationId:conversationId
                                                                 anchor:nil
                                                                  topic:topic
                                                            sessionName:sessionName ?: @""];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"initWithCoder: has not been implemented"
                               userInfo:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self applyFunBotSubSessionBackground];
  [self configureBotSubSessionNavigation];
  [self applyBotSubSessionTitleWithFallback:nil];
  [self setupBotSubSessionGuideView];
  [self refreshBotSubSessionGuideView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self applyFunBotSubSessionBackground];
  [self configureBotSubSessionNavigation];
  [self applyBotSubSessionTitleWithFallback:nil];
}

- (void)setTitleContent:(NSString *)titleContent {
  [super setTitleContent:titleContent];
  self.title = titleContent;
  [self updateBotSubSessionGuideText];
}

- (void)remoteUserEndEditing { self.title = self.titleContent; }
- (void)remoteUserOnlineChanged { self.title = self.titleContent; }

- (TopicChatViewModel *)topicChatViewModel {
  return [self.viewModel isKindOfClass:[TopicChatViewModel class]]
    ? (TopicChatViewModel *)self.viewModel
    : nil;
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
  __weak typeof(self) weakSelf = self;
  [self loadBaseSessionInfo:^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) {
      if (completion) completion();
      return;
    }
    [self.viewModel loadShowName:@[sessionId] teamId:nil completion:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
          if (completion) completion();
          return;
        }
        self.botConversationDisplayTitle = [self normalConversationDisplayTitle:sessionId];
        [self applyBotSubSessionTitleWithFallback:sessionId];
        if (completion) completion();
      });
    }];
  }];
}

- (void)getSessionInfoWithSessionId:(NSString *)sessionId :(void (^)(void))completion {
  [self getSessionInfo:sessionId completion:completion];
}

- (void)loadBaseSessionInfo:(void (^)(void))completion {
  NSString *account = [[IMKitClient instance] account];
  if ([[NEFriendUserCache shared] getFriendInfo:account] == nil) {
    [[ContactRepo shared] getUserListFromCloud:@[account]
                                   completion:^(__unused NSArray<NEUserWithFriend *> *users,
                                                __unused NSError *error) {
      if (completion) completion();
    }];
  } else if (completion) {
    completion();
  }
}

- (NEBaseUserSettingViewController *)getUserSettingViewController {
  NEBaseUserSettingViewController *controller = [super getUserSettingViewController];
  controller.fromBotSubSession = YES;
  controller.botSubSessionTopic = self.topicChatViewModel.topic;
  return controller;
}

- (void)toSetting {
  // 子会话设置以列内底部弹层呈现，不会像普通聊天 push 设置页那样自然收键盘；
  [self.view endEditing:YES];
  if (!self.topicChatViewModel.topic) return;
  [self showBotSubSessionActionSheet];
}

- (void)showBotSubSessionActionSheet {
  if (!self.topicChatViewModel) return;
  BotSubSessionActionSheetController *controller = [[BotSubSessionActionSheetController alloc]
    initWithTitle:[self botSubSessionDisplayTitle]];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onRename = ^{
    [weakController dismissViewControllerAnimated:NO completion:nil];
    [weakSelf showRenameAlert];
  };
  controller.onDelete = ^{
    [weakController dismissViewControllerAnimated:NO completion:nil];
    [weakSelf showDeleteAlert];
  };
  [self showBottomSheetInDetailColumn:controller animated:NO completion:nil];
}

- (void)showRenameAlert {
  TopicChatViewModel *viewModel = self.topicChatViewModel;
  if (!viewModel.topic) return;
  BotSubSessionRenameDialogController *controller = [[BotSubSessionRenameDialogController alloc]
    initWithName:[self botSubSessionDisplayTitle]
    saveButtonBackgroundColor:[UIColor ne_colorWithHexString:@"#58BE6B"]];
  __weak typeof(controller) weakController = controller;
  controller.onSave = ^(NSString *name) {
    if (name.length == 0) {
      [weakController showToast:chatLocalizable(@"bot_sub_session_input_name")];
      return;
    }
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakController showToast:commonLocalizable(@"network_error")];
      return;
    }
    [viewModel updateTopicName:name :^(__unused V2NIMTopic *topic, NSError *error) {
      if (error) {
        [weakController showToast:chatLocalizable(@"bot_sub_session_rename_failed")];
      } else {
        [weakController dismissViewControllerAnimated:NO completion:nil];
      }
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (void)showDeleteAlert {
  TopicChatViewModel *viewModel = self.topicChatViewModel;
  if (!viewModel.topic) return;
  NSString *message = [NSString stringWithFormat:chatLocalizable(@"bot_sub_session_delete_topic"),
                       [self botSubSessionDisplayTitle]];
  BotSubSessionDeleteDialogController *controller = [[BotSubSessionDeleteDialogController alloc]
    initWithTitle:chatLocalizable(@"bot_sub_session_delete_title")
           message:message
    confirmButtonBackgroundColor:[UIColor ne_colorWithHexString:@"#58BE6B"]];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onDelete = ^{
    [weakController dismissViewControllerAnimated:NO completion:nil];
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
      return;
    }
    [viewModel removeCurrentTopic:^(NSError *error) {
      if (error) [weakSelf.view ne_makeToast:chatLocalizable(@"bot_sub_session_delete_failed")];
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (void)onTopicChanged:(V2NIMTopic *)topic {
  [self applyBotSubSessionTitleWithFallback:nil];
  [self configureBotSubSessionNavigation];
  [self refreshBotSubSessionGuideView];
}

- (void)onTopicTipMessage:(NSString *)text { [self.view ne_makeToast:text]; }

- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index {
  [super sending:message index:index];
  [self refreshBotSubSessionGuideView];
}

- (void)sending:(V2NIMMessage *)message :(NSIndexPath *)index {
  [self sending:message index:index];
}

- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index {
  [super sendSuccess:message index:index];
  [self refreshBotSubSessionGuideView];
}

- (void)sendSuccess:(V2NIMMessage *)message :(NSIndexPath *)index {
  [self sendSuccess:message index:index];
}

- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs {
  [super onRecvMessages:messages indexs:indexs];
  [self refreshBotSubSessionGuideView];
}

- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages :(NSArray<NSIndexPath *> *)indexs {
  [self onRecvMessages:messages indexs:indexs];
}

- (void)setOperationItems:(NSMutableArray<OperationItem *> *)items
                    model:(MessageContentModel *)model {
  NSIndexSet *unsupportedIndexes = [items indexesOfObjectsPassingTest:
    ^BOOL(OperationItem *item, NSUInteger index, BOOL *stop) {
    return item.type == OperationTypePin ||
           item.type == OperationTypeRemovePin ||
           item.type == OperationTypeRecall;
  }];
  [items removeObjectsAtIndexes:unsupportedIndexes];
}

- (NSArray<NEMoreItemModel *> *)expandMoreAction {
  NSMutableArray<NEMoreItemModel *> *items = [[super expandMoreAction] mutableCopy];
  [items filterUsingPredicate:[NSPredicate predicateWithBlock:
    ^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
    return item.type != NEMoreActionTypeAiChat;
  }]];
  [self.chatInputView.chatAddMoreView configData:items];
  return items;
}

- (void)onCurrentTopicRemoved {
  if (![NSThread isMainThread]) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf onCurrentTopicRemoved]; });
    return;
  }
  UINavigationController *navigationController = self.navigationController;
  if (!self.isViewLoaded || navigationController.topViewController != self) return;
  NSString *toast = chatLocalizable(@"bot_sub_session_removed");
  __weak typeof(self) weakSelf = self;
  void (^showToastOnList)(void) = ^{
    __strong typeof(weakSelf) self = weakSelf;
    UINavigationController *navigationController = self.navigationController;
    NSUInteger index = [navigationController.viewControllers indexOfObjectIdenticalTo:self];
    UIViewController *previousController = index != NSNotFound && index > 0
      ? navigationController.viewControllers[index - 1]
      : nil;
    if (![previousController isKindOfClass:[NEBaseBotSubSessionListViewController class]]) return;
    [navigationController popViewControllerAnimated:NO];
    [(NEBaseBotSubSessionListViewController *)previousController showToast:toast];
  };
  UIViewController *presentedController = self.presentedViewController ?:
    navigationController.presentedViewController;
  if (presentedController) {
    [presentedController dismissViewControllerAnimated:NO completion:showToastOnList];
  } else {
    showToastOnList();
  }
}

- (UIView *)botSubSessionGuideView {
  if (!_botSubSessionGuideView) {
    _botSubSessionGuideView = [self createBotSubSessionGuideView];
  }
  return _botSubSessionGuideView;
}

- (UIView *)createBotSubSessionGuideView {
  UIView *container = [[UIView alloc] init];
  container.translatesAutoresizingMaskIntoConstraints = NO;
  container.userInteractionEnabled = NO;
  UIImageView *imageView = [[UIImageView alloc]
    initWithImage:chatLoadImage(@"bot_sub_session_guide")];
  imageView.translatesAutoresizingMaskIntoConstraints = NO;
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  UILabel *label = self.botSubSessionGuideLabel;
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
  label.textColor = [UIColor colorWithRed:153 / 255.0 green:153 / 255.0
                                    blue:153 / 255.0 alpha:1];
  label.textAlignment = NSTextAlignmentCenter;
  [self updateBotSubSessionGuideText];
  [container addSubview:imageView];
  [container addSubview:label];
  [NSLayoutConstraint activateConstraints:@[
    [imageView.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
    [imageView.topAnchor constraintEqualToAnchor:container.topAnchor],
    [imageView.widthAnchor constraintEqualToConstant:64],
    [imageView.heightAnchor constraintEqualToConstant:64],
    [label.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:24],
    [label.leftAnchor constraintGreaterThanOrEqualToAnchor:container.leftAnchor constant:24],
    [label.rightAnchor constraintLessThanOrEqualToAnchor:container.rightAnchor constant:-24],
    [label.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
    [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
  ]];
  return container;
}

- (void)setupBotSubSessionGuideView {
  [self.contentView addSubview:self.botSubSessionGuideView];
  self.botSubSessionGuideTopConstraint = [self.botSubSessionGuideView.topAnchor
    constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:12];
  NSLayoutConstraint *centerYConstraint = [self.botSubSessionGuideView.centerYAnchor
    constraintEqualToAnchor:self.contentView.centerYAnchor];
  centerYConstraint.priority = UILayoutPriorityDefaultLow;
  [NSLayoutConstraint activateConstraints:@[
    [self.botSubSessionGuideView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
    [self.botSubSessionGuideView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.botSubSessionGuideView.bottomAnchor
      constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12],
    [self.botSubSessionGuideView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    centerYConstraint,
    self.botSubSessionGuideTopConstraint,
  ]];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self updateBotSubSessionGuideTopConstraint];
}

- (void)updateBotSubSessionGuideTopConstraint {
  UIView *topView = self.topMessageView.superview != nil && !self.topMessageView.hidden
    ? self.topMessageView
    : nil;
  if (topView == self.botSubSessionGuideTopView) return;
  self.botSubSessionGuideTopConstraint.active = NO;
  self.botSubSessionGuideTopConstraint = topView
    ? [self.botSubSessionGuideView.topAnchor constraintGreaterThanOrEqualToAnchor:topView.bottomAnchor
                                                            constant:12]
    : [self.botSubSessionGuideView.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor
                                                            constant:12];
  self.botSubSessionGuideTopConstraint.active = YES;
  self.botSubSessionGuideTopView = topView;
}

- (void)refreshBotSubSessionGuideView {
  [self updateBotSubSessionGuideText];
  self.botSubSessionGuideView.hidden = self.topicChatViewModel.topic != nil ||
                                       self.viewModel.messages.count > 0;
}

- (NSString *)botSubSessionDisplayTitle {
  NSString *topicTitle = [self.topicChatViewModel.topic.topicName ?: @""
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (topicTitle.length > 0) return topicTitle;
  if (!self.topicChatViewModel.topic) return chatLocalizable(@"bot_sub_session_new_conversation");
  NSString *conversationTitle = [self.botConversationDisplayTitle
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (conversationTitle.length > 0) return conversationTitle;
  NSString *fallbackTitle = [self.titleContent
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return fallbackTitle.length > 0 ? fallbackTitle : [self botConversationTitleFallback];
}

- (void)updateBotSubSessionGuideText {
  self.botSubSessionGuideLabel.text = [NSString
    stringWithFormat:chatLocalizable(@"bot_sub_session_guide"), [self botSubSessionGuideTitle]];
}

- (NSString *)botSubSessionGuideTitle {
  NSString *topicTitle = [self.topicChatViewModel.topic.topicName ?: @""
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (topicTitle.length > 0) return topicTitle;
  NSString *conversationTitle = [self.botConversationDisplayTitle
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return conversationTitle.length > 0 ? conversationTitle : [self botConversationTitleFallback];
}

- (void)applyBotSubSessionTitleWithFallback:(NSString *)fallback {
  NSString *displayTitle = [self botSubSessionDisplayTitleWithFallback:fallback];
  self.titleContent = displayTitle;
  self.title = displayTitle;
  [self updateBotSubSessionGuideText];
}

- (NSString *)botSubSessionDisplayTitleWithFallback:(NSString *)fallback {
  NSString *displayTitle = [[self botSubSessionDisplayTitle]
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return displayTitle.length > 0 ? displayTitle : (fallback ?: [self botConversationTitleFallback]);
}

- (NSString *)normalConversationDisplayTitle:(NSString *)sessionId {
  NSString *showName = [[self.viewModel getShowName:sessionId showAlias:YES]
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (showName.length > 0) return showName;
  NSString *routeTitle = [self.botSessionName
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return routeTitle.length > 0 ? routeTitle : sessionId;
}

- (NSString *)botConversationTitleFallback {
  NSString *routeTitle = [self.botSessionName
    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  return routeTitle.length > 0 ? routeTitle : ChatRepo.sessionId;
}

- (void)configureBotSubSessionNavigation {
  BOOL canShowAction = self.topicChatViewModel.topic != nil;
  self.navigationView.moreButton.hidden = !canShowAction;
  if (!canShowAction) {
    self.navigationItem.rightBarButtonItem = nil;
    return;
  }
  UIImage *image = [ChatUIConfig shared].messageProperties.titleBarRightRes ?:
    [coreLoader() loadImage:@"three_point"];
  [self.navigationView setMoreButtonImage:image];
  [self.navigationView.moreButton removeTarget:nil action:nil
                              forControlEvents:UIControlEventTouchUpInside];
  [self.navigationView addMoreButtonTarget:self selector:@selector(toSetting)];
  [self addRightAction:image action:@selector(toSetting) target:self];
}

- (void)applyFunBotSubSessionBackground {
  self.navigationController.navigationBar.backgroundColor = UIColor.funChatNavigationBg;
  self.navigationView.backgroundColor = UIColor.funChatNavigationBg;
  self.navigationView.titleBarBottomLine.backgroundColor = UIColor.funChatNavigationDivideBg;
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.funChatNavigationBg;
    appearance.shadowColor = UIColor.funChatNavigationDivideBg;
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
  }
}

@end
