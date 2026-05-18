// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotDetailController.h"
#import "AIRobotDetailViewModel.h"
#import "ContactConst.h"
#import "NormalContactUIColor.h"
#import <NEChatKitOC/NEAIRobotManager.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

static NSInteger const kNEAIRobotRefreshAlertTag = 9901;
static NSInteger const kNEAIRobotDeleteAlertTag = 9911;
static NSInteger const kNEAIRobotDetailSeparatorTag = 8301;

@implementation NEBaseAIRobotDetailController

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = [[AIRobotDetailViewModel alloc] initWithBot:bot];
    _operationTitles = @[];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _operationTitles = @[];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = contactLocalizable(@"ai_robot_detail_title");
  self.navigationView.moreButton.hidden = YES;
  self.operationTitles = @[
    contactLocalizable(@"ai_robot_view_config"),
    contactLocalizable(@"ai_robot_refresh_token"),
  ];
  [self setupDetailUI];
  [self configHeader];
}

- (void)setupDetailUI {
  self.view.backgroundColor = [self pageBackgroundColor];

  [self.view addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + [self headerTopMargin]],
    [self.headerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.headerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
    [self.headerView.heightAnchor constraintEqualToConstant:[self headerHeight]],
  ]];
  [self setupHeaderStyle];

  [self.headerView addSubview:self.avatarView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarView.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor constant:16.0],
    [self.avatarView.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
    [self.avatarView.widthAnchor constraintEqualToConstant:[self avatarSize]],
    [self.avatarView.heightAnchor constraintEqualToConstant:[self avatarSize]],
  ]];

  [self.headerView addSubview:self.headerArrow];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerArrow.rightAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:-16.0],
    [self.headerArrow.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
    [self.headerArrow.widthAnchor constraintEqualToConstant:16.0],
    [self.headerArrow.heightAnchor constraintEqualToConstant:16.0],
  ]];

  [self.headerView addSubview:self.nameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.leftAnchor constraintEqualToAnchor:self.avatarView.rightAnchor constant:12.0],
    [self.nameLabel.rightAnchor constraintEqualToAnchor:self.headerArrow.leftAnchor constant:-8.0],
    [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
  ]];

  UITapGestureRecognizer *headerTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapHeader)];
  [self.headerView addGestureRecognizer:headerTap];

  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor constant:[self sectionSpacing]],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
    [self.tableView.heightAnchor constraintEqualToConstant:self.operationTitles.count * [self rowHeight]],
  ]];
  [self setupTableStyle];
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AIRobotDetailCell"];

  [self.view addSubview:self.chatSeparatorBlock];
  [NSLayoutConstraint activateConstraints:@[
    [self.chatSeparatorBlock.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.chatSeparatorBlock.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.chatSeparatorBlock.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.chatSeparatorBlock.heightAnchor constraintEqualToConstant:[self chatSeparatorHeight]],
  ]];

  [self.view addSubview:self.chatRowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.chatRowView.topAnchor constraintEqualToAnchor:self.chatSeparatorBlock.bottomAnchor],
    [self.chatRowView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.chatRowView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
    [self.chatRowView.heightAnchor constraintEqualToConstant:[self chatRowHeight] + [self deleteSeparatorHeight] + [self deleteRowHeight]],
  ]];
  [self setupChatRowStyle];

  UIView *chatTapArea = [[UIView alloc] init];
  chatTapArea.translatesAutoresizingMaskIntoConstraints = NO;
  chatTapArea.backgroundColor = [UIColor clearColor];
  UITapGestureRecognizer *chatTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapChat)];
  [chatTapArea addGestureRecognizer:chatTap];
  [self.chatRowView addSubview:chatTapArea];
  [NSLayoutConstraint activateConstraints:@[
    [chatTapArea.topAnchor constraintEqualToAnchor:self.chatRowView.topAnchor],
    [chatTapArea.leftAnchor constraintEqualToAnchor:self.chatRowView.leftAnchor],
    [chatTapArea.rightAnchor constraintEqualToAnchor:self.chatRowView.rightAnchor],
    [chatTapArea.heightAnchor constraintEqualToConstant:[self chatRowHeight]],
  ]];

  [self.chatRowView addSubview:self.chatLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.chatLabel.centerXAnchor constraintEqualToAnchor:self.chatRowView.centerXAnchor],
    [self.chatLabel.centerYAnchor constraintEqualToAnchor:chatTapArea.centerYAnchor],
  ]];

  [self.chatRowView addSubview:self.chatDeleteSeparator];
  [NSLayoutConstraint activateConstraints:@[
    [self.chatDeleteSeparator.topAnchor constraintEqualToAnchor:self.chatRowView.topAnchor constant:[self chatRowHeight]],
    [self.chatDeleteSeparator.leftAnchor constraintEqualToAnchor:self.chatRowView.leftAnchor],
    [self.chatDeleteSeparator.rightAnchor constraintEqualToAnchor:self.chatRowView.rightAnchor],
    [self.chatDeleteSeparator.heightAnchor constraintEqualToConstant:0.5],
  ]];

  [self.chatRowView addSubview:self.deleteButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.deleteButton.leftAnchor constraintEqualToAnchor:self.chatRowView.leftAnchor],
    [self.deleteButton.rightAnchor constraintEqualToAnchor:self.chatRowView.rightAnchor],
    [self.deleteButton.topAnchor constraintEqualToAnchor:self.chatRowView.topAnchor constant:[self chatRowHeight] + [self deleteSeparatorHeight]],
    [self.deleteButton.heightAnchor constraintEqualToConstant:[self deleteRowHeight]],
  ]];
}

- (void)configHeader {
  V2NIMUserAIBot *bot = self.viewModel.bot;
  if (!bot) {
    return;
  }
  NSString *name = bot.name.length > 0 ? bot.name : (bot.accid ?: @"");
  NSString *shortName = [NEFriendUserCache getShortName:name length:2] ?: @"";
  [self.avatarView configHeadData:bot.icon name:shortName uid:bot.accid ?: @""];
  self.nameLabel.text = name;
}

- (UIColor *)pageBackgroundColor {
  return [UIColor ne_lightBackgroundColor];
}

- (CGFloat)cardHorizontalMargin {
  return 20.0;
}

- (CGFloat)headerTopMargin {
  return 0.0;
}

- (CGFloat)headerHeight {
  return [self avatarRowHeight] + 0.5 + [self nicknameRowHeight];
}

- (CGFloat)avatarRowHeight {
  return 74.0;
}

- (CGFloat)nicknameRowHeight {
  return 50.0;
}

- (CGFloat)avatarSize {
  return 42.0;
}

- (CGFloat)avatarCornerRadius {
  return 21.0;
}

- (CGFloat)sectionSpacing {
  return 12.0;
}

- (CGFloat)rowHeight {
  return 48.0;
}

- (CGFloat)chatSeparatorHeight {
  return 12.0;
}

- (CGFloat)chatRowHeight {
  return 50.0;
}

- (CGFloat)deleteSeparatorHeight {
  return 0.0;
}

- (CGFloat)deleteRowHeight {
  return 50.0;
}

- (UIColor *)chatTextColor {
  return [UIColor ne_normalTheme];
}

- (UIFont *)chatLabelFont {
  return [UIFont systemFontOfSize:16.0];
}

- (UIFont *)deleteLabelFont {
  return [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
}

- (UIColor *)confirmButtonColor {
  return [UIColor normalContactThemeColor];
}

- (void)setupHeaderStyle {
  self.headerView.layer.cornerRadius = 8.0;
  self.headerView.clipsToBounds = YES;
}

- (void)setupTableStyle {
  self.tableView.layer.cornerRadius = 8.0;
  self.tableView.clipsToBounds = YES;
  self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)setupChatRowStyle {
  self.chatRowView.layer.cornerRadius = 8.0;
  self.chatRowView.clipsToBounds = YES;
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.operationTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIRobotDetailCell" forIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor whiteColor];
  cell.textLabel.text = indexPath.row < self.operationTitles.count ? self.operationTitles[indexPath.row] : @"";
  cell.textLabel.font = [UIFont systemFontOfSize:16.0];
  cell.textLabel.textColor = [UIColor ne_darkText];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.accessoryView = nil;
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self rowHeight];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  UIView *oldSeparator = [cell.contentView viewWithTag:kNEAIRobotDetailSeparatorTag];
  [oldSeparator removeFromSuperview];
  BOOL isLast = indexPath.row == self.operationTitles.count - 1;
  if (!isLast) {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16.0,
                                                                 [self rowHeight] - 0.5,
                                                                 tableView.bounds.size.width - 16.0,
                                                                 0.5)];
    separator.backgroundColor = [UIColor ne_greyLine];
    separator.tag = kNEAIRobotDetailSeparatorTag;
    [cell.contentView addSubview:separator];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.row) {
    case 0:
      [self didTapViewConfig];
      break;
    case 1:
      [self didTapRefreshToken];
      break;
    default:
      break;
  }
}

#pragma mark - Actions

- (void)didTapHeader {
  [self didTapEdit];
}

- (void)didTapEdit {
  V2NIMUserAIBot *bot = self.viewModel.bot;
  if (!bot || !self.navigationController) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  [[Router shared] use:ContactCreateAIRobotRouter
            parameters:@{
              @"nav": self.navigationController,
              @"bot": bot,
              @"animated": @YES,
              @"onEditSaved": ^(V2NIMUserAIBot *updatedBot) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }
                strongSelf.viewModel.bot = updatedBot;
                [strongSelf configHeader];
              },
            }
               closure:nil];
}

- (void)didTapViewConfig {
  V2NIMUserAIBot *bot = self.viewModel.bot;
  if (!bot || !self.navigationController) {
    return;
  }
  [[Router shared] use:ContactAIRobotConfigRouter
            parameters:@{
              @"nav": self.navigationController,
              @"bot": bot,
              @"animated": @YES,
            }
               closure:nil];
}

- (void)didTapRefreshToken {
  [self showRefreshTokenConfirmAlert];
}

- (void)showRefreshTokenConfirmAlert {
  [self showConfirmAlertWithTag:kNEAIRobotRefreshAlertTag
                          title:contactLocalizable(@"ai_robot_refresh_token_title")
                           desc:contactLocalizable(@"ai_robot_refresh_token_desc")
                   confirmTitle:commonLocalizable(@"sure")
                   confirmColor:[self confirmButtonColor]];
}

- (void)confirmRefreshToken {
  [self removeAlertWithTag:kNEAIRobotRefreshAlertTag];
  [self performRefreshToken];
}

- (void)performRefreshToken {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  self.view.userInteractionEnabled = NO;
  __weak typeof(self) weakSelf = self;
  [self.viewModel refreshToken:^(NSString * _Nullable token, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.view.userInteractionEnabled = YES;
      if (error != nil) {
        [strongSelf.view ne_makeToast:contactLocalizable(@"ai_robot_token_refresh_failed")];
        return;
      }
      [[NEAIRobotManager shared] loadAll:nil];
      if (token.length > 0) {
        strongSelf.viewModel.bot.token = token;
      }
      [strongSelf.view ne_makeToast:contactLocalizable(@"ai_robot_token_refresh_success")];
    });
  }];
}

- (void)didTapChat {
  NSString *accid = self.viewModel.bot.accid ?: @"";
  if (accid.length == 0 || !self.navigationController) {
    return;
  }
  NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accid];
  if (conversationId.length == 0) {
    return;
  }

  UINavigationController *nav = self.navigationController;
  [[Router shared] use:PushP2pChatVCRouter
            parameters:@{
              @"nav": nav,
              @"conversationId": conversationId,
              @"animated": @YES,
            }
               closure:nil];
  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray<UIViewController *> *controllers = [nav.viewControllers mutableCopy];
    NSIndexSet *indexes = [controllers indexesOfObjectsPassingTest:^BOOL(UIViewController * _Nonnull obj,
                                                                         NSUInteger idx,
                                                                         BOOL * _Nonnull stop) {
      return obj == self;
    }];
    if (indexes.count > 0) {
      [controllers removeObjectsAtIndexes:indexes];
      [nav setViewControllers:controllers animated:NO];
    }
  });
}

- (void)didTapDelete {
  [self showDeleteConfirmAlert];
}

- (void)showDeleteConfirmAlert {
  [self showConfirmAlertWithTag:kNEAIRobotDeleteAlertTag
                          title:contactLocalizable(@"ai_robot_delete_confirm_title")
                           desc:contactLocalizable(@"ai_robot_delete_confirm_desc")
                   confirmTitle:contactLocalizable(@"delete")
                   confirmColor:[UIColor ne_redText]];
}

- (void)performDelete {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  self.view.userInteractionEnabled = NO;
  NSString *botAccid = self.viewModel.bot.accid ?: @"";
  __weak typeof(self) weakSelf = self;
  [self.viewModel deleteRobot:^(NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.view.userInteractionEnabled = YES;
      if (error != nil) {
        [strongSelf.view ne_makeToast:robotErrorMessage(error)];
        return;
      }
      [[NEAIRobotManager shared] removeBotWithAccid:botAccid];
      [strongSelf.navigationController popViewControllerAnimated:YES];
    });
  }];
}

#pragma mark - Alert

- (void)showConfirmAlertWithTag:(NSInteger)tag
                          title:(NSString *)title
                           desc:(NSString *)desc
                   confirmTitle:(NSString *)confirmTitle
                   confirmColor:(UIColor *)confirmColor {
  UIView *overlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
  overlay.tag = tag;

  UIView *alertView = [[UIView alloc] init];
  alertView.translatesAutoresizingMaskIntoConstraints = NO;
  alertView.backgroundColor = [UIColor whiteColor];
  alertView.layer.cornerRadius = 14.0;
  alertView.clipsToBounds = YES;
  [overlay addSubview:alertView];
  [NSLayoutConstraint activateConstraints:@[
    [alertView.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
    [alertView.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
    [alertView.widthAnchor constraintEqualToConstant:270.0],
    [alertView.heightAnchor constraintEqualToConstant:140.0],
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = title;
  titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  titleLabel.textColor = [UIColor blackColor];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [alertView addSubview:titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [titleLabel.topAnchor constraintEqualToAnchor:alertView.topAnchor constant:19.0],
    [titleLabel.leftAnchor constraintEqualToAnchor:alertView.leftAnchor constant:16.0],
    [titleLabel.rightAnchor constraintEqualToAnchor:alertView.rightAnchor constant:-16.0],
    [titleLabel.heightAnchor constraintEqualToConstant:22.0],
  ]];

  UILabel *descLabel = [[UILabel alloc] init];
  descLabel.translatesAutoresizingMaskIntoConstraints = NO;
  descLabel.text = desc;
  descLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13.0] ?: [UIFont systemFontOfSize:13.0];
  descLabel.textColor = [UIColor ne_darkText];
  descLabel.textAlignment = NSTextAlignmentCenter;
  descLabel.numberOfLines = 0;
  [alertView addSubview:descLabel];
  [NSLayoutConstraint activateConstraints:@[
    [descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10.0],
    [descLabel.leftAnchor constraintEqualToAnchor:alertView.leftAnchor constant:16.0],
    [descLabel.rightAnchor constraintEqualToAnchor:alertView.rightAnchor constant:-16.0],
  ]];

  UIView *hLine = [[UIView alloc] init];
  hLine.translatesAutoresizingMaskIntoConstraints = NO;
  hLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:80.0 / 255.0 alpha:0.05];
  [alertView addSubview:hLine];
  [NSLayoutConstraint activateConstraints:@[
    [hLine.leftAnchor constraintEqualToAnchor:alertView.leftAnchor],
    [hLine.rightAnchor constraintEqualToAnchor:alertView.rightAnchor],
    [hLine.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor constant:-44.0],
    [hLine.heightAnchor constraintEqualToConstant:0.5],
  ]];

  UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
  cancelBtn.tag = tag;
  [cancelBtn setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
  [cancelBtn setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
  cancelBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  [alertView addSubview:cancelBtn];
  [NSLayoutConstraint activateConstraints:@[
    [cancelBtn.leftAnchor constraintEqualToAnchor:alertView.leftAnchor],
    [cancelBtn.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [cancelBtn.widthAnchor constraintEqualToAnchor:alertView.widthAnchor multiplier:0.5 constant:-0.25],
    [cancelBtn.heightAnchor constraintEqualToConstant:44.0],
  ]];

  UIView *vLine = [[UIView alloc] init];
  vLine.translatesAutoresizingMaskIntoConstraints = NO;
  vLine.backgroundColor = [UIColor colorWithRed:0 green:0 blue:80.0 / 255.0 alpha:0.05];
  [alertView addSubview:vLine];
  [NSLayoutConstraint activateConstraints:@[
    [vLine.leftAnchor constraintEqualToAnchor:cancelBtn.rightAnchor],
    [vLine.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [vLine.widthAnchor constraintEqualToConstant:0.5],
    [vLine.heightAnchor constraintEqualToConstant:44.0],
  ]];

  UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  confirmBtn.translatesAutoresizingMaskIntoConstraints = NO;
  confirmBtn.tag = tag;
  [confirmBtn setTitle:confirmTitle forState:UIControlStateNormal];
  [confirmBtn setTitleColor:confirmColor forState:UIControlStateNormal];
  confirmBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17.0] ?: [UIFont systemFontOfSize:17.0];
  [alertView addSubview:confirmBtn];
  [NSLayoutConstraint activateConstraints:@[
    [confirmBtn.rightAnchor constraintEqualToAnchor:alertView.rightAnchor],
    [confirmBtn.bottomAnchor constraintEqualToAnchor:alertView.bottomAnchor],
    [confirmBtn.widthAnchor constraintEqualToAnchor:alertView.widthAnchor multiplier:0.5 constant:-0.25],
    [confirmBtn.heightAnchor constraintEqualToConstant:44.0],
  ]];

  [cancelBtn addTarget:self action:@selector(didTapAlertCancelButton:) forControlEvents:UIControlEventTouchUpInside];
  [confirmBtn addTarget:self action:@selector(didTapAlertConfirmButton:) forControlEvents:UIControlEventTouchUpInside];

  UIView *containerView = self.view.window ?: self.view;
  [containerView addSubview:overlay];
  overlay.frame = containerView.bounds;
}

- (void)didTapAlertCancelButton:(UIButton *)sender {
  [self removeAlertWithTag:sender.tag];
}

- (void)didTapAlertConfirmButton:(UIButton *)sender {
  [self removeAlertWithTag:sender.tag];
  if (sender.tag == kNEAIRobotRefreshAlertTag) {
    [self performRefreshToken];
  } else if (sender.tag == kNEAIRobotDeleteAlertTag) {
    [self performDelete];
  }
}

- (void)removeAlertWithTag:(NSInteger)tag {
  UIView *containerView = self.view.window ?: self.view;
  for (UIView *subview in [containerView.subviews copy]) {
    if (subview.tag == tag) {
      [subview removeFromSuperview];
      break;
    }
  }
}

- (UIImageView *)makeArrowView {
  UIImageView *arrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
  arrowView.contentMode = UIViewContentModeScaleAspectFit;
  arrowView.frame = CGRectMake(0, 0, 16.0, 16.0);
  return arrowView;
}

#pragma mark - Lazy Init

- (UIView *)headerView {
  if (!_headerView) {
    _headerView = [[UIView alloc] init];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.backgroundColor = [UIColor whiteColor];
  }
  return _headerView;
}

- (NEUserHeaderView *)avatarView {
  if (!_avatarView) {
    _avatarView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarView.layer.cornerRadius = [self avatarCornerRadius];
    _avatarView.clipsToBounds = YES;
    _avatarView.titleLabel.font = [UIFont systemFontOfSize:17.0];
    _avatarView.titleLabel.textColor = [UIColor whiteColor];
  }
  return _avatarView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:16.0];
    _nameLabel.textColor = [UIColor ne_darkText];
  }
  return _nameLabel;
}

- (UIImageView *)headerArrow {
  if (!_headerArrow) {
    _headerArrow = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _headerArrow.translatesAutoresizingMaskIntoConstraints = NO;
    _headerArrow.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _headerArrow;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.estimatedRowHeight = 0.0;
    _tableView.estimatedSectionHeaderHeight = 0.0;
    _tableView.estimatedSectionFooterHeight = 0.0;
    _tableView.scrollEnabled = NO;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

- (UIView *)chatSeparatorBlock {
  if (!_chatSeparatorBlock) {
    _chatSeparatorBlock = [[UIView alloc] init];
    _chatSeparatorBlock.translatesAutoresizingMaskIntoConstraints = NO;
    _chatSeparatorBlock.backgroundColor = [self pageBackgroundColor];
  }
  return _chatSeparatorBlock;
}

- (UIView *)chatRowView {
  if (!_chatRowView) {
    _chatRowView = [[UIView alloc] init];
    _chatRowView.translatesAutoresizingMaskIntoConstraints = NO;
    _chatRowView.backgroundColor = [UIColor whiteColor];
  }
  return _chatRowView;
}

- (UILabel *)chatLabel {
  if (!_chatLabel) {
    _chatLabel = [[UILabel alloc] init];
    _chatLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _chatLabel.text = contactLocalizable(@"ai_robot_chat");
    _chatLabel.font = [self chatLabelFont];
    _chatLabel.textColor = [self chatTextColor];
    _chatLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _chatLabel;
}

- (UIView *)chatDeleteSeparator {
  if (!_chatDeleteSeparator) {
    _chatDeleteSeparator = [[UIView alloc] init];
    _chatDeleteSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _chatDeleteSeparator.backgroundColor = [UIColor ne_greyLine];
  }
  return _chatDeleteSeparator;
}

- (UIButton *)deleteButton {
  if (!_deleteButton) {
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_deleteButton setTitle:contactLocalizable(@"ai_robot_delete") forState:UIControlStateNormal];
    [_deleteButton setTitleColor:[UIColor ne_redText] forState:UIControlStateNormal];
    _deleteButton.titleLabel.font = [self deleteLabelFont];
    [_deleteButton addTarget:self action:@selector(didTapDelete) forControlEvents:UIControlEventTouchUpInside];
  }
  return _deleteButton;
}

@end
