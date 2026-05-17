// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactUserViewController.h"
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEAIUserManager.h>
#import <NEChatKitOC/NEAIRobotManager.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NSString+NIMKit.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import "ContactConst.h"
#import "NEBaseContactAliasViewController.h"
#import "CenterTextCell.h"
#import "TextWithDetailTextCell.h"
#import "TextWithRightArrowCell.h"
#import "TextWithSwitchCell.h"

static UILabel *NEFindLabelWithText(UIView *view, NSString *text) {
  if (text.length == 0) {
    return nil;
  }
  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:[UILabel class]]) {
      UILabel *label = (UILabel *)subview;
      if ([label.text isEqualToString:text]) {
        return label;
      }
    }
    UILabel *foundLabel = NEFindLabelWithText(subview, text);
    if (foundLabel) {
      return foundLabel;
    }
  }
  return nil;
}

@implementation NEBaseContactUserViewController

- (BOOL)isCurrentUserFriend:(NSString *)uid {
  if ([[NEFriendUserCache shared] isFriend:uid]) {
    return YES;
  }
  if ([self.user.accountId isEqualToString:uid] && self.user.friend) {
    return YES;
  }
  return NO;
}

#pragma mark - Init

- (instancetype)initWithAccountId:(NSString *)accountId {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _accountId = accountId;
    _className = @"ContactUserViewController";
    _data = [NSMutableArray array];
    _headerView = [[NEBaseUserInfoHeaderView alloc] init];
    _viewModel = [[ContactUserViewModel alloc] init];
  }
  return self;
}

- (instancetype)initWithNimUser:(V2NIMUser *)nimUser {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = [[NEUserWithFriend alloc] initWithUser:nimUser friend:nil];
    _accountId = _user.user.accountId;
    _className = @"ContactUserViewController";
    _data = [NSMutableArray array];
    _headerView = [[NEBaseUserInfoHeaderView alloc] init];
    _viewModel = [[ContactUserViewModel alloc] init];
  }
  return self;
}

- (instancetype)initWithUser:(NEUserWithFriend *)user {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _user = user;
    _accountId = user.user.accountId;
    _className = @"ContactUserViewController";
    _data = [NSMutableArray array];
    _headerView = [[NEBaseUserInfoHeaderView alloc] init];
    _viewModel = [[ContactUserViewModel alloc] init];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.tableViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loadData)
                                               name:NENotificationFriendCacheInit
                                             object:nil];
  [self commonUI];
  [self loadData];
  [[ContactRepo shared] addContactListener:self];

  // 数字人无需远端查询信息
  if ([self.user.user isKindOfClass:[V2NIMAIUser class]]) {
    [self loadData];
    return;
  }

  if (self.accountId) {
    __weak typeof(self) weakSelf = self;
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
      [self.view ne_makeToast:commonLocalizable(@"network_error")
                     duration:2.0
                     position:NEToastPositionBottom];
    }
    [self.view makeToastActivity:YXToastPositionCenter];
    [self.viewModel getUserInfo:self.accountId completion:^(NEUserWithFriend * _Nullable user, NSError * _Nullable error) {
      [weakSelf.view ne_hideToastActivity];
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription];
      } else if (user) {
        weakSelf.user = user;
        [weakSelf loadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationDidTapHeader object:user];
      }
    }];
  }
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)chatActionTitle {
  return commonLocalizable(@"chat");
}

- (void)changeLanguage {
  [self loadData];
}

#pragma mark - Lazy Init

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;

    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

#pragma mark - commonUI

- (void)commonUI {
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationView.moreButton.hidden = YES;

  [self.view addSubview:self.tableView];
  self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.tableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.tableView registerClass:[TextWithRightArrowCell class]
         forCellReuseIdentifier:NSStringFromClass([TextWithRightArrowCell class])];
  [self.tableView registerClass:[TextWithDetailTextCell class]
         forCellReuseIdentifier:NSStringFromClass([TextWithDetailTextCell class])];
  [self.tableView registerClass:[TextWithSwitchCell class]
         forCellReuseIdentifier:NSStringFromClass([TextWithSwitchCell class])];
  [self.tableView registerClass:[CenterTextCell class]
         forCellReuseIdentifier:NSStringFromClass([CenterTextCell class])];
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];

  self.tableView.tableHeaderView = self.headerView;
  self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.headerView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
    [self.headerView.heightAnchor constraintEqualToConstant:113],
    [self.headerView.widthAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.width],
  ]];
}

#pragma mark - loadData

- (void)loadData {
  NSString *uid = self.user.user.accountId ?: self.accountId;
  if (!uid) return;

  // 数字人信息从缓存中取
  NEUserWithFriend *aiUser = [[NEAIUserManager shared] getNEUserById:uid];
  if (aiUser) {
    self.user = aiUser;
  }

  NEUserWithFriend *cachedFriendUser = [[NEFriendUserCache shared] getFriendInfo:uid];
  if (cachedFriendUser) {
    if (!self.user || !self.user.user) {
      self.user = cachedFriendUser;
    } else if (!self.user.friend && cachedFriendUser.friend) {
      self.user = [[NEUserWithFriend alloc] initWithUser:self.user.user
                                                  friend:cachedFriendUser.friend];
    }
  }

  if ([self.user.user isKindOfClass:[V2NIMAIUser class]]) {
    // 数字人仅展示【聊天】
    self.data = [NSMutableArray arrayWithArray:@[
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:[self chatActionTitle]
                            detailTitle:@""
                                  value:NO
                              textColor:[UIColor ne_colorWithHexString:@"#337EFF"]
                              cellClass:[CenterTextCell class]],
      ]],
    ]];
  } else if (self.isRobot || [[NEAIRobotManager shared] isRobot:uid]) {
    // 机器人仅展示【去聊天】
    self.data = [NSMutableArray arrayWithArray:@[
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:[self chatActionTitle]
                            detailTitle:@""
                                  value:NO
                              textColor:[UIColor ne_colorWithHexString:@"#337EFF"]
                              cellClass:[CenterTextCell class]],
      ]],
    ]];
  } else if ([self isCurrentUserFriend:uid]) {
    self.data = [NSMutableArray arrayWithArray:@[
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:contactLocalizable(@"noteName")
                            detailTitle:self.user.friend.alias
                                  value:NO
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithRightArrowCell class]],
      ]],
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:contactLocalizable(@"birthday")
                            detailTitle:self.user.user.birthday
                                  value:NO
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithDetailTextCell class]],
        [[UserItem alloc] initWithTitle:contactLocalizable(@"phone")
                            detailTitle:self.user.user.mobile
                                  value:NO
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithDetailTextCell class]],
        [[UserItem alloc] initWithTitle:contactLocalizable(@"email")
                            detailTitle:self.user.user.email
                                  value:NO
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithDetailTextCell class]],
        [[UserItem alloc] initWithTitle:contactLocalizable(@"sign")
                            detailTitle:self.user.user.sign
                                  value:NO
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithDetailTextCell class]],
      ]],
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:contactLocalizable(@"add_blackList")
                            detailTitle:@""
                                  value:[[NEFriendUserCache shared] isBlockAccount:uid]
                              textColor:[UIColor darkTextColor]
                              cellClass:[TextWithSwitchCell class]],
      ]],
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:[self chatActionTitle]
                            detailTitle:@""
                                  value:NO
                              textColor:[UIColor ne_colorWithHexString:@"#337EFF"]
                              cellClass:[CenterTextCell class]],
        [[UserItem alloc] initWithTitle:contactLocalizable(@"delete_friend")
                            detailTitle:@""
                                  value:NO
                              textColor:[UIColor redColor]
                              cellClass:[CenterTextCell class]],
      ]],
    ]];
  } else {
    self.data = [NSMutableArray arrayWithArray:@[
      [NSMutableArray arrayWithArray:@[
        [[UserItem alloc] initWithTitle:contactLocalizable(@"add_friend")
                            detailTitle:@""
                                  value:NO
                              textColor:[UIColor ne_colorWithHexString:@"#337EFF"]
                              cellClass:[CenterTextCell class]],
      ]],
    ]];
  }

  [self.headerView setData:self.user];
  self.tableView.tableHeaderView = self.tableView.tableHeaderView;
  [self.tableView.tableHeaderView layoutIfNeeded];
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UserItem *item = self.data[indexPath.section][indexPath.row];
  NSString *cellIdentifier = NSStringFromClass(item.cellClass);
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

  if ([cell isKindOfClass:[TextWithRightArrowCell class]]) {
    TextWithRightArrowCell *rightArrowCell = (TextWithRightArrowCell *)cell;
    rightArrowCell.titleLabel.text = item.title;
    return cell;
  }

  if ([cell isKindOfClass:[TextWithDetailTextCell class]]) {
    TextWithDetailTextCell *detailCell = (TextWithDetailTextCell *)cell;
    detailCell.titleLabel.text = item.title;
    detailCell.detailTitleLabel.text = item.detailTitle;
    if ([item.title isEqualToString:contactLocalizable(@"sign")]) {
      detailCell.detailTitleLabel.numberOfLines = 2;
    }
    return cell;
  }

  if ([cell isKindOfClass:[TextWithSwitchCell class]]) {
    TextWithSwitchCell *switchCell = (TextWithSwitchCell *)cell;
    switchCell.titleLabel.text = item.title;
    switchCell.switchButton.on = item.value;

    __weak typeof(self) weakSelf = self;
    void (^block)(NSString *, BOOL) = ^(NSString *title, BOOL value) {
      if ([title isEqualToString:contactLocalizable(@"add_blackList")]) {
        [weakSelf blackList:value completion:^{
          switchCell.switchButton.on = !switchCell.switchButton.isOn;
        }];
      } else if ([title isEqualToString:contactLocalizable(@"message_remind")]) {
      }
    };
    switchCell.block = block;

    return cell;
  }

  if ([cell isKindOfClass:[CenterTextCell class]]) {
    CenterTextCell *centerCell = (CenterTextCell *)cell;
    centerCell.titleLabel.text = item.title;
    centerCell.titleLabel.textColor = item.textColor;
    return cell;
  }

  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor clearColor];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 0.1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  UIView *footerView = [[UIView alloc] init];
  footerView.backgroundColor = [UIColor clearColor];
  return footerView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UserItem *item = self.data[indexPath.section][indexPath.row];
  if ([item.title isEqualToString:contactLocalizable(@"noteName")]) {
    [self toEditRemarks];
  }
  if ([item.title isEqualToString:[self chatActionTitle]]) {
    [self chat:self.user];
  }
  if ([item.title isEqualToString:contactLocalizable(@"delete_friend")]) {
    [self deleteFriend:self.user];
  }
  if ([item.title isEqualToString:contactLocalizable(@"add_friend")]) {
    NSString *uid = self.user.user.accountId;
    if (uid) {
      if ([self isCurrentUserFriend:uid]) {
        [self loadData];
      } else {
        [self addFriend];
      }
    }
  }
}

#pragma mark - Actions

- (NEBaseContactAliasViewController *)getContactAliasViewController {
  return [[NEBaseContactAliasViewController alloc] init];
}

- (void)toEditRemarks {
  NEBaseContactAliasViewController *remark = [self getContactAliasViewController];
  remark.user = self.user;
  __weak typeof(self) weakSelf = self;
  remark.completion = ^(NEUserWithFriend *u) {
    weakSelf.user = u;
    [weakSelf.headerView setData:u];
  };
  [self.navigationController pushViewController:remark animated:YES];

  NSLog(@"edit remarks");
}

- (void)allowNotify:(BOOL)allow {
  NSLog(@"edit remarks");
}

- (void)blackList:(BOOL)isBlack completion:(void (^)(void))completion {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    completion();
    return;
  }

  NSString *userId = self.user.user.accountId;
  if (!userId) return;

  if (isBlack) {
    // add
    __weak typeof(self) weakSelf = self;
    [self.viewModel.contactRepo addBlockList:userId completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription];
        completion();
      }
    }];
  } else {
    // remove
    __weak typeof(self) weakSelf = self;
    [self.viewModel.contactRepo removeBlockList:userId completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription];
        completion();
      }
    }];
  }
}

- (void)chat:(NEUserWithFriend *)user {
  NSString *accid = self.user.user.accountId;
  if (!accid) return;

  NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accid];
  [[Router shared] use:PushP2pChatVCRouter
            parameters:@{@"nav": self.navigationController ?: [NSNull null],
                         @"conversationId": conversationId ?: [NSNull null],
                         @"removeUserVC": @YES,
                         @"animated": @NO}
               closure:nil];
}

- (void)deleteFriendAction:(NEUserWithFriend *)user {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  NSString *userId = user.user.accountId;
  if (userId) {
    [self.viewModel deleteFriend:userId completion:^(NSError * _Nullable error) {
      if (error != nil) {
        [self.view ne_makeToast:error.localizedDescription ?: @""];
      } else {
        [self.navigationController popViewControllerAnimated:YES];
      }
    }];
  }
}

- (void)deleteFriend:(NEUserWithFriend *)user {
  NSString *name = [user showName] ?: @"";
  NSString *alertTitle = [NSString stringWithFormat:contactLocalizable(@"delete_title"), name];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
  UILabel *titleLabel = NEFindLabelWithText(alertController.view, alertTitle);
  [self applyContactNameEmojiStyleToLabel:titleLabel name:name];
  titleLabel.accessibilityIdentifier = @"id.action1";

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:[UIColor ne_darkText] forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  __weak typeof(self) weakSelf = self;
  UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:contactLocalizable(@"delete_friend")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
    [weakSelf deleteFriendAction:user];
  }];
  [deleteAction setValue:[UIColor ne_redText] forKey:@"_titleTextColor"];
  deleteAction.accessibilityIdentifier = @"id.action2";

  [alertController addAction:cancelAction];
  [alertController addAction:deleteAction];
  [self fixAlertOnIpad:alertController];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)applyContactNameEmojiStyleToLabel:(UILabel *)label name:(NSString *)name {
  if (label.text.length == 0 || name.length == 0 || ![name nim_containsEmoji]) {
    return;
  }

  NSRange nameRange = [label.text rangeOfString:name];
  if (nameRange.location == NSNotFound || nameRange.length == 0) {
    return;
  }

  UIFont *contactNameFont = self.headerView.titleLabel.font ?: [UIFont boldSystemFontOfSize:22];
  UIColor *textColor = label.textColor ?: [UIColor ne_darkText];
  UIFont *textFont = label.font ?: [UIFont systemFontOfSize:13];
  NSMutableAttributedString *attributedTitle =
      [[NSMutableAttributedString alloc] initWithString:label.text
                                             attributes:@{
    NSFontAttributeName: textFont,
    NSForegroundColorAttributeName: textColor,
  }];

  [name enumerateSubstringsInRange:NSMakeRange(0, name.length)
                            options:NSStringEnumerationByComposedCharacterSequences
                         usingBlock:^(NSString * _Nullable substring,
                                      NSRange substringRange,
                                      NSRange enclosingRange,
                                      BOOL *stop) {
    if (![(substring ?: @"") nim_containsEmoji]) {
      return;
    }

    NSRange titleRange = NSMakeRange(nameRange.location + substringRange.location,
                                     substringRange.length);
    [attributedTitle addAttribute:NSFontAttributeName
                            value:contactNameFont
                            range:titleRange];
  }];

  label.attributedText = attributedTitle;
}

- (void)addFriend {
  __weak typeof(self) weakSelf = self;
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }
  NSString *account = self.user.user.accountId;
  if (account) {
    [self.viewModel addFriend:account completion:^(NSError * _Nullable error) {
      if (error) {
        NSLog(@"ContactKit log");
      } else {
        [weakSelf.view ne_makeToast:contactLocalizable(@"send_friend_apply")];
        if ([[NEFriendUserCache shared] isBlockAccount:account]) {
          [weakSelf.viewModel removeBlackList:account completion:^(NSError * _Nullable err) {
          }];
        }
      }
    }];
  }
}

#pragma mark - NEContactListener

- (void)onContactChange:(NSInteger)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
  for (NEUserWithFriend *contact in contacts) {
    if ([contact.user.accountId isEqualToString:self.accountId]) {
      if (changeType == NEContactChangeTypeDeleteFriend) {
        self.user = [[NEUserWithFriend alloc] initWithUser:contact.user friend:nil];
      } else if (changeType == NEContactChangeTypeUpdate && !contact.friend && self.user.friend) {
        self.user = [[NEUserWithFriend alloc] initWithUser:contact.user friend:self.user.friend];
      } else {
        self.user = contact;
      }
      [self loadData];
    }
  }
}

@end
